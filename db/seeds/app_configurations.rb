# frozen_string_literal: true

module Seeds
  module AppConfigurations
    def self.add_values(values)
      values.each do |v|
        slice = v.slice(:app_type_id, :name)
        next if Admin::AppConfiguration.active.find_by(slice)
        
        v = v.merge current_admin: auto_admin
        Admin::AppConfiguration.create!(v)
      end
    end

    def self.create_accuracy_scores
      elt = <<~END_TEXT
        category: '{{default_category}}'
        schema_name: '{{default_schema_name}}'
        extra_log_types: |
          _configurations:
            use_current_version: true
      END_TEXT
      opt = <<~END_TEXT
        category: '{{default_category}}'
        schema_name: '{{default_schema_name}}'
        options: |
          _configurations:
            use_current_version: true
      END_TEXT

      values = [
        { app_type_id: nil, name: 'default options activity log', value: elt },
        { app_type_id: nil, name: 'default options dynamic model', value: opt },
        { app_type_id: nil, name: 'default options external identifier', value: opt }
      ]

      add_values values

      Rails.logger.info "#{name} = #{Admin::AppConfiguration.all.length}"
    end

    def self.setup
      log "In #{self}.setup"
      create_accuracy_scores
      log "Ran #{self}.setup"
    end
  end
end
