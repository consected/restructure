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
            'trackers': 'Latest tracker entry per protocol',
            'tracker_histories': 'All tracker entries',
            'latest_tracker_history': 'Most recent tracker entry',
            'item_flags': 'Item Flags core table'
          }
      }

      categories = ActivityLog.active.select(:category).distinct.reorder('').pluck(:category)
      categories.each do |cat|
        res.merge!(
          "activity log: #{cat || '(no category)'}":
            ActivityLog.active.where(category: cat).map { |r| [r.resource_name, r.name] }.to_h
        )
      end

      categories = DynamicModel.active.select(:category).distinct.reorder('').pluck(:category)
      categories.each do |cat|
        res.merge!(
          "dynamic model: #{cat || '(no category)'}":
            DynamicModel.active.where(category: cat).map { |r| [r.resource_name, r.name] }.to_h
        )
      end

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
      categories = DynamicModel.active.select(:category).distinct.reorder('').pluck(:category)
      categories.each do |cat|
        res.merge!(
          "dynamic model: #{cat || '(no category)'}":
            DynamicModel.active.where(category: cat).map { |r| [r.resource_name, r.name] }.to_h
        )
      end

      res.merge!(
        "external identifiers": ExternalIdentifier.active.map { |r| [r.resource_name, r.label] }.to_h
      )

      res
    end

    def self.resource_descriptions_for_report
      res = {
        'All': { '_all_reports_': 'All Reports' }
      }

      categories = Report.active.select(:item_type).distinct.reorder('').pluck(:item_type)
      categories.each do |cat|
        res.merge!(
          "report: #{cat || '(no category)'}":
            Report.active.map { |r| [r.alt_resource_name, r.name] }.to_h
        )
      end
      res
    end

    def self.resource_descriptions_for_activity_log_type
      ActivityLog.all_option_configs_grouped_resources
    end
  end
end
