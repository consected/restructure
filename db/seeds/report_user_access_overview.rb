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
        res.disabled = false
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
      # Shared search attributes for the first three perspectives (by_role,
      # by_resource, resolved). User and App Type are required for meaningful
      # results; Resource Type, Resource Name, and Role are optional filters.
      search_attrs = <<~END_YAML
        user:
          user:
            label: 'User (required)'
            multiple: single
            default: current_user
        app_type_id:
          select_from_model:
            label: 'App Type (required)'
            multiple: single
            resource_name: admin__app_types
            selections:
              name: id
            default: '{{current_user_app_type_id}}'
        resource_type:
          config_selector:
            label: 'Resource Type (optional)'
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
            label: 'Resource Name (optional)'
            resource_name: admin__user_access_controls
            selections:
              resource_name: resource_name
            group_by: resource_type
            all: true
        role_name:
          select_from_model:
            label: 'Role (optional)'
            resource_name: admin__user_roles
            selections:
              role_name: role_name
            all: true
      END_YAML

      # Search attributes for the roles-by-user perspective (roles_only).
      # App Type is required; User and Role are optional filters.
      search_attrs_roles_with_user = <<~END_YAML
        app_type_id:
          select_from_model:
            label: 'App Type (required)'
            multiple: single
            resource_name: admin__app_types
            selections:
              name: id
            default: '{{current_user_app_type_id}}'
        user:
          user:
            label: 'User (optional)'
            multiple: single
        role_name:
          select_from_model:
            label: 'Role (optional)'
            resource_name: admin__user_roles
            selections:
              role_name: role_name
            all: true
      END_YAML

      # Search attributes for the users-by-role perspective (users_with_role)
      # match the roles-by-user perspective.
      search_attrs_users_with_role = search_attrs_roles_with_user

      # Search attributes for the resource-focused perspective.
      # App Type is required; Resource Type and Resource Name are optional
      # so admins can scope to a single resource or browse all resources.
      search_attrs_resource_focus = <<~END_YAML
        app_type_id:
          select_from_model:
            label: 'App Type (required)'
            multiple: single
            resource_name: admin__app_types
            selections:
              name: id
            default: '{{current_user_app_type_id}}'
        resource_type:
          config_selector:
            label: 'Resource Type (optional)'
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
            label: 'Resource Name (optional)'
            resource_name: admin__user_access_controls
            selections:
              resource_name: resource_name
            group_by: resource_type
            all: true
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

      # ── Perspective 6: Resource Focused By Role / Source ─────────────

      p6_options = <<~END_YAML
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
            blank: ' '
            source: 'Assigned via'
            role_name: 'Role (where applicable)'
            user_email: 'User (where applicable)'
            resource_type: 'Resource Type'
            resource_name: 'Resource Name'
            access: 'Access'
            app_scope: 'App Type Scope'
          show_as:
            role_name: url
            user_email: url
            resource_name: url
            app_scope: url
      END_YAML

      p6_sql = <<~END_SQL
        -- User Access Overview - Perspective 6: Resource-focused by role/source
        -- Shows all grants for selected resource(s), grouped first by resource
        -- (resource_type / resource_name). Each grouped child row shows the
        -- assignment source: direct user-specific grant, role-based grant, or
        -- default fallback. Role and user are surfaced in dedicated columns so
        -- the source label remains short and free of duplicated identifiers.

        SELECT
          uac.resource_type || ' / ' || uac.resource_name AS id0,
          uac.resource_type || ' / ' || uac.resource_name || '--' || uac.id AS id1,
          CASE
            WHEN uac.user_id IS NOT NULL THEN '(direct - user-specific)'
            WHEN uac.role_name IS NOT NULL AND uac.role_name <> '' THEN '(role-based)'
            ELSE '(default - fallback)'
          END AS source,
          CASE
            WHEN uac.role_name IS NOT NULL AND uac.role_name <> '' THEN
              '[' || uac.role_name || '](/admin/user_roles?filter[role_name]=' || uac.role_name || ')'
            ELSE ''
          END AS role_name,
          CASE
            WHEN uac.user_id IS NOT NULL THEN
              '[' || u.email || '](/admin/manage_users?filter[email]=' || u.email || ')'
            ELSE ''
          END AS user_email,
          uac.resource_type,
          '[' || uac.resource_name || '](/admin/user_access_controls?filter[resource_name]=' || uac.resource_name || '&filter[resource_type]=' || uac.resource_type || ')' AS resource_name,
          uac.access,
          CASE
            WHEN uac.app_type_id IS NULL THEN '(all)'
            ELSE '[' || at.name || '](/admin/app_types/' || uac.app_type_id || ')'
          END AS app_scope

        FROM ml_app.user_access_controls uac
        LEFT JOIN ml_app.users u ON uac.user_id = u.id
        LEFT JOIN ml_app.app_types at ON uac.app_type_id = at.id

        WHERE uac.disabled IS NOT TRUE
          AND (u.id IS NULL OR u.disabled IS NOT TRUE)
          AND (uac.app_type_id = CAST(NULLIF(:app_type_id, '') AS INTEGER) OR uac.app_type_id IS NULL)
          AND (COALESCE(:resource_type, '') = '' OR uac.resource_type = :resource_type)
          AND (COALESCE(:resource_name, '') = '' OR uac.resource_name = :resource_name)

        ORDER BY
          uac.resource_type ASC,
          uac.resource_name ASC,
          CASE
            WHEN uac.user_id IS NOT NULL THEN '0-direct'
            WHEN uac.role_name IS NOT NULL AND uac.role_name <> '' THEN '1-' || uac.role_name
            ELSE '2-default'
          END,
          uac.app_type_id ASC NULLS LAST,
          u.email ASC NULLS LAST
        ;
      END_SQL

      # ── Build report and UAC arrays ─────────────────────────────────────

      report_values = [
        {
          name: "User Access Controls - Selected User's Grants by Role",
          item_type: 'admin-user-access-overview',
          short_name: 'user_access_overview_by_role',
          description: 'Lists every access control granted to the selected user, grouped by the role that grants it (or shown as a direct user assignment). Raw, unresolved entries — the same resource may appear more than once under different roles.',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          position: 1,
          options: p1_options,
          sql: p1_sql,
          search_attrs: search_attrs
        },
        {
          name: "User Access Controls - Selected User's Grants by Resource",
          item_type: 'admin-user-access-overview',
          short_name: 'user_access_overview_by_resource',
          description: 'Lists every access control granted to the selected user, grouped by resource. Raw, unresolved entries from all roles and direct assignments — the same resource may appear more than once with different access levels.',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          position: 2,
          options: p2_options,
          sql: p2_sql,
          search_attrs: search_attrs
        },
        {
          name: "User Access Controls - Selected User's Effective Access",
          item_type: 'admin-user-access-overview',
          short_name: 'user_access_overview_resolved',
          description: 'Shows the effective access the selected user has for each resource after role precedence and resolution rules have been applied. Each resource appears once, with the access level that actually takes effect.',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          position: 3,
          options: p3_options,
          sql: p3_sql,
          search_attrs: search_attrs
        },
        {
          name: "User Roles - Each User's Roles",
          item_type: 'admin-user-access-overview',
          short_name: 'user_access_overview_roles_only',
          description: 'Lists each user in the selected app type with the roles assigned to them. One row per user-role assignment, ordered by user. Does not include resource-level access controls.',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          position: 5,
          options: p4_options,
          sql: p4_sql,
          search_attrs: search_attrs_roles_with_user
        },
        {
          name: "User Roles - Each Role's Users",
          item_type: 'admin-user-access-overview',
          short_name: 'user_access_overview_users_with_role',
          description: 'Lists each role in the selected app type with the users assigned to it. One row per user-role assignment, ordered by role. Does not include resource-level access controls.',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          position: 6,
          options: p5_options,
          sql: p5_sql,
          search_attrs: search_attrs_users_with_role
        },
        {
          name: 'User Access Controls - Resource Grants by Role/Source',
          item_type: 'admin-user-access-overview',
          short_name: 'user_access_overview_resource_by_role',
          description: 'Lists access controls for selected resource(s), grouped by assignment source so admins can audit role-based grants, direct user assignments, and default fallback controls.',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          position: 4,
          options: p6_options,
          sql: p6_sql,
          search_attrs: search_attrs_resource_focus
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
        },
        {
          resource_type: 'report',
          access: nil,
          resource_name: 'admin_user_access_overview__user_access_overview_resource_by_role'
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
