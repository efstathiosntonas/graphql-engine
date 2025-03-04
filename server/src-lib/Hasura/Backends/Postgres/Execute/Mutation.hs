module Hasura.Backends.Postgres.Execute.Mutation
  ( MutationRemoteJoinCtx,
    MutateResp (..),
    --
    execDeleteQuery,
    execInsertQuery,
    execUpdateQuery,
    --
    executeMutationOutputQuery,
    mutateAndFetchCols,
  )
where

import Data.Aeson
import Data.Sequence qualified as DS
import Database.PG.Query qualified as Q
import Hasura.Backends.Postgres.Connection
import Hasura.Backends.Postgres.SQL.DML qualified as S
import Hasura.Backends.Postgres.SQL.Types
import Hasura.Backends.Postgres.SQL.Value
import Hasura.Backends.Postgres.Translate.Delete
import Hasura.Backends.Postgres.Translate.Insert
import Hasura.Backends.Postgres.Translate.Mutation
import Hasura.Backends.Postgres.Translate.Returning
import Hasura.Backends.Postgres.Translate.Select
import Hasura.Backends.Postgres.Translate.Update
import Hasura.Base.Error
import Hasura.EncJSON
import Hasura.Prelude
import Hasura.QueryTags
import Hasura.RQL.DML.Internal
import Hasura.RQL.IR.Delete
import Hasura.RQL.IR.Insert
import Hasura.RQL.IR.Returning
import Hasura.RQL.IR.Select
import Hasura.RQL.IR.Update
import Hasura.RQL.Types
import Hasura.SQL.Types
import Hasura.Session
import Network.HTTP.Client qualified as HTTP
import Network.HTTP.Types qualified as N

data MutateResp (b :: BackendType) a = MutateResp
  { _mrAffectedRows :: !Int,
    _mrReturningColumns :: ![ColumnValues b a]
  }
  deriving (Generic)

deriving instance (Backend b, Show a) => Show (MutateResp b a)

deriving instance (Backend b, Eq a) => Eq (MutateResp b a)

instance (Backend b, ToJSON a) => ToJSON (MutateResp b a) where
  toJSON = genericToJSON hasuraJSON

instance (Backend b, FromJSON a) => FromJSON (MutateResp b a) where
  parseJSON = genericParseJSON hasuraJSON

type MutationRemoteJoinCtx = (HTTP.Manager, [N.Header], UserInfo)

data Mutation (b :: BackendType) = Mutation
  { _mTable :: !QualifiedTable,
    _mQuery :: !(MutationCTE, DS.Seq Q.PrepArg),
    _mOutput :: !(MutationOutput b),
    _mCols :: ![ColumnInfo b],
    _mStrfyNum :: !Bool
  }

