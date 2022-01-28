# frozen_string_literal: true

module UserHandler
  extend ActiveSupport::Concern
  include GeneralDataConcerns

  included do
    attr_accessor :no_track

    scope :active, lambda {
      if attribute_names.include?('disabled')
        where Arel.sql('disabled is null or disabled = false')
      else
        self
      end
    }
    scope :disabled, lambda {
      if attribute_names.include?('disabled')
        where disabled: true
      else
        self
      end
    }

    after_initialize :init_vars_user_handler

    # Ensure dynamic models without master as the foreign key and filestore files don't break associations
    unless defined?(no_master_association) && no_master_association
      # Standard associations
      Rails.logger.debug "Associating master as inverse of #{assoc_inverse}"
      belongs_to :master, assoc_rules
      has_many :trackers, as: :item, inverse_of: :item if self != Tracker && self != TrackerHistory
    end

    belongs_to :created_by_user, class_name: 'User', optional: true if attribute_names.include? 'created_by_user_id'

    has_many :item_flags, -> { preload(:item_flag_name) }, as: :item, inverse_of: :item

    validate :source_correct
    validate :rank_correct

    after_save :set_previous_action_flags
    after_save :track_record_update
  end

  class_methods do
    def uses_item_flags?(user)
      Classification::ItemFlagName.enabled_for? name.ns_underscore, user
    end

    def foreign_key_name
      @foreign_key_name = :master_id
    end

    def primary_key_name
      @primary_key_name = :id
    end

    def assoc_rules
      r = { inverse_of: assoc_inverse }
      r[:foreign_key] = foreign_key_name if foreign_key_name && foreign_key_name != :master_id
      r[:primary_key] = primary_key_name if primary_key_name && primary_key_name != :id
      r[:optional] = true if defined?(no_master_association) && no_master_association

      r
    end

    def assoc_inverse
      # The plural model name
      to_s.ns_underscore.pluralize.to_sym
    end

    def ns_table_name
      assoc_inverse.to_s.singularize.to_sym
    end

    def get_rank_name(value)
      Classification::GeneralSelection.name_for self, value, :rank
    end

    def get_source_name(value)
      Classification::GeneralSelection.name_for self, value, :source
    end

    def valid_rec_types
      return nil unless attribute_names.include?('rec_type')

      Classification::GeneralSelection.selector_attributes([:value], item_type: "#{assoc_inverse}_type").map(&:first)
    end

    # A secondary key is a field that can be used to uniquely identify a record. It is not a formal key,
    # and can not be guaranteed to provide uniqueness, but for certain data situations
    # (such as imports and page layout lookups on a 'slug') it may be considered to be sufficient.
    # To facilitate matching code, the method secondary_key_unique? checks this fact.
    # Overriding methods will return a symbol representing the field name
    # @return [Symbol | nil]
    def secondary_key
      nil
    end

    # Check if a value is unique for the defined secondary_key field
    # Returns true if exactly one item is found, false if more than one item is found.
    # By returning nil, rather than false for non-existent values, the caller can evaluate the result
    # appropriately.
    # @param [Object] value represents the secondary_key value to check
    # @param [Boolean | nil] fail_if_not_existent (default is nil) if true, indicates that nil should be returned
    #   if the value does not already exist in the table
    def secondary_key_unique?(value, fail_if_non_existent: nil)
      raise 'No secondary_key field defined' unless secondary_key

      l = where(secondary_key => value).length
      return false if l > 1
      return true if l == 1

      # the length is 0
      # handle the result based on the option
      (fail_if_non_existent ? nil : true)
    end

    def secondary_key_dups
      # protect against SQL injection
      raise "Bad secondary_key #{secondary_key}" unless attribute_names.include? secondary_key.to_s

      sk = secondary_key.to_s
      self.select("count(id), #{sk}").group(sk).having('count(id) > 1')
    end

    # Find the item by the secondary key value, checking that the secondary key field is set,
    # and that the result does not return multiple values.
    # It is valid that no matches are made, in which case we return nil
    def find_by_secondary_key(value)
      raise 'No secondary_key field defined' unless secondary_key

      res = where(secondary_key => value)
      raise "Secondary key field '#{secondary_key}' returns multiple values for '#{value}'" if res.length > 1

      res.first
    end

    # Find all items by the secondary key value, checking that the secondary key field is set
    # A ActiveRecord scope is returned that may have a count of 0, 1 or many
    def find_all_by_secondary_key(value)
      raise 'No secondary_key field defined' unless secondary_key

      where(secondary_key => value)
    end
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

  def belongs_directly_to
    master unless self.class.no_master_association
  end

  #
  # Check if the associated master has a current admin set for administrative tasks
  # @return [Boolean]
  def current_admin?
    master.current_admin? if respond_to?(:master) && master
  end

  # A fallback data attribute to act as the human identifier for an item
  # for quick review.
  # Most items will override this definition.
  # Even if they don't directly, but have an attribute, we'll catch it
  # @return [String]
  def data
    return super() if defined? super

    a_list = %w[id master_id user_id admin_id rank source rec_type notes]
    (attributes[(attribute_names - a_list).first] || '').to_s
  end

  protected

  def init_vars_user_handler
    instance_var_init :was_created
    instance_var_init :updated_with
    instance_var_init :was_updated
    instance_var_init :update_action
    instance_var_init :multiple_results
  end

  #
  # After a record has been saved, make a tracker entry for it
  # This only happens if the record was created or updated,
  # is not marked `no_track` and it has a master association.
  # @return [Boolean | nil] representing success or failure
  def track_record_update
    # Don't do this if we have the configuration set to avoid tracking, or
    # if the record was not created or updated
    return if no_track || !(@was_updated || @was_created) || self.class.no_master_association

    @update_action = true
    Tracker.track_record_update self
  end

  def source_correct
    if respond_to?(:source) && source && !source_name
      logger.info "Requested source of #{source}. This is not a valid value."
      errors.add :source, "(#{source}) not a valid value"
      logger.warn "Source is not a valid value in #{inspect}"
      return false
    end
    true
  end

  def rank_correct
    if respond_to?(:rank) && rank
      unless rank_name
        errors.add :rank, "(#{rank}) not a valid value"
        logger.warn "Rank is not a valid value in #{inspect}"
      end
      return false
    end
    true
  end

  #
  # Previous action flags allow easy identification of the action that has just been completed
  # was_created, was_updated or was_disabled
  def set_previous_action_flags
    @was_created = respond_to?(:id) && saved_change_to_id? ? 'created' : false

    # If an embedded_item is present and it was updated, allow that to set @was_updated.
    # Just changing the updated_at attribute on self (with #touch) is not registered as a change.
    @was_updated = if respond_to?(:updated_at) &&
                      (saved_change_to_updated_at? || embedded_item&.saved_change_to_updated_at?)
                     'updated'
                   else
                     false
                   end

    @was_disabled = respond_to?(:disabled) && saved_change_to_disabled? && disabled ? 'disabled' : false
  end
end
