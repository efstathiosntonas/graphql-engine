.. meta::
   :description: Hasura schema/metadata API reference
   :keywords: hasura, docs, schema/metadata API, API reference

.. _schema_metadata_apis:

Schema / Metadata API Reference (Deprecated)
============================================

.. contents:: Table of contents
  :backlinks: none
  :depth: 1
  :local:

Introduction
------------

The schema / metadata API provides the following features:

1. Execute SQL on the underlying Postgres database, supports schema modifying actions.
2. Modify Hasura metadata (permission rules and relationships).

This is primarily intended to be used as an ``admin`` API to manage the Hasura schema and metadata.

.. admonition:: Deprecation

  In versions ``v2.0.0`` and above, the schema/metadata API is deprecated in favour of the :ref:`schema API <schema_apis>` and the
  :ref:`metadata API <metadata_apis>`.

  Though for backwards compatibility, the schema/metadata APIs will continue to function.

Endpoint
--------

All requests are ``POST`` requests to the ``/v1/query`` endpoint.

Request structure
-----------------

.. code-block:: http

   POST /v1/query HTTP/1.1

   {
      "type": "<query-type>",
      "args": <args-object>
   }

Request body
^^^^^^^^^^^^

.. parsed-literal::

   :ref:`Query <schema_metadata_api_query>`

.. _schema_metadata_api_query:

Query
*****

.. list-table::
   :header-rows: 1

   * - Key
     - Required
     - Schema
     - Description
   * - type
     - true
     - String
     - Type of the query
   * - args
     - true
     - JSON Value
     - The arguments to the query
   * - version
     - false
     - Integer
     - Version of the API (default: 1)

Request types
-------------

The various types of queries are listed in the following table:

