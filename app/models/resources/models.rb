# frozen_string_literal: true

module Resources
  #
  # Provide a mechanism to centrally track all useful models for user applications.
  # This provides a centrally cached set of models, including dynamic definitions
  # that can looked up by common identifiers such as resource name and table name.
  # The aim is to provide a consistent mechanism to connect identifiers used in code
  # and dynamic definitions to the underlying models and paths used to access them.
  class Models
    def self.init
      @@resources ||= {}
    end

    #
    # Provide a sorted list of all model definitions, ordered by type / human name,
    # keyed by resource_name
    # @return [Hash]
    def self.all
      @@resources.sort_by { |_k, r| "#{r[:type]} - #{r[:human_name]}" }.to_h || {}
    end

    #
    # Find a single model by one of the possible model keys
    # @return [Hash]
    def self.find_by(key_val)
      @@resources ||= {}

      key = key_val.keys.first.to_sym
      val = key_val.first.last

      if key == :resource_name
        @@resources[val.to_sym]
      else
        res = @@resources.filter { |_k, v| v[key] == val }
        return unless res&.first

        res.first.last
      end
    end

    #
    # Add a model to the cached set for future retrieval
    # Most of the definition values will be based on the model
    # The *type* will be calculated to provide a mechanism for
    # categorizing the models.
    def self.add(model)
      @@resources ||= {}

      resource_name = model.resource_name.to_sym
      type = if model.respond_to? :definition
               model.definition.class.name.underscore.to_sym
             elsif model.respond_to? :resource_category
               model.resource_category
             else
               :default
             end

      @@resources[resource_name] = {
        type: type,
        class_name: model.name,
        model: model,
        table_name: model.table_name,
        resource_name: resource_name
      }

      if model.respond_to? :base_route_name
        @@resources[resource_name].merge! base_route_name: model.base_route_name,
                                          base_route_segments: model.base_route_segments

      end
      @@resources[resource_name]
    end

    #
    # Remove a resource from the cached set
    def self.remove(resource_name:)
      @@resources ||= {}
      @@resources.delete(resource_name.to_sym)
    end
  end
end
