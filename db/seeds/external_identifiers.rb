# frozen_string_literal: true

module Seeds
  module ExternalIdentifiers
    def self.add_values(values)
      updated = false
      values.each do |v|
        res = ExternalIdentifier.find_by(name: v['name'])
        next if res

        v[:current_admin] = auto_admin
        res = ExternalIdentifier.new(v)

        updated = res.save!
      end
      updated
    end

    def self.create_external_identifiers
      values = [
        { 'name' => 'scantrons', 'label' => 'Scantron ID', 'external_id_attribute' => 'scantron_id', 'external_id_view_formatter' => '', 'external_id_edit_pattern' => '\\d{0,6}', 'prevent_edit' => false, 'pregenerate_ids' => false, 'min_id' => 1, 'max_id' => 999_999, 'disabled' => nil },
        { 'name' => 'sage_assignments', 'label' => 'Sage ID', 'external_id_attribute' => 'sage_id', 'external_id_view_formatter' => 'format_sage_id', 'external_id_edit_pattern' => nil, 'prevent_edit' => true, 'pregenerate_ids' => true, 'min_id' => 1_000_000_000, 'max_id' => 9_999_999_999, 'disabled' => nil }
      ]

      updated = add_values values

      Rails.logger.info "#{name} = #{ExternalIdentifier.all.length}"
    end

    def self.setup
      log "In #{self}.setup"
      if Rails.env.test? || ExternalIdentifier.active.count < 2
        create_external_identifiers
        log "Ran #{self}.setup"
      else
        log "Did not run #{self}.setup"
      end

      if Rails.env.test?

        sa = ExternalIdentifier.active.find_by(name: 'scantrons')
        unless sa
          s = ExternalIdentifier.find_by(name: 'scantrons')
          raise 'Scantron not found' unless s

          s.update!(current_admin: auto_admin, disabled: false) if s.disabled?
        end
        # ::ExternalIdentifier.refresh_outdated unless defined? Scantron
        raise "Scantron not defined: #{sa}\n#{s}" unless defined? Scantron

        sa = ExternalIdentifier.active.find_by(name: 'sage_assignments')
        unless sa
          s = ExternalIdentifier.find_by(name: 'sage_assignments')
          raise 'SageAssignment not found' unless s

          s.update!(current_admin: auto_admin, disabled: false) if s.disabled?
        end
        # ::ExternalIdentifier.refresh_outdated unless defined? SageAssignment
        raise "SageAssignment not defined: #{sa}\n#{s}" unless defined? SageAssignment

        Master.reset_external_id_matching_fields!

        Admin::AppType.active.each do |app_type|
          Admin::UserAccessControl.create(user: nil, app_type: app_type, resource_type: 'table', resource_name: 'scantrons', access: :create, current_admin: auto_admin)
          Admin::UserAccessControl.create(user: nil, app_type: app_type, resource_type: 'table', resource_name: 'sage_assignments', access: :create, current_admin: auto_admin)
        end
      end
    end
  end
end
