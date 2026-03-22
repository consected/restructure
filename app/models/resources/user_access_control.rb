# frozen_string_literal: true

module Resources
  #
  # Handle the resource name descriptions for user access controls
  class UserAccessControl
    include ConfigurationDefs

    def self.resource_descriptions_for(resource_type)
      case resource_type
      when :table
        resource_descriptions_for_table
      when :general
        resource_descriptions_for_general
      when :limited_access
        resource_descriptions_for_limited_access
      when :external_id_assignments
        resource_descriptions_for_limited_access
      when :report
        resource_descriptions_for_report
      when :standalone_page
        resource_descriptions_for_standalone_page
      when :activity_log_type
        resource_descriptions_for_activity_log_type
      else
        []
      end
    end

    #
    # List of resource name for the specified resource type
    # @param [String] resource_type
    # @return [Array{String}]
    def self.resource_names_for(resource_type)
      keys_from_grouped_config(Resources::UserAccessControl.resource_descriptions_for(resource_type)).map(&:to_s)
    end

    def self.resource_descriptions_for_table
      res = {
        'Common Master Tables':
          {
            Settings::DefaultSubjectInfoTableName => 'Participant info (names, biographical)',
            Settings::DefaultSecondaryInfoTableName => 'Participant secondary info (associated indentifiable info)',
            Settings::DefaultContactInfoTableName => 'Participant contact info (email / phone)',
            Settings::DefaultAddressInfoTableName => 'Participant addresses',
            'datadic_variables' => 'Data Dictionary variables',
            'trackers': 'Latest tracker entry per protocol',
            'tracker_histories': 'All tracker entries',
            'latest_tracker_history': 'Most recent tracker entry',
            'item_flags': 'Item Flags core table',
            'user_preferences': 'User preferences'
          }
      }

      categorize_resources ActivityLog, 'activity log', res
      categorize_resources DynamicModel, 'dynamic model', res

      res.merge!("external identifiers": ExternalIdentifier.active.map { |r| [r.resource_name, r.label] }.to_h)

      res.merge!("item flags": ItemFlag.active_resource_names.map { |r| [r, 'Item Flags for table'] }.to_h)

      res.merge!('Filestore Tables': {
                   'nfs_store__manage__containers': 'All Filestore containers',
                   'nfs_store__manage__stored_files': 'All Filestore stored files',
                   'nfs_store__manage__archived_files': 'All Filestore files extracted from archives'
                 })

      res
    end

    def self.resource_descriptions_for_general
      configuration_defs_for :uac_general_resource_names
    end

    def self.resource_descriptions_for_limited_access
      res = {}

      categorize_resources DynamicModel, 'dynamic model', res

      res.merge!(
        'external identifiers': ExternalIdentifier.active.map { |r| [r.resource_name, r.label] }.to_h,
        'general': {
          'master_created_by_user': 'Created by User',
          'temporary_master': 'Temporary Master Record'
        }
      )

      res
    end

    def self.resource_descriptions_for_report
      res = {
        'All': { '_all_reports_': 'All Reports' }
      }

      rs = Report.active.reorder('').order(item_type: :asc)
      categories = rs.map(&:item_type).uniq
      categories.each do |cat|
        res.merge!(
          "report: #{cat&.present? && cat || '(no category)'}":
            rs.select { |r| r.item_type == cat }.map { |r| [r.alt_resource_name, r.name] }.to_h
        )
      end

      res
    end

    def self.resource_descriptions_for_standalone_page
      res = {
        'All': { '_all_standalone_pages_': 'All Standalone Pages' }
      }

      rs = Admin::PageLayout.active.standalone.reorder('').order(app_type_id: :asc, panel_name: :asc)
      rs.each do |r|
        res[r.app_type.label] ||= {}
        res[r.app_type.label][r.panel_name] = r.panel_label
      end

      res
    end

    def self.resource_descriptions_for_activity_log_type
      ActivityLog.reset_all_option_configs_resource_names!
      ActivityLog.reset_active_model_configurations!
      ActivityLog.all_option_configs_grouped_resources
    end

    #
    # Categorize resources, taking care to treat both '' and nil categories as a single category
    # @param [Class] klass - type of resources to categorize
    # @param [String] label - label to form key prefix
    # @param [Hash] into_hash - the hash to merge into
    def self.categorize_resources(klass, label, into_hash)
      recs = klass.active.reorder('').order(category: :asc)
      categories = recs.map(&:category).uniq
      categories.delete_if { |cat| cat == '' }
      categories.each do |cat|
        into_hash.merge!(
          "#{label}: #{cat&.present? ? cat : '(no category)'}":
            recs.select { |rec| (rec.category || '') == (cat || '') }.map { |r| [r.resource_name, r.name] }.to_h
        )
      end
    end
  end
end