mkMutation ::
  UserInfo ->
  QualifiedTable ->
  (MutationCTE, DS.Seq Q.PrepArg) ->
  MutationOutput ('Postgres pgKind) ->
  [ColumnInfo ('Postgres pgKind)] ->
  Bool ->
  Mutation ('Postgres pgKind)
mkMutation _userInfo table query output allCols strfyNum =
  Mutation table query output allCols strfyNum

runMutation ::
  ( MonadTx m,
    Backend ('Postgres pgKind),
    PostgresAnnotatedFieldJSON pgKind,
    MonadReader QueryTagsComment m
  ) =>
  Mutation ('Postgres pgKind) ->
  m EncJSON
runMutation mut =
  bool (mutateAndReturn mut) (mutateAndSel mut) $
    hasNestedFld $ _mOutput mut

mutateAndReturn ::
  ( MonadTx m,
    Backend ('Postgres pgKind),
    PostgresAnnotatedFieldJSON pgKind,
    MonadReader QueryTagsComment m
  ) =>
  Mutation ('Postgres pgKind) ->
  m EncJSON
mutateAndReturn (Mutation qt (cte, p) mutationOutput allCols strfyNum) =
  executeMutationOutputQuery qt allCols Nothing cte mutationOutput strfyNum (toList p)

execUpdateQuery ::
  forall pgKind m.
  ( MonadTx m,
    Backend ('Postgres pgKind),
    PostgresAnnotatedFieldJSON pgKind,
    MonadReader QueryTagsComment m
  ) =>
  Bool ->
  UserInfo ->
  (AnnotatedUpdate ('Postgres pgKind), DS.Seq Q.PrepArg) ->
  m EncJSON
execUpdateQuery strfyNum userInfo (u, p) =
  runMutation
    (mkMutation userInfo (_auTable u) (MCCheckConstraint updateCTE, p) (_auOutput u) (_auAllCols u) strfyNum)
  where
    updateCTE = mkUpdateCTE u

execDeleteQuery ::
  forall pgKind m.
  ( MonadTx m,
    Backend ('Postgres pgKind),
    PostgresAnnotatedFieldJSON pgKind,
    MonadReader QueryTagsComment m
  ) =>
  Bool ->
  UserInfo ->
  (AnnDel ('Postgres pgKind), DS.Seq Q.PrepArg) ->
  m EncJSON
execDeleteQuery strfyNum userInfo (u, p) =
  runMutation
    (mkMutation userInfo (dqp1Table u) (MCDelete delete, p) (dqp1Output u) (dqp1AllCols u) strfyNum)
  where
    delete = mkDelete u

execInsertQuery ::
  ( MonadTx m,
    Backend ('Postgres pgKind),
    PostgresAnnotatedFieldJSON pgKind,
    MonadReader QueryTagsComment m
  ) =>
  Bool ->
  UserInfo ->
  (InsertQueryP1 ('Postgres pgKind), DS.Seq Q.PrepArg) ->
  m EncJSON
execInsertQuery strfyNum userInfo (u, p) =
  runMutation
    (mkMutation userInfo (iqp1Table u) (MCCheckConstraint insertCTE, p) (iqp1Output u) (iqp1AllCols u) strfyNum)
  where
    insertCTE = mkInsertCTE u

{- Note: [Prepared statements in Mutations]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The SQL statements we generate for mutations seem to include the actual values
in the statements in some cases which pretty much makes them unfit for reuse
(Handling relationships in the returning clause is the source of this
complexity). Further, `PGConn` has an internal cache which maps a statement to
a 'prepared statement id' on Postgres. As we prepare more and more single-use
SQL statements we end up leaking memory both on graphql-engine and Postgres
till the connection is closed. So a simpler but very crude fix is to not use
prepared statements for mutations. The performance of insert mutations
shouldn't be affected but updates and delete mutations with complex boolean
conditions **might** see some degradation.
-}

mutateAndSel ::
  forall pgKind m.
  ( MonadTx m,
    Backend ('Postgres pgKind),
    PostgresAnnotatedFieldJSON pgKind,
    MonadReader QueryTagsComment m
  ) =>
  Mutation ('Postgres pgKind) ->
  m EncJSON
mutateAndSel (Mutation qt q mutationOutput allCols strfyNum) = do
  -- Perform mutation and fetch unique columns
  MutateResp _ columnVals <- liftTx $ mutateAndFetchCols qt allCols q strfyNum
  select <- mkSelectExpFromColumnValues qt allCols columnVals
  -- Perform select query and fetch returning fields
  executeMutationOutputQuery
    qt
    allCols
    Nothing
    (MCSelectValues select)
    mutationOutput
    strfyNum
    []

withCheckPermission :: (MonadError QErr m) => m (a, Bool) -> m a
withCheckPermission sqlTx = do
  (rawResponse, checkConstraint) <- sqlTx
  unless checkConstraint $
    throw400 PermissionError $
      "check constraint of an insert/update permission has failed"
  pure rawResponse

executeMutationOutputQuery ::
  forall pgKind m.
  ( MonadTx m,
    Backend ('Postgres pgKind),
    PostgresAnnotatedFieldJSON pgKind,
    MonadReader QueryTagsComment m
  ) =>
  QualifiedTable ->
  [ColumnInfo ('Postgres pgKind)] ->
  Maybe Int ->
  MutationCTE ->
  MutationOutput ('Postgres pgKind) ->
  Bool ->
  -- | Prepared params
  [Q.PrepArg] ->
  m EncJSON
executeMutationOutputQuery qt allCols preCalAffRows cte mutOutput strfyNum prepArgs = do
  queryTags <- ask
  let queryTx :: Q.FromRes a => m a
      queryTx = do
        let selectWith = mkMutationOutputExp qt allCols preCalAffRows cte mutOutput strfyNum
            query = Q.fromBuilder $ toSQL selectWith
            queryWithQueryTags = query {Q.getQueryText = (Q.getQueryText query) <> (_unQueryTagsComment queryTags)}
        -- See Note [Prepared statements in Mutations]
        liftTx (Q.rawQE dmlTxErrorHandler queryWithQueryTags prepArgs False)

  if checkPermissionRequired cte
    then withCheckPermission $ Q.getRow <$> queryTx
    else (runIdentity . Q.getRow) <$> queryTx

mutateAndFetchCols ::
  forall pgKind.
  (Backend ('Postgres pgKind), PostgresAnnotatedFieldJSON pgKind) =>
  QualifiedTable ->
  [ColumnInfo ('Postgres pgKind)] ->
  (MutationCTE, DS.Seq Q.PrepArg) ->
  Bool ->
  Q.TxE QErr (MutateResp ('Postgres pgKind) TxtEncodedVal)
mutateAndFetchCols qt cols (cte, p) strfyNum = do
  let mutationTx :: Q.FromRes a => Q.TxE QErr a
      mutationTx =
        -- See Note [Prepared statements in Mutations]
        Q.rawQE dmlTxErrorHandler sqlText (toList p) False

  if checkPermissionRequired cte
    then withCheckPermission $ (first Q.getAltJ . Q.getRow) <$> mutationTx
    else (Q.getAltJ . runIdentity . Q.getRow) <$> mutationTx
  where
    rawAliasIdentifier = qualifiedObjectToText qt <> "__mutation_result"
    aliasIdentifier = Identifier rawAliasIdentifier
    tabFrom = FromIdentifier $ FIIdentifier rawAliasIdentifier
    tabPerm = TablePerm annBoolExpTrue Nothing
    selFlds = flip map cols $
      \ci -> (fromCol @('Postgres pgKind) $ ciColumn ci, mkAnnColumnFieldAsText ci)

    sqlText = Q.fromBuilder $ toSQL selectWith
    selectWith = S.SelectWith [(S.Alias aliasIdentifier, getMutationCTE cte)] select
    select =
      S.mkSelect
        { S.selExtr =
            S.Extractor extrExp Nothing :
            bool [] [S.Extractor checkErrExp Nothing] (checkPermissionRequired cte)
        }
    checkErrExp = mkCheckErrorExp aliasIdentifier
    extrExp =
      S.applyJsonBuildObj
        [ S.SELit "affected_rows",
          affRowsSel,
          S.SELit "returning_columns",
          colSel
        ]

    affRowsSel =
      S.SESelect $
        S.mkSelect
          { S.selExtr = [S.Extractor S.countStar Nothing],
            S.selFrom = Just $ S.FromExp [S.FIIdentifier aliasIdentifier]
          }
    colSel =
      S.SESelect $
        mkSQLSelect JASMultipleRows $
          AnnSelectG selFlds tabFrom tabPerm noSelectArgs strfyNum
