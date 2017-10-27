module UserHandler

  extend ActiveSupport::Concern
  include GeneralDataConcerns

  included do
    attr_accessor :no_track
    # Standard associations
    Rails.logger.debug "Associating master as inverse of #{assoc_inverse}"

    after_initialize :init_vars_user_handler

    belongs_to :master, assoc_rules
    belongs_to :user

    has_many :item_flags, as: :item, inverse_of: :item
    has_many :activity_logs, as: :item, inverse_of: :item
    has_many :trackers, as: :item, inverse_of: :item if self != Tracker && self != TrackerHistory

    # Generate the set of activity log associations, for each record type for this item type
    ActivityLog.active.where(item_type: self.name.ns_underscore).each do |al|
      has_many al.model_assocation_name.to_sym, class_name: al.activity_log_class_name
    end

    before_validation :check_master

    # Ensure the user id is saved
    before_validation :force_write_user

    before_validation :downcase_attributes

    validates :master_id, presence: true
    # This validation ensures that the user ID has been set in the master object
    # It implicitly reinforces security, in that the user must be authenticated for
    # the user to have been set
    validate :user_set

    validate :source_correct
    validate :rank_correct

    after_save :check_status
    after_save :track_record_update
  end

  class_methods do

    def uses_item_flags?
      ItemFlagName.enabled_for? self.name.ns_underscore
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

    def get_rank_name value
      GeneralSelection.name_for self, value, :rank
    end
    def get_source_name value
      GeneralSelection.name_for self, value, :source
    end

    def human_name
      name.underscore.humanize.titleize
    end

    def valid_rec_types
      return nil unless self.attribute_names.include?('rec_type')
      GeneralSelection.selector_attributes([:value], item_type: "#{self.assoc_inverse}_type").map(&:first)
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
    # The option fail_if_non_existent: true (default is nil) indicates that false should be returned
    # if the value does not already exist in the table
    def secondary_key_unique? value, options={}
      raise "No secondary_key field defined" unless secondary_key
      l = self.where(secondary_key => value).length
      return false if l > 1
      return true if l == 1
      # the length is 0
      # handle the result based on the option
      return !options[:fail_if_non_existent]
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

  def master_user

    if respond_to?(:master) && master
      current_user = master.current_user
      current_user
    else
      nil
    end
  end

  # Returns the full model name, namespaced like 'module__class' (double underscore) if there is a namespace.
  # otherwise it returns just the basic name
  def item_type
    self.class.name.singularize.ns_underscore
  end

  # Returns the full model name pluralized, namespaced like 'module/class' if there is a namespace.
  # otherwise it returns just the basic name
  # works great for generating routes
  def item_type_path
    self.class.name.pluralize.underscore
  end
  
  def validating= v
    @validating = v
  end

  def validating?
    @validating
  end

  protected

    def init_vars_user_handler
      instance_var_init :was_created
      instance_var_init :updated_with
      instance_var_init :was_updated
      instance_var_init :update_action
      instance_var_init :multiple_results
    end

    def creatable_without_user
      false
    end

    def downcase_attributes

      ignore = ['item_type']

      self.attributes.reject {|k,v| ignore.include? k}.each do |k, v|

        logger.info "Downcasing attribute (#{k})"
        self.send("#{k}=".to_sym, v.downcase) if self.attributes[k].is_a? String
      end
      true
    end

    def user_set
      return true if creatable_without_user && !persisted?

      unless self.user
        errors.add :user, "must be authenticated and set"
        logger.warn "User is not set. Failed user_set validation in user_handler for #{self.inspect}"
      end
      self.user
    end

    def check_master
      raise "master not set in #{self}" unless !!(self.master_id && self.master)
    end

    def force_write_user
      return true if creatable_without_user && !persisted? || validating?
      logger.debug "Forcing save of user in #{self}"
      return unless self.master
      mu = master_user
      raise "bad user (for master #{master}) being pulled from master_user (#{mu.is_a?(User) ? '' : 'not a user'}#{mu && mu.persisted? ? '': ' not persisted'})" unless mu.is_a?(User) && mu.persisted?

      write_attribute :user_id, mu.id
    end

    def track_record_update
      return if no_track
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
