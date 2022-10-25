module Seeds
  module ReportUserNotifications
    def self.do_last
      true
    end

    def self.add_values(values)
      values.each do |v|
        res = Report.find_or_initialize_by(v)
        res.update(current_admin: auto_admin) unless res.admin
      end
    end

    def self.create_templates
      options = <<~END_TEXT
        view_options:
          hide_search_button: true
          view_as: list
          hide_criteria_panel: true
          no_results_scroll: true
        column_options:
          show_as:
            generated_content: iframe
          tags:
            subject: h1
          alt_column_header:
            from_user_email: from
            created_at: at
            generated_content: ''
            subject: ''
      END_TEXT

      sql = <<~END_TEXT
        select
        distinct
        -- app.name app,
        subject,
        from_user_email,
        mn.created_at,
        -- status,

        generated_content
        --generated_content as_text


        from ml_app.message_notifications mn

        --left join ml_app.app_types app on mn.app_type_id = app.id
        where
        :current_user = ANY (recipient_user_ids)
        and nullif(generated_content, '') is not null
        order by mn.created_at desc
        limit 20
        ;
      END_TEXT

      values = [

        {
          name: 'My Notifications',
          item_type: 'user',
          short_name: 'my_notifications',
          report_type: 'regular_report',
          auto: true,
          options: options,
          sql: sql
        }

      ]

      add_values values
    end

    def self.setup
      log "In #{self}.setup"
      if !Report.find_by(short_name: 'my_notifications')
        create_templates
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end
  end
end
