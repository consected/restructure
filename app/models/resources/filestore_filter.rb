# frozen_string_literal: true

module Resources
  #
  # Handle the resource name descriptions for user access controls
  class FilestoreFilter
    include ConfigurationDefs

    #
    # Key value hash of resource names => descriptions that
    # Filestore filters can be applied to.
    # This selects only activity logs with an 'nfs_store__manage__container' reference,
    # any resources listed as Settings::FilestoreAdminResourceNames
    # plus a default "Filestore Container" extry
    # @return [Hash{String => String}]
    def self.resource_descriptions
      res = ActivityLog
            .all_option_configs_grouped_resources { |e| e&.references && e.references[:nfs_store__manage__container] }

      res = key_vals_from_grouped_config(res)

      res.merge!(Settings::FilestoreAdminResourceNames.map { |r| [r.pluralize, r.humanize] }.to_h)

      res.merge!(
        NfsStore::Manage::Container.resource_name => 'Filestore Container'
      )

      res
    end
  end
end
