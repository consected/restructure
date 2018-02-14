module Seeds
  module AppTypes

    def self.do_last
      true
    end

    def self.add_values values
      values.each do |v|
        res = AppType.find_or_initialize_by(v)
        res.update(current_admin: auto_admin) unless res.admin
      end

    end

    def self.create_app_types


      values = [
        {"name"=>"zeus", "label"=>"Zeus", "disabled"=>nil}
      ]

      add_values values

      Rails.logger.info "#{self.name} = #{AccuracyScore.all.length}"
    end


    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || AppType.count == 0
        create_app_types
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end
  end
end
