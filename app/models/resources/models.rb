# frozen_string_literal: true

module Resources
  class Models
    def self.init
      @@resources ||= {}
    end

    def self.all
      @@resources.sort_by { |_k, r| "#{r[:type]} - #{r[:human_name]}" }.to_h || {}
    end

    def self.find_by(resource_name:)
      @@resources ||= {}

      @@resources[resource_name.to_sym]
    end

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
    end

    def self.remove(resource_name:)
      @@resources ||= {}
      @@resources.delete(resource_name.to_sym)
    end
  end
end
