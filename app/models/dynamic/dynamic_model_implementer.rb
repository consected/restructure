# frozen_string_literal: true

module Dynamic
  module DynamicModelImplementer
    extend ActiveSupport::Concern

    class_methods do
      #
      # The secondary_key to use for lookups of records using #find_by_secondary_key
      # @return [String] field name
      def secondary_key
        definition.secondary_key
      end

      def final_setup
        Rails.logger.debug "Running final setup for #{name}"
        ro = result_order
        return unless primary_key.present?

        use_key = primary_key || attribute_names.first

        ro = { use_key => :desc } if result_order.blank?
        default_scope -> { order ro }
      end

      # Scope method to filter results based on whether they can be viewed according to user access controls
      # and default option config showable_if rules
      # @return [ActiveRecord::Relation] scope to provide rules filtered according to the calculated rules
      def filter_results
        return all unless primary_key == 'id'

        sall = all
        return unless sall

        ex_ids = []
        sall.each do |r|
          ex_ids << r.id unless r.can_access?
        end

        if ex_ids.empty?
          sall
        else
          where("#{table_name}.id not in (?)", ex_ids)
        end
      end

      def is_dynamic_model
        true
      end

      # TODO: check if this is always overridden by UserHandler
      def assoc_inverse
        @assoc_inverse = definition.model_association_name
      end

      # Override the primary_key definition for a model, to ensure
      # views and tables without primary keys can load
      def primary_key
        primary_key_name&.to_s
      end

      def result_order
        return @result_order if @result_order

        @result_order = definition.result_order || ''
      end

      def no_master_association
        foreign_key_name.blank?
      end

      # At this time dynamic models only use one config definition, under the 'default' key
      # Simplify access to the default options configuration
      def default_options
        @default_options = definition.default_options
      end

      def human_name
        @human_name = definition.name
      end

      def find(id)
        find_by(primary_key => id)
      end

      def permitted_params
        field_list = definition.field_list
        if field_list.blank?
          attribute_names.map(&:to_sym) - %i[user_id created_at updated_at
                                             tracker_id] + [:item_id]
        else
          definition.field_list_array.map(&:to_sym)
        end
      end
    end

    def model_data_type
      :dynamic_model
    end

    # The dynamic model option type is always 'default' unless it
    # is set in the _configurations.option_type_attr_name
    def option_type
      option_type_attr_name = self.class.option_type_attr_name
      send(option_type_attr_name) || 'default' unless option_type_attr_name == :option_type
    end

    def option_type=(value)
      option_type_attr_name = self.class.option_type_attr_name
      return unless option_type_attr_name

      send("#{option_type_attr_name}=", value)
    end

    def id
      attributes[self.class.primary_key.to_s]
    end

    def table_key
      table_key_name = self.class.definition.table_key_name
      attributes[table_key_name] if table_key_name.present?
    end

    def can_edit?
      return @can_edit unless @can_edit.nil?

      @can_edit = false

      # This returns nil if there was no rule, true or false otherwise.
      # Therefore, for no rule (nil) return whatever the user access controls allow,
      # since they are final arbiter.
      res = calc_can :edit
      return @can_edit = !!super() if res.nil?
      return unless res

      # Finally continue with the standard checks if none of the previous have failed
      @can_edit = !!super()
    end

    def can_access?
      return @can_access unless @can_access.nil?

      @can_access = false

      # This returns nil if there was no rule, true or false otherwise.
      # Therefore, for no rule (nil) return true
      res = calc_can :access
      return @can_access = true if res.nil?
      return unless res

      # Finally continue with the standard checks if none of the previous have failed
      @can_access = !!super()
    end
  end
end
