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
                base_route_name base_route_segments base_master_segment category].freeze

      # type: one of :dynamic_model, :external_identifier, :activity_log, :activity_log_type, :default, :data_dictionary
      # class_name: simple String respresenting the namespaced class name
      # model: the actual class implementation
      # table_name: the underlying table for persistence
      # option_type: for activity_log_type this represents the extra log type symbol
      # resource_name: a commonly formatted underscored symbol with namespace represented by double underscore (pluralized)
      # resource_item_name: an item resource name that is typically singularized resource_name, but for activity_log_type
      #                     may be pluralized to match the extra log type name
      # hyphenated_name: hyphenated names are typically used by the UI to identify component lists and panels
      #                  - for table resources this is pluralized
      #                  - for dynamic models this doesn't have the 'dynamic_model' prefix
      # hyphenated_item_name: hyphenated item name represents the UI ID of a single result
      #                       (within a hyphenated name list block) - and is typically singularized hyphenated_name,
      #                        but for activity_log_type may be pluralized to match the extra log type name
      # base_route_name: the base string for route names
      #                  For example `send("new_#{base_route_name}_path")` returns the path
      #                  to the "new" controller action
      # base_route_segments: a URI (sub) path, such as "activity_log/player_contact_phones" or "dynamic_model/projects"
      # base_master_segment: a URI (prefix) path for '/masters/' only if it is needed

      KEYS.each do |key_name|
        define_method key_name do
          self[key_name]
        end
      end
    end

    mattr_accessor :resources, :updated_at

    def self.init
      self.resources ||= {}
    end

    #
    # Provide a sorted list of all model definitions, ordered by type / human name,
    # keyed by resource_name
    # @return [Hash]
    def self.all
      resources.sort_by { |_k, r| "#{r[:type]} - #{r[:human_name]}" }.to_h
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
      base_master_segment = nil
      if !base_master_segment && model.respond_to?(:no_master_association) && !model.no_master_association
        base_master_segment = '/masters'
      end
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
                                      base_master_segment: base_master_segment,
                                      hyphenated_name: hyphenated_name&.freeze,
                                      hyphenated_item_name: hyphenated_item_name&.freeze,
                                      category: category&.freeze,
                                      option_type: option_type&.to_sym,
                                      updated_at: updated_at
      self.updated_at = Time.now
      resources[resource_name]
    end

    #
    # Safely resolve a class-name-like string to the registered model class.
    #
    # This is an allow-list alternative to String#constantize / ns_constantize for
    # any code path that takes a model identifier from user-influenced input
    # (params, URL segments, background-job arguments, admin configuration, etc.).
    #
    # Only classes that have been registered in this registry (via Resources::Models.add)
    # can be resolved. Any input that does not match a registered entry returns nil,
    # eliminating the constantize-as-RCE / arbitrary-autoload attack surface.
    #
    # Accepted input forms (all map to the same registry entry):
    # - resource_name symbol/string  e.g. "dynamic_model__contact_infos" / :masters
    # - resource_item_name           e.g. "dynamic_model__contact_info"  / :master
    # - fully qualified class name   e.g. "DynamicModel::ContactInfo"
    # - ns_camelized slash form      e.g. "DynamicModel/ContactInfo"
    #
    # @param name [String, Symbol, nil]
    # @return [Class, nil] the registered model class, or nil if no match
    def self.find_model(name)
      return nil if name.nil?

      s = name.to_s
      return nil if s.empty?

      # Class-name form (with :: or /): match by class_name directly.
      if s.include?('::') || s.include?('/')
        class_name = s.tr('/', ':').gsub(/:+/, '::')
        match = resources.values.find { |r| r[:class_name] == class_name }
        return match[:model] if match
        return nil
      end

      # Camel-cased single segment e.g. "Master" - match by class_name.
      if s =~ /\A[A-Z]/
        match = resources.values.find { |r| r[:class_name] == s }
        return match[:model] if match
        return nil
      end

      # Snake-cased forms: resource_name (plural) or resource_item_name (singular).
      sym = s.to_sym
      entry = resources[sym]
      return entry[:model] if entry

      match = resources.values.find { |r| r[:resource_item_name] == sym }
      return match[:model] if match

      nil
    end

    #
    # Same as .find_model but raises FphsException when the name does not resolve
    # to a registered model. Use this at boundaries where an unknown identifier
    # indicates a bad request or programming error rather than expected absence.
    #
    # @param name [String, Symbol, nil]
    # @return [Class]
    def self.find_model!(name)
      model = find_model(name)
      return model if model

      raise FphsException, "#{name.inspect} is not a recognized model resource name"
    end

    #
    # Remove a resource from the cached set
    def self.remove(resource_name:)
      self.updated_at = Time.now
      resources.delete(resource_name.to_sym)
    end

    init
  end
end