.. list-table::
   :header-rows: 1

   * - ``type``
     - ``args``
     - ``version``
     - Synopsis

   * - **bulk**
     - :ref:`Query <schema_metadata_api_query>` array
     - 1
     - Execute multiple operations in a single query

   * - :ref:`schema_metadata_run_sql`
     - :ref:`run_sql_args <schema_metadata_run_sql_syntax>`
     - 1
     - Run SQL directly on Postgres

   * - :ref:`schema_metadata_track_table`
     - :ref:`TableName <TableName>`
     - 1
     - Add a table/view

   * - :ref:`track_table <schema_metadata_track_table_v2>`
     - :ref:`track_table_args <schema_metadata_track_table_syntax_v2>`
     - 2
     - Add a table/view with configuration

   * - :ref:`set_table_customization <schema_metadata_set_table_customization>`
     - :ref:`set_table_customization_args <schema_metadata_set_table_customization_syntax>`
     - 1
     - Set table customization of an already tracked table

   * - :ref:`set_table_custom_fields <schema_metadata_set_table_custom_fields>` (deprecated)
     - :ref:`set_table_custom_fields_args <schema_metadata_set_table_custom_fields_syntax>`
     - 2
     - Set custom fields of an already tracked table (deprecated)

   * - :ref:`schema_metadata_untrack_table`
     - :ref:`untrack_table_args <schema_metadata_untrack_table_syntax>`
     - 1
     - Remove a table/view

   * - :ref:`schema_metadata_set_table_is_enum`
     - :ref:`set_table_is_enum_args <schema_metadata_set_table_is_enum_syntax>`
     - 1
     - Set a tracked table as an enum table

   * - :ref:`schema_metadata_track_function`
     - :ref:`FunctionName <FunctionName>`
     - 1
     - Add an SQL function

   * - :ref:`schema_metadata_track_function`
     - :ref:`track_function_args <schema_metadata_track_function_syntax_v2>`
     - 2
     - Add an SQL function with configuration

   * - :ref:`schema_metadata_untrack_function`
     - :ref:`FunctionName <FunctionName>`
     - 1
     - Remove an SQL function

   * - :ref:`schema_metadata_create_object_relationship`
     - :ref:`create_object_relationship_args <schema_metadata_create_object_relationship_syntax>`
     - 1
     - Define a new object relationship

   * - :ref:`schema_metadata_create_array_relationship`
     - :ref:`create_array_relationship_args <schema_metadata_create_array_relationship_syntax>`
     - 1
     - Define a new array relationship

   * - :ref:`schema_metadata_drop_relationship`
     - :ref:`drop_relationship_args <schema_metadata_drop_relationship_syntax>`
     - 1
     - Drop an existing relationship

   * - :ref:`schema_metadata_rename_relationship`
     - :ref:`rename_relationship_args <schema_metadata_rename_relationship_syntax>`
     - 1
     - Modify name of an existing relationship

   * - :ref:`schema_metadata_set_relationship_comment`
     - :ref:`set_relationship_comment_args <schema_metadata_set_relationship_comment_syntax>`
     - 1
     - Set comment on an existing relationship

   * - :ref:`schema_metadata_add_computed_field`
     - :ref:`add_computed_field_args <schema_metadata_add_computed_field_syntax>`
     - 1
     - Add a computed field

   * - :ref:`schema_metadata_drop_computed_field`
     - :ref:`drop_computed_field_args <schema_metadata_drop_computed_field_syntax>`
     - 1
     - Drop a computed field

   * - :ref:`schema_metadata_create_insert_permission`
     - :ref:`create_insert_permission_args <schema_metadata_create_insert_permission_syntax>`
     - 1
     - Specify insert permission

   * - :ref:`schema_metadata_drop_insert_permission`
     - :ref:`drop_insert_permission_args <schema_metadata_drop_insert_permission_syntax>`
     - 1
     - Remove existing insert permission

   * - :ref:`schema_metadata_create_select_permission`
     - :ref:`create_select_permission_args <schema_metadata_create_select_permission_syntax>`
     - 1
     - Specify select permission

   * - :ref:`schema_metadata_drop_select_permission`
     - :ref:`drop_select_permission_args <schema_metadata_drop_select_permission_syntax>`
     - 1
     - Remove existing select permission

   * - :ref:`schema_metadata_create_update_permission`
     - :ref:`create_update_permission_args <schema_metadata_create_update_permission_syntax>`
     - 1
     - Specify update permission

   * - :ref:`schema_metadata_drop_update_permission`
     - :ref:`drop_update_permission_args <schema_metadata_drop_update_permission_syntax>`
     - 1
     - Remove existing update permission

   * - :ref:`schema_metadata_create_delete_permission`
     - :ref:`create_delete_permission_args <schema_metadata_create_delete_permission_syntax>`
     - 1
     - Specify delete permission

   * - :ref:`schema_metadata_drop_delete_permission`
     - :ref:`drop_delete_permission_args <schema_metadata_drop_delete_permission_syntax>`
     - 1
     - Remove existing delete permission

   * - :ref:`schema_metadata_set_permission_comment`
     - :ref:`set_permission_comment_args <schema_metadata_set_permission_comment_syntax>`
     - 1
     - Set comment on an existing permission

   * - :ref:`schema_metadata_create_event_trigger`
     - :ref:`create_event_trigger_args <schema_metadata_create_event_trigger_syntax>`
     - 1
     - Create or replace an event trigger

   * - :ref:`schema_metadata_delete_event_trigger`
     - :ref:`delete_event_trigger_args <schema_metadata_delete_event_trigger_syntax>`
     - 1
     - Delete an existing event trigger

   * - :ref:`schema_metadata_redeliver_event`
     - :ref:`redeliver_event_args <schema_metadata_redeliver_event_syntax>`
     - 1
     - Redeliver an existing event

   * - :ref:`schema_metadata_invoke_event_trigger`
     - :ref:`invoke_event_trigger_args <schema_metadata_invoke_event_trigger_syntax>`
     - 1
     - Invoke a trigger with custom payload

   * - :ref:`schema_metadata_create_cron_trigger`
     - :ref:`create_cron_trigger_args <schema_metadata_create_cron_trigger_syntax>`
     - 1
     - Create a cron trigger

   * - :ref:`schema_metadata_delete_cron_trigger`
     - :ref:`delete_cron_trigger_args <schema_metadata_delete_cron_trigger_syntax>`
     - 1
     - Delete an existing cron trigger

   * - :ref:`metadata_get_cron_triggers`
     - :ref:`Empty Object`
     - 1
     - Fetch all the cron triggers

   * - :ref:`schema_metadata_create_scheduled_event`
     - :ref:`create_scheduled_event_args <schema_metadata_create_scheduled_event_syntax>`
     - 1
     - Create a new scheduled event

   * - :ref:`schema_metadata_add_remote_schema`
     - :ref:`add_remote_schema_args <schema_metadata_add_remote_schema_syntax>`
     - 1
     - Add a remote GraphQL server as a remote schema

   * - :ref:`schema_metadata_update_remote_schema`
     - :ref:`update_remote_schema_args <schema_metadata_update_remote_schema_syntax>`
     - 1
     - Update the details for a remote schema

   * - :ref:`schema_metadata_remove_remote_schema`
     - :ref:`remove_remote_schema_args <schema_metadata_remove_remote_schema_syntax>`
     - 1
     - Remove an existing remote schema

   * - :ref:`schema_metadata_reload_remote_schema`
     - :ref:`reload_remote_schema_args <schema_metadata_reload_remote_schema_syntax>`
     - 1
     - Reload schema of an existing remote schema

   * - :ref:`schema_metadata_add_remote_schema_permissions`
     - :ref:`add_remote_schema_permissions <schema_metadata_add_remote_schema_permissions_syntax>`
     - 1
     - Add permissions to a role of an existing remote schema

   * - :ref:`schema_metadata_drop_remote_schema_permissions`
     - :ref:`drop_remote_schema_permissions <schema_metadata_drop_remote_schema_permissions_syntax>`
     - 1
     - Drop existing permissions defined for a role for a remote schema

   * - :ref:`schema_metadata_create_remote_relationship`
     - :ref:`create_remote_relationship_args <schema_metadata_create_remote_relationship_syntax>`
     - 1
     - Create a remote relationship with an existing remote schema

   * - :ref:`schema_metadata_update_remote_relationship`
     - :ref:`update_remote_relationship_args <schema_metadata_update_remote_relationship_syntax>`
     - 1
     - Update an existing remote relationship

   * - :ref:`schema_metadata_delete_remote_relationship`
     - :ref:`delete_remote_relationship_args <schema_metadata_delete_remote_relationship_syntax>`
     - 1
     - Delete an existing remote relationship

   * - :ref:`schema_metadata_export_metadata`
     - :ref:`Empty Object`
     - 1
     - Export the current metadata

   * - :ref:`schema_metadata_replace_metadata`
     - :ref:`replace_metadata_args <schema_metadata_replace_metadata_syntax>`
     - 1
     - Import and replace existing metadata

   * - :ref:`schema_metadata_reload_metadata`
     - :ref:`reload_metadata_args <schema_metadata_reload_metadata_syntax>`
     - 1
     - Reload changes to the underlying Postgres DB

   * - :ref:`schema_metadata_clear_metadata`
     - :ref:`Empty Object`
     - 1
     - Clear/wipe-out the current metadata state form server

   * - :ref:`schema_metadata_get_inconsistent_metadata`
     - :ref:`Empty Object`
     - 1
     - List all inconsistent metadata objects

   * - :ref:`schema_metadata_drop_inconsistent_metadata`
     - :ref:`Empty Object`
     - 1
     - Drop all inconsistent metadata objects

   * - :ref:`schema_metadata_create_query_collection`
     - :ref:`create_query_collection_args <schema_metadata_create_query_collection_syntax>`
     - 1
     - Create a query collection

   * - :ref:`schema_metadata_drop_query_collection`
     - :ref:`drop_query_collection_args <schema_metadata_drop_query_collection_syntax>`
     - 1
     - Drop a query collection

   * - :ref:`schema_metadata_add_query_to_collection`
     - :ref:`add_query_to_collection_args <schema_metadata_add_query_to_collection_syntax>`
     - 1
     - Add a query to a given collection

   * - :ref:`schema_metadata_drop_query_from_collection`
     - :ref:`drop_query_from_collection_args <schema_metadata_drop_query_from_collection_syntax>`
     - 1
     - Drop a query from a given collection

   * - :ref:`schema_metadata_add_collection_to_allowlist`
     - :ref:`add_collection_to_allowlist_args <schema_metadata_add_collection_to_allowlist_syntax>`
     - 1
     - Add a collection to the allow-list

   * - :ref:`schema_metadata_drop_collection_from_allowlist`
     - :ref:`drop_collection_from_allowlist_args <schema_metadata_drop_collection_from_allowlist_syntax>`
     - 1
     - Drop a collection from the allow-list

   * - :ref:`schema_metadata_set_custom_types`
     - :ref:`set_custom_types_args <schema_metadata_set_custom_types_syntax>`
     - 1
     - Set custom GraphQL types

   * - :ref:`schema_metadata_create_action`
     - :ref:`create_action_args <schema_metadata_create_action_syntax>`
     - 1
     - Create an action

   * - :ref:`schema_metadata_drop_action`
     - :ref:`drop_action_args <schema_metadata_drop_action_syntax>`
     - 1
     - Drop an action

   * - :ref:`schema_metadata_update_action`
     - :ref:`update_action_args <schema_metadata_update_action_syntax>`
     - 1
     - Update an action

   * - :ref:`schema_metadata_create_action_permission`
     - :ref:`create_action_permission_args <schema_metadata_create_action_permission_syntax>`
     - 1
     - Create an action permission

   * - :ref:`schema_metadata_drop_action_permission`
     - :ref:`drop_action_permission_args <schema_metadata_drop_action_permission_syntax>`
     - 1
     - Drop an action permission

   * - :ref:`schema_metadata_create_rest_endpoint`
     - :ref:`create_rest_endpoint_args <schema_metadata_create_rest_endpoint_syntax>`
     - 3
     - Create a RESTified GraphQL Endpoint

   * - :ref:`schema_metadata_drop_rest_endpoint`
     - :ref:`drop_rest_endpoint_args <schema_metadata_drop_rest_endpoint_syntax>`
     - 3
     - Drop a RESTified GraphQL Endpoint

