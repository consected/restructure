# frozen_string_literal: true

module Resources
  #
  # Provide a mechanism to centrally track all useful models for user applications.
  # This provides a centrally cached set of models, including dynamic definitions
  # that can looked up by common identifiers such as resource name and table name.
  # The aim is to provide a consistent mechanism to connect identifiers used in code
  # and dynamic definitions to the underlying models and paths used to access them.
  class Models
    class Item < Hash
      KEYS = %i[type class_name model table_name option_type
                resource_name resource_item_name
                hyphenated_name hyphenated_item_name
                base_route_name base_route_segments category].freeze

      # type: one of :dynamic_model, :external_identifier, :activity_log, :activity_log_type, :default, :data_dictionary
      # class_name: simple String respresenting the namespaced class name
      # model: the actual class implementation
      # table_name: the underlying table for persistence
      # option_type: for activity_log_type this represents the extra log type symbol
      # resource_name: a commonly formatted underscored symbol with namespace represented by double underscore (pluralized)
      # resource_item_name: an item resource name that is typically singularized resource_name, but for activity_log_type
      #                     may be pluralized to match the extra log type name
      # hyphenated_name: hyphenated names are typically used by the UI to identify component lists and panels
      #                  for table resources this is pluralized
      # hyphenated_item_name: hyphenated item name represents the UI ID of a single result
      #                       (within a hyphenated name list block) - and is typically singularized hyphenated_name,
      #                        but for activity_log_type may be pluralized to match the extra log type name
      # base_route_name: the base string for route names
      #                  For example `send("new_#{base_route_name}_path")` returns the path
      #                  to the "new" controller action
      # base_route_segments: a URI (sub) path, such as "activity_log/player_contact_phones" or "dynamic_model/projects"

      KEYS.each do |key_name|
        define_method key_name do
          self[key_name]
        end
      end
    end

    mattr_accessor :resources

    def self.init
      self.resources ||= {}
    end

    #
    # Provide a sorted list of all model definitions, ordered by type / human name,
    # keyed by resource_name
    # @return [Hash]
    def self.all
      resources.sort_by { |_k, r| "#{r[:type]} - #{r[:human_name]}" }.to_h || {}
    end

    def self.to_a
      resources.values
    end

    #
    # Find a single model by one of the possible model keys
    # @return [Hash]
    def self.find_by(key_val)
      key = key_val.keys.first.to_sym
      val = key_val.first.last

      if key == :resource_name
        resources[val.to_sym]
      else
        res = resources.filter { |_k, v| v[key] == val }
        return unless res&.first

        res.first.last
      end
    end

    #
    # Add a model to the cached set for future retrieval
    # Most of the definition values will be based on the model
    # The *type* will be calculated to provide a mechanism for
    # categorizing the models, or can provided explicitly
    def self.add(model,
                 resource_name: nil, resource_item_name: nil, type: nil,
                 base_route_name: nil, base_route_segments: nil,
                 hyphenated_name: nil, hyphenated_item_name: nil, category: nil,
                 option_type: nil)
      resource_name ||= model.resource_name
      resource_name = resource_name.to_sym
      type ||= if model.respond_to? :definition
                 model.definition.class.name.underscore.to_sym
               elsif model.respond_to? :resource_category
                 model.resource_category
               else
                 :default
               end

      resource_item_name = model.resource_item_name if !resource_item_name && model.respond_to?(:resource_item_name)
      resource_item_name ||= resource_name

      hyphenated_name = model.hyphenated_name if !hyphenated_name && model.respond_to?(:hyphenated_name)
      if !hyphenated_item_name && model.respond_to?(:hyphenated_item_name)
        hyphenated_item_name = model.hyphenated_item_name
      end
      base_route_name = model.base_route_name if !base_route_name && model.respond_to?(:base_route_name)
      base_route_segments = model.base_route_segments if !base_route_segments && model.respond_to?(:base_route_segments)
      category = model.category if !category && model.respond_to?(:category)

      updated_at = model.definition.updated_at if model.respond_to? :definition

      resources[resource_name] = Item.new
      resources[resource_name].merge! type: type.to_sym,
                                      class_name: model.name.freeze,
                                      model: model,
                                      table_name: model.table_name.freeze,
                                      resource_name: resource_name.to_sym,
                                      resource_item_name: resource_item_name.to_sym,
                                      base_route_name: base_route_name&.freeze,
                                      base_route_segments: base_route_segments&.freeze,
                                      hyphenated_name: hyphenated_name&.freeze,
                                      hyphenated_item_name: hyphenated_item_name&.freeze,
                                      category: category&.freeze,
                                      option_type: option_type&.to_sym,
                                      updated_at: updated_at
      resources[resource_name]
    end

    #
    # Remove a resource from the cached set
    def self.remove(resource_name:)
      resources.delete(resource_name.to_sym)
    end

    init
  end
end
