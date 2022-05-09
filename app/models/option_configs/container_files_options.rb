# frozen_string_literal: true

module OptionConfigs
  # Container Files options represent dynamic definitions for Filestore files, allowing them to act
  # like dynamic models according to options defined for each container
  class ContainerFilesOptions < ExtraOptions
    def self.add_key_attributes
      %i[resource_type]
    end

    attr_accessor(*key_attributes)

    def initialize(name, config, container_file)
      super(name, config, container_file)

      if @config_obj.disabled
        Rails.logger.info "configuration for this container file has not been enabled: #{@config_obj.table_name}"
        return
      end
      raise FphsException, 'container file options name: property can not be blank' if self.name.blank?

      self.resource_type = container_file.resource_name
    end
  end
end
