module Seeds
  module ExternalIdentifiers

    def self.add_values values
      updated = false
      values.each do |v|
        res = ExternalIdentifier.find_or_initialize_by(v)
        unless res.admin
          res.update(current_admin: auto_admin)
          updated = true
        end
      end
      return updated
    end

    def self.create_external_identifiers


      values = [
        {"name"=>"scantrons", "label"=>'Scantron ID', "external_id_attribute"=>"scantron_id", "external_id_view_formatter"=>"", "external_id_edit_pattern" => '\\d{0,6}', "prevent_edit"=> false, "pregenerate_ids"=>false, "min_id"=>1, "max_id"=>999999, "disabled"=>nil},
        {"name"=>"sage_assignments", "label"=>'Sage ID', "external_id_attribute"=>"sage_id", "external_id_view_formatter"=>"format_sage_id", "external_id_edit_pattern" => nil,"prevent_edit"=>true, "pregenerate_ids"=>true, "min_id"=>1000000000, "max_id"=>9999999999, "disabled"=>nil}
      ]

      updated = add_values values

      Rails.logger.info "#{self.name} = #{ExternalIdentifier.all.length}"
    end


    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || ExternalIdentifier.count == 0
        create_external_identifiers
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end
    end
  end
end
