module UserHandler

  extend ActiveSupport::Concern
  include GeneralDataConcerns

  included do
    attr_accessor :no_track
    # Standard associations
    Rails.logger.debug "Associating master as inverse of #{assoc_inverse}"

    after_initialize :init_vars_user_handler

    belongs_to :master, assoc_rules

    has_many :item_flags,  -> { preload(:item_flag_name) }, as: :item, inverse_of: :item



    has_many :trackers, as: :item, inverse_of: :item if self != Tracker && self != TrackerHistory


    validate :source_correct
    validate :rank_correct

    after_save :check_status
    after_save :track_record_update
  end

  class_methods do

    def uses_item_flags? user
      Classification::ItemFlagName.enabled_for? self.name.ns_underscore, user
    end

    def foreign_key_name
      @foreign_key_name = :master_id
    end

    def primary_key_name
      @primary_key_name = :id
    end

    def assoc_rules
      r = {inverse_of: assoc_inverse}
      r[:foreign_key] = self.foreign_key_name if self.foreign_key_name && self.foreign_key_name != :master_id
      r[:primary_key] = self.primary_key_name if self.primary_key_name && self.primary_key_name != :id
      r

    end

    def assoc_inverse
      # The plural model name
      self.to_s.ns_underscore.pluralize.to_sym
    end

    def ns_table_name
      assoc_inverse.to_s.singularize.to_sym
    end

    def get_rank_name value
      Classification::GeneralSelection.name_for self, value, :rank
    end
    def get_source_name value
      Classification::GeneralSelection.name_for self, value, :source
    end


    def valid_rec_types
      return nil unless self.attribute_names.include?('rec_type')
      Classification::GeneralSelection.selector_attributes([:value], item_type: "#{self.assoc_inverse}_type").map(&:first)
    end


    # A secondary key is a field that can be used to uniquely identify a record. It is not a formal key,
    # and can not be guaranteed to provide uniqueness, but for certain data situations (such as imports)
    # it may be considered to be sufficient.
    # To facilitate matching code, the method secondary_key_unique? checks this fact.
    # Returns a symbol representing the field name
    def secondary_key
      nil
    end

    # Check if a value is unique for the defined secondary_key field
    # Returns true if exactly one item is found, false if more than one item is found.
    # The option fail_if_non_existent: true (default is nil) indicates that nil should be returned
    # if the value does not already exist in the table
    # By returning nil, rather than false for non-existent values, the caller can evaluate the result
    # appropriately.
    def secondary_key_unique? value, options={}
      raise "No secondary_key field defined" unless secondary_key
      l = self.where(secondary_key => value).length
      return false if l > 1
      return true if l == 1
      # the length is 0
      # handle the result based on the option
      return (options[:fail_if_non_existent] ? nil : true)
    end

    def secondary_key_dups
      # protect against SQL injection
      raise "Bad secondary_key #{secondary_key}" unless attribute_names.include? secondary_key.to_s
      sk = secondary_key.to_s
      self.select("count(id), #{sk}").group(sk).having("count(id) > 1")
    end

    # Find the item by the secondary key value, checking that the secondary key field is set,
    # and that the result does not return multiple values.
    # It is valid that no matches are made, in which case we return nil
    def find_by_secondary_key value
      raise "No secondary_key field defined" unless secondary_key
      res = self.where(secondary_key => value)
      raise "Secondary key field '#{secondary_key}' returns multiple values for '#{value}'" if res.length > 1
      res.first
    end

  end


  public


    def belongs_directly_to
      master
    end

    def is_admin?
      if respond_to?(:master) && master
        master.is_admin?
      else
        nil
      end
    end

    # A fallback data attribute to act as the human identifier for an item
    # for quick review.
    # Most items will override this definition.
    # Even if they don't directly, but have an attribute, we'll catch it
    def data
      if defined? super
        return super()
      end
      a_list = %w(id master_id user_id admin_id rank source rec_type notes)
      (self.attributes[(self.attribute_names - a_list).first] || "").to_s
    end

  protected

    def init_vars_user_handler
      instance_var_init :was_created
      instance_var_init :updated_with
      instance_var_init :was_updated
      instance_var_init :update_action
      instance_var_init :multiple_results
    end



    def track_record_update
      # Don't do this if we have the configuration set to avoid tracking, or
      # if the record was not created or updated
      return if no_track || !(@was_updated || @was_created) || self.class.no_master_association
      @update_action = true
      Tracker.track_record_update self
    end

    def source_correct
      if respond_to?(:source) && self.source
        unless source_name
          logger.info "Requested source of #{self.source}. This is not a valid value."
          errors.add :source, "(#{self.source}) not a valid value"
          logger.warn "Source is not a valid value in #{self.inspect}"
          return false
        end
      end
      true
    end


    def rank_correct
      if respond_to?(:rank) && self.rank
        unless rank_name
          errors.add :rank, "(#{self.rank}) not a valid value"
          logger.warn "Rank is not a valid value in #{self.inspect}"
        end
        return false
      end
      true
    end
end
