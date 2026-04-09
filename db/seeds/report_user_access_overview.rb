# frozen_string_literal: true

module Seeds
  module ReportUserAccessOverview
    def self.do_last
      true
    end

    def self.add_report_values(values)
      values.each do |v|
        res = Report.find_or_initialize_by(short_name: v[:short_name], item_type: v[:item_type])
        res.assign_attributes(v)
        res.current_admin = Seeds.auto_admin
        res.save!
      end
    end

    def self.add_uac_values(values)
      values.each do |v|
        res = Admin::UserAccessControl.find_or_initialize_by(v)
        res.update(current_admin: Seeds.auto_admin) unless res.admin
      end
    end

    def self.create_templates
      # Shared search attributes for all perspectives
      search_attrs = <<~END_YAML
        user:
          user:
            multiple: single
            default: current_user
        role_name:
          select_from_model:
            resource_name: admin__user_roles
            selections:
              role_name: role_name
            all: true
        resource_type:
          config_selector:
            label: Resource Type
            multiple: single
            all: true
            filter_selector: resource_name
            selections:
              table: table
              general: general
              limited_access: limited_access
              report: report
              standalone_page: standalone_page
              activity_log_type: activity_log_type
        resource_name:
          select_from_model:
            resource_name: admin__user_access_controls
            selections:
              resource_name: resource_name
            group_by: resource_type
            all: true
        app_type_id:
          select_from_model:
            multiple: single
            resource_name: admin__app_types
            selections:
              name: id
            default: '{{current_user_app_type_id}}'
      END_YAML

      search_attrs_roles_with_user = <<~END_YAML
        user:
          user:
            multiple: single
        role_name:
          select_from_model:
            resource_name: admin__user_roles
            selections:
              role_name: role_name
            all: true
        app_type_id:
          select_from_model:
            multiple: single
            resource_name: admin__app_types
            selections:
              name: id
            default: '{{current_user_app_type_id}}'
      END_YAML

      search_attrs_users_with_role = <<~END_YAML
        user:
          user:
            multiple: single
        role_name:
          select_from_model:
            resource_name: admin__user_roles
            selections:
              role_name: role_name
            all: true
        app_type_id:
          select_from_model:
            multiple: single
            resource_name: admin__app_types
            selections:
              name: id
            default: '{{current_user_app_type_id}}'
      END_YAML

      # ── Perspective 1: By Role ──────────────────────────────────────────

      p1_options = <<~END_YAML
        view_options:
          view_as: tree
          report_auto_submit_on_change: false
          hide_field_names_with_comments: true
          hide_result_count: false
          no_results_scroll: true

        tree_view_options:
          num_levels: 2
          expand_level: 1
          column_levels:
            -
              - id0
              - source

        column_options:
          alt_column_header:
            id0: '[expand]'
            source: 'Assigned via (role name)'
            resource_type: 'Resource Type'
            resource_name: 'Resource Name'
            access: 'Access'
            app_scope: 'App Type Scope'
            user_email: 'User'
          show_as:
            resource_name: url
            source: url
            app_scope: url
            user_email: url
      END_YAML

      p1_sql = <<~END_SQL
        -- User Access Overview - Perspective 1: User -> Roles / Direct -> UACs
        -- Shows all user access controls grouped by the access source (role name or "direct")

        WITH target_user AS (
          SELECT id, email
          FROM ml_app.users
          WHERE id = CAST(NULLIF(:user, '') AS INTEGER)
            AND disabled IS NOT TRUE
        ),
        user_roles AS (
          SELECT DISTINCT ur.role_name, ur.app_type_id, ur.user_id
          FROM ml_app.user_roles ur
          INNER JOIN target_user tu ON ur.user_id = tu.id
          WHERE ur.disabled IS NOT TRUE
            AND (ur.app_type_id = CAST(NULLIF(:app_type_id, '') AS INTEGER) OR ur.app_type_id IS NULL)
            AND (COALESCE(:role_name, '') = '' OR ur.role_name = :role_name)
        )
        SELECT
          CASE
            WHEN uac.user_id IS NOT NULL THEN '(direct - user-specific)'
            WHEN uac.role_name IS NOT NULL AND uac.role_name <> '' THEN uac.role_name
            ELSE '(default - fallback)'
          END AS id0,
          uac.id AS id1,
          ' ' blank,
          CASE
            WHEN uac.user_id IS NOT NULL THEN
              '[(direct - user-specific)](/admin/user_access_controls?filter[user_id]=' || uac.user_id || '&filter[resource_name]=' || uac.resource_name || '&filter[resource_type]=' || uac.resource_type || ')'
            WHEN uac.role_name IS NOT NULL AND uac.role_name <> '' THEN
              '[' || uac.role_name || '](/admin/user_roles?filter[role_name]=' || uac.role_name || ')'
            ELSE '[(default - fallback)](/admin/user_access_controls?filter[resource_name]=' || uac.resource_name || '&filter[resource_type]=' || uac.resource_type || ')'
          END AS source,
          uac.resource_type,
          '[' || uac.resource_name || '](/admin/user_access_controls?filter[resource_name]=' || uac.resource_name || '&filter[resource_type]=' || uac.resource_type || ')' AS resource_name,
          uac.access,
          CASE
            WHEN uac.app_type_id IS NULL THEN '(all)'
            ELSE '[' || at.name || '](/admin/app_types/' || uac.app_type_id || ')'
          END AS app_scope,
          '[' || tu.email || '](/admin/manage_users?filter[email]=' || tu.email || ')' AS user_email

        FROM ml_app.user_access_controls uac
        LEFT JOIN ml_app.app_types at ON uac.app_type_id = at.id
        CROSS JOIN target_user tu

        WHERE uac.disabled IS NOT TRUE
          AND (uac.app_type_id = CAST(NULLIF(:app_type_id, '') AS INTEGER) OR uac.app_type_id IS NULL)
          AND (COALESCE(:resource_type, '') = '' OR uac.resource_type = :resource_type)
          AND (COALESCE(:resource_name, '') = '' OR uac.resource_name = :resource_name)
          AND (COALESCE(:role_name, '') = '' OR uac.role_name = :role_name)
          AND (
            uac.user_id = tu.id
            OR (
              uac.role_name IN (SELECT ur.role_name FROM user_roles ur WHERE ur.user_id = tu.id)
              AND uac.user_id IS NULL
            )
            OR (
              uac.user_id IS NULL
              AND (uac.role_name IS NULL OR uac.role_name = '')
            )
          )

        ORDER BY
          id0,
          id1,
          uac.app_type_id ASC NULLS LAST,
          CASE
            WHEN uac.user_id IS NOT NULL THEN '0-direct'
            WHEN uac.role_name IS NOT NULL AND uac.role_name <> '' THEN '1-' || uac.role_name
            ELSE '2-default'
          END,
          uac.resource_type ASC,
          uac.resource_name ASC
        ;
      END_SQL

      # ── Perspective 2: By Resource ──────────────────────────────────────

      p2_options = <<~END_YAML
        view_options:
          view_as: tree
          report_auto_submit_on_change: false
          hide_field_names_with_comments: true
          hide_result_count: false
          no_results_scroll: true

        tree_view_options:
          num_levels: 2
          expand_level: 1
          column_levels:
            -
              - id0
              - resource_type
              - resource_name

        column_options:
          alt_column_header:
            id0: '[expand]'
            source: 'Assigned via (role name)'
            resource_type: 'Resource Type'
            resource_name: 'Resource Name'
            access: 'Access'
            app_scope: 'App Type Scope'
          show_as:
            resource_name: url
            source: url
            app_scope: url
      END_YAML

      p2_sql = <<~END_SQL
        -- User Access Overview - Perspective 2: By Resource
        -- Shows all user access controls grouped by resource

        WITH target_user AS (
          SELECT id, email
          FROM ml_app.users
          WHERE id = CAST(NULLIF(:user, '') AS INTEGER)
            AND disabled IS NOT TRUE
        ),
        user_roles AS (
          SELECT DISTINCT ur.role_name, ur.app_type_id, ur.user_id
          FROM ml_app.user_roles ur
          INNER JOIN target_user tu ON ur.user_id = tu.id
          WHERE ur.disabled IS NOT TRUE
            AND (ur.app_type_id = CAST(NULLIF(:app_type_id, '') AS INTEGER) OR ur.app_type_id IS NULL)
            AND (COALESCE(:role_name, '') = '' OR ur.role_name = :role_name)
        )
        SELECT
          uac.resource_type || ' / ' || uac.resource_name AS id0,
          uac.resource_type || ' / ' || uac.resource_name || '--' || uac.id AS id1,
          ' ' blank,
          CASE
            WHEN uac.user_id IS NOT NULL THEN
              '[(direct - user-specific)](/admin/user_access_controls?filter[user_id]=' || uac.user_id || '&filter[resource_name]=' || uac.resource_name || '&filter[resource_type]=' || uac.resource_type || ')'
            WHEN uac.role_name IS NOT NULL AND uac.role_name <> '' THEN
              '[' || uac.role_name || '](/admin/user_roles?filter[role_name]=' || uac.role_name || ')'
            ELSE '[(default - fallback)](/admin/user_access_controls?filter[resource_name]=' || uac.resource_name || '&filter[resource_type]=' || uac.resource_type || ')'
          END AS source,
          uac.resource_type,
          '[' || uac.resource_name || '](/admin/user_access_controls?filter[resource_name]=' || uac.resource_name || '&filter[resource_type]=' || uac.resource_type || ')' AS resource_name,
          uac.access,
          CASE
            WHEN uac.app_type_id IS NULL THEN '(all)'
            ELSE '[' || at.name || '](/admin/app_types/' || uac.app_type_id || ')'
          END AS app_scope

        FROM ml_app.user_access_controls uac
        LEFT JOIN ml_app.app_types at ON uac.app_type_id = at.id
        CROSS JOIN target_user tu

        WHERE uac.disabled IS NOT TRUE
          AND (uac.app_type_id = CAST(NULLIF(:app_type_id, '') AS INTEGER) OR uac.app_type_id IS NULL)
          AND (COALESCE(:resource_type, '') = '' OR uac.resource_type = :resource_type)
          AND (COALESCE(:resource_name, '') = '' OR uac.resource_name = :resource_name)
          AND (COALESCE(:role_name, '') = '' OR uac.role_name = :role_name)
          AND (
            uac.user_id = tu.id
            OR (
              uac.role_name IN (SELECT ur.role_name FROM user_roles ur WHERE ur.user_id = tu.id)
              AND uac.user_id IS NULL
            )
            OR (
              uac.user_id IS NULL
              AND (uac.role_name IS NULL OR uac.role_name = '')
            )
          )

        ORDER BY
          id0,
          id1,
          uac.resource_type ASC,
          uac.resource_name ASC,
          uac.app_type_id ASC NULLS LAST,
          CASE
            WHEN uac.user_id IS NOT NULL THEN '0-direct'
            WHEN uac.role_name IS NOT NULL AND uac.role_name <> '' THEN '1-' || uac.role_name
            ELSE '2-default'
          END
        ;
      END_SQL

      # ── Perspective 3: Resolved ─────────────────────────────────────────

      p3_options = <<~END_YAML
        view_options:
          view_as: tree
          report_auto_submit_on_change: false
          hide_field_names_with_comments: true
          hide_result_count: false
          no_results_scroll: true

        tree_view_options:
          num_levels: 2
          expand_level: 1
          column_levels:
            -
              - id0
              - resource_type
              - resource_name

        column_options:
          alt_column_header:
            id0: '[expand]'
            source: 'Resolved via (role name)'
            resource_type: 'Resource Type'
            resource_name: 'Resource Name'
            access: 'Access'
            app_scope: 'App Type Scope'
          show_as:
            resource_name: url
            source: url
            app_scope: url
      END_YAML

      p3_sql = <<~END_SQL
        -- User Access Overview - Perspective 3: Resolved
        -- One effective UAC per resource after priority resolution

        WITH target_user AS (
          SELECT id, email
          FROM ml_app.users
          WHERE id = CAST(NULLIF(:user, '') AS INTEGER)
            AND disabled IS NOT TRUE
        ),
        user_roles AS (
          SELECT DISTINCT ur.role_name, ur.app_type_id, ur.user_id
          FROM ml_app.user_roles ur
          INNER JOIN target_user tu ON ur.user_id = tu.id
          WHERE ur.disabled IS NOT TRUE
            AND (ur.app_type_id = CAST(NULLIF(:app_type_id, '') AS INTEGER) OR ur.app_type_id IS NULL)
            AND (COALESCE(:role_name, '') = '' OR ur.role_name = :role_name)
        )
        SELECT DISTINCT ON (uac.resource_type, uac.resource_name)
          uac.resource_type || ' / ' || uac.resource_name AS id0,
          uac.resource_type || ' / ' || uac.resource_name || '--' || uac.id AS id1,
          ' ' blank,
          uac.resource_type,
          '[' || uac.resource_name || '](/admin/user_access_controls?filter[resource_name]=' || uac.resource_name || '&filter[resource_type]=' || uac.resource_type || ')' AS resource_name,
          uac.access,
          CASE
            WHEN uac.user_id IS NOT NULL THEN
              '[(direct - user-specific)](/admin/user_access_controls?filter[user_id]=' || uac.user_id || '&filter[resource_name]=' || uac.resource_name || '&filter[resource_type]=' || uac.resource_type || ')'
            WHEN uac.role_name IS NOT NULL AND uac.role_name <> '' THEN
              '[' || uac.role_name || '](/admin/user_roles?filter[role_name]=' || uac.role_name || ')'
            ELSE '[(default - fallback)](/admin/user_access_controls?filter[resource_name]=' || uac.resource_name || '&filter[resource_type]=' || uac.resource_type || ')'
          END AS source,
          CASE
            WHEN uac.app_type_id IS NULL THEN '(all)'
            ELSE '[' || at.name || '](/admin/app_types/' || uac.app_type_id || ')'
          END AS app_scope,
          CASE
            WHEN uac.user_id IS NOT NULL THEN 0
            WHEN uac.role_name IS NOT NULL AND uac.role_name <> '' THEN 1
            ELSE 2
          END  as reorder

        FROM ml_app.user_access_controls uac
        LEFT JOIN ml_app.app_types at ON uac.app_type_id = at.id
        CROSS JOIN target_user tu

        WHERE uac.disabled IS NOT TRUE
          AND (uac.app_type_id = CAST(NULLIF(:app_type_id, '') AS INTEGER) OR uac.app_type_id IS NULL)
          AND (COALESCE(:resource_type, '') = '' OR uac.resource_type = :resource_type)
          AND (COALESCE(:resource_name, '') = '' OR uac.resource_name = :resource_name)
          AND (COALESCE(:role_name, '') = '' OR uac.role_name = :role_name)
          AND (
            uac.user_id = tu.id
            OR (
              uac.role_name IN (SELECT ur.role_name FROM user_roles ur WHERE ur.user_id = tu.id)
              AND uac.user_id IS NULL
            )
            OR (
              uac.user_id IS NULL
              AND (uac.role_name IS NULL OR uac.role_name = '')
            )
          )

        ORDER BY
          uac.resource_type, uac.resource_name,
          id0,
          reorder
        ;
      END_SQL

      # ── Perspective 4: Roles Only ───────────────────────────────────────

      p4_options = <<~END_YAML
        view_options:
          view_as: tree
          report_auto_submit_on_change: false
          hide_field_names_with_comments: true
          hide_result_count: false
          no_results_scroll: true

        tree_view_options:
          num_levels: 2
          expand_level: 1
          column_levels:
            -
              - id0
              - user_email

        column_options:
          alt_column_header:
            id0: '[expand]'
            role_name: 'Role Name'
            app_scope: 'App Type Scope'
            user_email: 'User'
          show_as:
            role_name: url
            app_scope: url
            user_email: url
      END_YAML

      p4_sql = <<~END_SQL
        -- User Access Overview - Perspective 4: Roles Only
        -- Lists roles assigned to a user (or all users) in the selected app type

        SELECT
          u.email AS id0,
          ur.id AS id1,
          ' ' blank,
          '[' || ur.role_name || '](/admin/user_roles?filter[role_name]=' || ur.role_name || ')' AS role_name,
          CASE
            WHEN ur.app_type_id IS NULL THEN '(all)'
            ELSE '[' || at.name || '](/admin/app_types/' || ur.app_type_id || ')'
          END AS app_scope,
          '[' || u.email || '](/admin/manage_users?filter[email]=' || u.email || ')' AS user_email

        FROM ml_app.user_roles ur
        INNER JOIN ml_app.users u ON ur.user_id = u.id
        LEFT JOIN ml_app.app_types at ON ur.app_type_id = at.id

        WHERE u.disabled IS NOT TRUE
          AND ur.disabled IS NOT TRUE
          AND (NULLIF(:user, '') IS NULL OR u.id = CAST(NULLIF(:user, '') AS INTEGER))
          AND ur.app_type_id = CAST(NULLIF(:app_type_id, '') AS INTEGER)
          AND (COALESCE(:role_name, '') = '' OR ur.role_name = :role_name)

        ORDER BY u.email ASC, ur.role_name ASC
        ;
      END_SQL

      # ── Perspective 5: Users With Role ────────────────────────────────

      p5_options = <<~END_YAML
        view_options:
          view_as: tree
          report_auto_submit_on_change: false
          hide_field_names_with_comments: true
          hide_result_count: false
          no_results_scroll: true

        tree_view_options:
          num_levels: 2
          expand_level: 1
          column_levels:
            -
              - id0
              - role_name

        column_options:
          alt_column_header:
            id0: '[expand]'
            role_name: 'Role Name'
            app_scope: 'App Type Scope'
            user_email: 'User'
          show_as:
            role_name: url
            app_scope: url
            user_email: url
      END_YAML

      p5_sql = <<~END_SQL
        -- User Access Overview - Perspective 5: Users With Role
        -- Lists users who have a role assigned in the selected app type

        SELECT
          ur.role_name AS id0,
          ur.id AS id1,
          ' ' blank,
          '[' || ur.role_name || '](/admin/user_roles?filter[role_name]=' || ur.role_name || ')' AS role_name,
          CASE
            WHEN ur.app_type_id IS NULL THEN '(all)'
            ELSE '[' || at.name || '](/admin/app_types/' || ur.app_type_id || ')'
          END AS app_scope,
          '[' || u.email || '](/admin/manage_users?filter[email]=' || u.email || ')' AS user_email

        FROM ml_app.user_roles ur
        INNER JOIN ml_app.users u ON ur.user_id = u.id
        LEFT JOIN ml_app.app_types at ON ur.app_type_id = at.id

        WHERE u.disabled IS NOT TRUE
          AND ur.disabled IS NOT TRUE
          AND (NULLIF(:user, '') IS NULL OR u.id = CAST(NULLIF(:user, '') AS INTEGER))
          AND ur.app_type_id = CAST(NULLIF(:app_type_id, '') AS INTEGER)
          AND (COALESCE(:role_name, '') = '' OR ur.role_name = :role_name)

        ORDER BY ur.role_name ASC, u.email ASC
        ;
      END_SQL

      # ── Build report and UAC arrays ─────────────────────────────────────

      report_values = [
        {
          name: 'User Access Overview - By Role',
          item_type: 'admin-user-access-overview',
          short_name: 'user_access_overview_by_role',
          description: 'View all access controls for a user, grouped by role name or direct assignment',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          options: p1_options,
          sql: p1_sql,
          search_attrs: search_attrs
        },
        {
          name: 'User Access Overview - By Resource',
          item_type: 'admin-user-access-overview',
          short_name: 'user_access_overview_by_resource',
          description: 'View all access controls for a user, grouped by resource',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          options: p2_options,
          sql: p2_sql,
          search_attrs: search_attrs
        },
        {
          name: 'User Access Overview - Resolved',
          item_type: 'admin-user-access-overview',
          short_name: 'user_access_overview_resolved',
          description: 'View the effective access for each resource after priority resolution',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          options: p3_options,
          sql: p3_sql,
          search_attrs: search_attrs
        },
        {
          name: 'User Access Overview - Roles Listed by User',
          item_type: 'admin-user-access-overview',
          short_name: 'user_access_overview_roles_only',
          description: 'View the roles assigned to a user in the selected app type',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          options: p4_options,
          sql: p4_sql,
          search_attrs: search_attrs_roles_with_user
        },
        {
          name: 'User Access Overview - Users Listed by Role',
          item_type: 'admin-user-access-overview',
          short_name: 'user_access_overview_users_with_role',
          description: 'View users who have a role assigned in the selected app type',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          options: p5_options,
          sql: p5_sql,
          search_attrs: search_attrs_users_with_role
        }
      ]

      uac_values = [
        {
          resource_type: 'report',
          access: nil,
          resource_name: 'admin_user_access_overview__user_access_overview_by_role'
        },
        {
          resource_type: 'report',
          access: nil,
          resource_name: 'admin_user_access_overview__user_access_overview_by_resource'
        },
        {
          resource_type: 'report',
          access: nil,
          resource_name: 'admin_user_access_overview__user_access_overview_resolved'
        },
        {
          resource_type: 'report',
          access: nil,
          resource_name: 'admin_user_access_overview__user_access_overview_roles_only'
        },
        {
          resource_type: 'report',
          access: nil,
          resource_name: 'admin_user_access_overview__user_access_overview_users_with_role'
        }
      ]

      add_report_values report_values
      add_uac_values uac_values

      # Disable the old landing page report if it exists
      old_p0 = Report.find_by(short_name: 'user_access_overview')
      old_p0&.update(disabled: true, current_admin: Seeds.auto_admin)
    end

    def self.setup
      log "In #{self}.setup"
      create_templates
      log "Ran #{self}.setup"
    end
  end
end
