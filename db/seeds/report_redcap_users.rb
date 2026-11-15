# frozen_string_literal: true

module Seeds
  module ReportRedcapUsers
    def self.add_report_values(values)
      values.each do |v|
        res = Report.find_or_initialize_by(short_name: v[:short_name], item_type: v[:item_type])
        res.assign_attributes(v)
        res.current_admin = Seeds.auto_admin
        res.save!
      end
    end

    def self.create_templates
      search_attrs = <<~END_YAML
        email:
          select_from_model:
            multiple: single
            resource_name: redcap__project_users
            selections:
              email: email
            all: true

        username:
          select_from_model:
            multiple: single
            resource_name: redcap__project_users
            selections:
              username: username
            all: true

        server_url:
          select_from_model:
            multiple: single
            resource_name: redcap__project_admins
            selections:
              server_url: server_url
            all: true
      END_YAML

      options = <<~END_YAML
        column_options:
          show_as:
            name: url
      END_YAML

      sql = <<~END_SQL
        select
        rpa.study,
        '[' || rpa.name || '](/redcap/project_admins?filter[id]=' || rpa.id || '&perform_action=edit)' AS name,
        rpa.server_url,
        rpu.username,
        rpu.email,
        rpu.expiration,
        rpu.disabled
        from redcap_project_users rpu
        inner join redcap_project_admins rpa on rpu.redcap_project_admin_id = rpa.id
        where
        (:email is null or rpu.email ~* :email)
        and (:username is null or rpu.username ~* :username)
        and (:server_url is null or rpa.server_url ~* :server_url)
      END_SQL

      report_values = [
        {
          name: 'REDCap Users',
          item_type: 'z-admin',
          short_name: 'redcap_users',
          description: 'Search REDCap project users across all projects.',
          report_type: 'regular_report',
          auto: false,
          searchable: false,
          options: options,
          sql: sql,
          search_attrs: search_attrs
        }
      ]

      add_report_values report_values
    end

    def self.setup
      log "In #{self}.setup"
      create_templates
      log "Ran #{self}.setup"
    end
  end
end
