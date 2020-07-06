# frozen_string_literal: true

module DynamicModelHandler
  extend ActiveSupport::Concern

  class_methods do
    def final_setup
      Rails.logger.debug "Running final setup for #{name}"
      ro = result_order
      ro = { id: :desc } if result_order.blank?
      default_scope -> { order ro }
    end

    # Scope method to filter results based on whether they can be viewed according to user access controls
    # and default option config showable_if rules
    # @return [ActiveRecord::Relation] scope to provide rules filtered according to the calculated rules
    def filter_results
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

    def assoc_inverse
      @assoc_inverse = definition.model_association_name
    end

    def foreign_key_name
      @foreign_key_name = definition.foreign_key_name.blank? ? nil : definition.foreign_key_name.to_sym
    end

    def primary_key_name
      @primary_key_name = definition.primary_key_name.to_sym
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
      !foreign_key_name
    end

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
      field_list = if field_list.blank?
                     attribute_names.map(&:to_sym) - %i[disabled user_id created_at updated_at tracker_id] + [:item_id]
                   else
                     definition.field_list_array.map(&:to_sym)
                   end

      field_list
    end
  end

  def model_data_type
    :dynamic_model
  end

  def option_type
    'default'
  end

  # resource_name used by user access controls
  def resource_name
    self.class.definition.resource_name
  end

  def option_type_config
    self.class.default_options
  end

  def master_id
    return nil if self.class.no_master_association

    master&.id
  end

  def current_user
    if self.class.no_master_association
      @current_user
    else
      master.current_user
    end
  end

  def current_user=(cu)
    if self.class.no_master_association
      @current_user = cu
    else
      master.current_user = cu
    end
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
    # Therefore, for no rule (nil) return true
    res = calc_can :edit
    return @can_edit = true if res.nil?
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

  # Calculate the can rules for the required type, based on user access controls and showable_if rules
  # @param type [Symbol] either :access or :edit for showable_if or editable_if
  def calc_can(type)
    # either use the editable_if configuration if there is one
    dopt = definition_default_options

    if type == :edit
      doptif = dopt.editable_if
    elsif type == :access
      doptif = dopt.showable_if
    end

    if doptif.is_a?(Hash) && doptif.first
      # Generate an old version of the object prior to changes
      old_obj = dup
      changes.each do |k, v|
        old_obj.send("#{k}=", v.first) if k.to_s != 'user_id'
      end

      # Ensure the duplicate old_obj references the real master, ensuring current user can
      # be referenced correctly in conditional calculations
      old_obj.master = master

      if type == :edit
        res = !!dopt.calc_editable_if(old_obj)
      elsif type == :access
        res = !!dopt.calc_showable_if(old_obj)
      end
    end

    res
  end

  # Force the ability to add references even if can_edit? for the parent record returns false
  def can_add_reference?
    return @can_add_reference unless @can_add_reference.nil?

    @can_add_reference = false
    dopt = definition_default_options
    return unless dopt.add_reference_if.is_a?(Hash) && dopt.add_reference_if.first

    res = dopt.calc_add_reference_if(self)
    @can_add_reference = !!res
  end
end