**See:**

- :ref:`Run SQL <schema_metadata_api_run_sql>`
- :ref:`Tables/Views <schema_metadata_api_tables_views>`
- :ref:`Custom SQL Functions <schema_metadata_api_custom_functions>`
- :ref:`Relationships <schema_metadata_api_relationship>`
- :ref:`Computed Fields <schema_metadata_api_computed_field>`
- :ref:`Permissions <schema_metadata_api_permission>`
- :ref:`Remote Schema Permissions <schema_metadata_remote_schema_api_permission>`
- :ref:`Event Triggers <schema_metadata_api_event_triggers>`
- :ref:`Remote Schemas <schema_metadata_api_remote_schemas>`
- :ref:`Query Collections <schema_metadata_api_query_collections>`
- :ref:`Custom Types <schema_metadata_api_custom_types>`
- :ref:`Actions <schema_metadata_api_actions>`
- :ref:`Manage Metadata <schema_metadata_api_manage_metadata>`

Response structure
------------------

.. list-table::
   :widths: 10 10 30
   :header-rows: 1

   * - Status code
     - Description
     - Response structure

   * - ``200``
     - Success
     - .. parsed-literal::

        Request specific

   * - ``400``
     - Bad request
     - .. code-block:: haskell

          {
              "path"  : String,
              "error" : String
          }

   * - ``401``
     - Unauthorized
     - .. code-block:: haskell

          {
              "error" : String
          }

   * - ``500``
     - Internal server error
     - .. code-block:: haskell

          {
              "error" : String
          }


