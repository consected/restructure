# frozen_string_literal: true

module OptionConfigs
  class PageLayoutOptions < BaseOptions
    def self.raise_bad_configs(option_configs)
      return unless option_configs.contains

      resources = option_configs.contains.resources
      return unless resources.present?

      al_types = %i[activity_log activity_log_type]
      al_count = resources.count do |r|
        item = Resources::Models.find_by(resource_name: r)
        item && al_types.include?(item[:type])
      end

      return if al_count.zero?
      return if al_count == 1 && resources.length == 1

      if al_count > 1
        raise FphsException, 'Panel contains multiple activity-log resources. ' \
                             'Activity-log resources must be in a single-resource panel.'
      else
        raise FphsException, 'Panel mixes activity-log resources with other resource types. ' \
                             'Activity-log resources must be in a single-resource panel.'
      end
    end
  end
end
