module Seeds
  module ActivityLogTableName

    def self.setup
      log "In #{self}.setup"


      ActivityLog.active.each do |al|
        if al.attribute_names.include?('table_name') && al.table_name.blank?
          al.table_name = al.generate_table_name
          al.current_admin = al.admin
          al.save!

          raise FphsException.new "Failed to set table name in migration" if al.table_name.blank?
        end
      end

    end

  end
end