Error codes
-----------

.. csv-table::
   :file: dataerrors.csv
   :widths: 10, 20, 70
   :header-rows: 1

Disabling schema / metadata API
-------------------------------

Since this API can be used to make changes to the GraphQL schema, it can be
disabled, especially in production deployments.

The ``enabled-apis`` flag or the ``HASURA_GRAPHQL_ENABLED_APIS`` env var can be used to
enable/disable this API. By default, the schema/metadata API is enabled. To disable it, you need
to explicitly state that this API is not enabled i.e. remove it from the list of enabled APIs.

.. code-block:: bash

   # enable only graphql api, disable metadata and pgdump
   --enabled-apis="graphql"
   HASURA_GRAPHQL_ENABLED_APIS="graphql"

See :ref:`server_flag_reference` for info on setting the above flag/env var.

.. toctree::
  :maxdepth: 1
  :hidden:

  Run SQL <run-sql>
  Tables/Views <table-view>
  Custom Functions <custom-functions>
  Relationships <relationship>
  Permissions <permission>
  Remote Schema Permissions <remote-schema-permissions>
  Computed Fields <computed-field>
  Event Triggers <event-triggers>
  Scheduled Triggers <scheduled-triggers>
  Remote Schemas <remote-schemas>
  Remote Relationships <remote-relationships>
  Query Collections <query-collections>
  RESTified GraphQL Endpoints <restified-endpoints>
  Custom Types <custom-types>
  Actions <actions>
  Manage Metadata <manage-metadata>
