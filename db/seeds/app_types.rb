module Seeds
  module AppTypes
    def self.do_last
      true
    end

    def self.add_values(values)
      values.each do |v|
        res = Admin::AppType.find_by_name(v['name'])
        if res
          res.update(current_admin: auto_admin) unless res.admin
        else
          v[:current_admin] = auto_admin
          Admin::AppType.create!(v)
        end
      end
    end

    def self.create_app_types
      values = [
        { 'name' => 'zeus', 'label' => 'Zeus', 'disabled' => nil, 'default_schema_name' => 'ml_app' }
      ]

      add_values values

      Rails.logger.info "#{name} = #{Classification::AccuracyScore.all.length}"
    end

    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || Admin::AppType.count == 0
        create_app_types
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end
  end
end
