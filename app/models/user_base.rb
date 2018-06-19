# Common abstract class for all user authenticated models to subclass.
# Follows the sensible Rails 5 convention, allow us to incorporate common, essential methods into
# all user models. Previously we had duplication across similar but different model concerns. This allows
# us to pull the essentials in one time only
class UserBase < ActiveRecord::Base

  self.abstract_class = true

  belongs_to :user


  # If this model should be associated with a master, check it
  before_validation :check_master, unless: :allows_nil_master?

  # Ensure the user id is saved
  before_validation :force_write_user

  before_validation :downcase_attributes

  before_save :check_can_save

  # This validation ensures that the user ID has been set in the master object
  # It implicitly reinforces security, in that the user must be authenticated for
  # the user to have been set
  validate :user_set
  validate :configurable_valid_if
  validate :valid_embedded_item

  after_save :create_referring_record

  attr_accessor :ignore_configurable_valid_if


  def self.all_subclasses
    # Subsclasses may be subclassed further - go to the next level if needed.
    UserBase.subclasses.map {|s| s.subclasses ? s.subclasses : s }.flatten
  end

  def self.class_from_name class_name
     all_subclasses.select {|s| s.name == class_name}.first
  end

  def self.is_external_identifier?
    false
  end

  def allows_nil_master?
    false
  end


  def creatable_without_user
    false
  end

  def self.no_master_association
    false
  end

  def can_edit?
    self.allows_current_user_access_to? :edit
  end

  def prevent_edit
    !can_edit?
  end

  def can_create?
    self.allows_current_user_access_to? :create
  end

  def can_access?
    self.allows_current_user_access_to? :access
  end

  # Simple wrapper around #valid? that ensures certain validation methods avoid running and breaking outside of
  # the time we actually need them to run (save and create).
  def check_valid?
    self.validating = true

    begin
      res = !marked_invalid? && self.valid?
    rescue => e
      self.errors.add "unexpected error", e.message
      res = false
    end
    self.validating = false
    res
  end

  def marked_invalid?
    @marked_invalid
  end

  def mark_invalid= val
    @marked_invalid = val
  end

  def validating?
    @validating
  end

  def validating= v
    @validating = v
  end

  def validating?
    @validating
  end

  # Provide a modified human name for an instance
  def human_name

    if respond_to?(:rec_type) && self.rec_type
      rec_type.underscore.humanize.titleize
    else
      self.class.human_name
    end
  end

  def self.human_name
    cn = self.name

    if self.respond_to?(:is_dynamic_model) && self.is_dynamic_model || self.respond_to?(:is_activity_log) && self.is_activity_log
      cn = cn.split('::').last
    end

    cn.underscore.humanize.titleize
  end

  def option_type
  end

  def option_type_config
  end

  def creatables
  end

  def save_action
  end

  def master_user
    return current_user if self.class.no_master_association
    if respond_to?(:master) && master
      current_user = master.current_user
      current_user
    elsif respond_to?(:item) && item.respond_to?(:master) && item.master
      current_user = item.master.current_user
      current_user
    else
      raise "master is nil and can't be used to get the current user" unless validating?
      nil
    end
  end

  # Returns the full model name, namespaced like 'module__class' if there is a namespace.
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

  def item_type_us
    self.item_type.ns_underscore
  end


  def allows_current_user_access_to? perform, with_options=nil
    raise FphsException.new "no master_user in allows_current_user_access_to?" unless master_user

    res = self.class.allows_user_access_to? master_user, perform, with_options=nil
    return false unless res

    if self.class.no_master_association
      # Since there is no master association, there is no master to block the access
      return true
    elsif respond_to?(:master) && master
      m = master
    elsif respond_to?(:item) && item.respond_to?(:master) && item.master
      m = item.master
    end

    !!m.allows_user_access

  end

  def self.allows_user_access_to? user, perform, with_options=nil
    raise FphsException.new "no user in allows_user_access_to?" unless user

    # Check at a table level that the user can access the resource
    named = self.name.ns_underscore.pluralize
    !!user.has_access_to?(perform, :table, named, with_options)
  end

  def referenced_from
    ModelReference.find_where_referenced_from self
  end

  def self.permitted_params
    self.attribute_names.map{|a| a.to_sym} - [:disabled, :user_id, :created_at, :updated_at, :tracker_id, :admin_id]
  end


  def embedded_item
    @embedded_item
  end

  def embedded_item= o
    if o.is_a? UserBase
      @embedded_item = o
    elsif o.is_a?(Hash) && @embedded_item
      @embedded_item.master.current_user ||= self.master_user
      @embedded_item.update o
      self.updated_at = @embedded_item.updated_at
    end
  end

  # Used as an indicator in certain models to show that this is part of a master record creation
  def creating_master=cm
    @creating_master = cm
  end

  def creating_master
    @creating_master
  end

  if Master.respond_to? :alternative_id_fields
    # add the alternative_id_fields from the master as attributes, so we can use them for matching
    Master.alternative_id_fields.each do |f|

      define_method :"#{f}=" do |value|
        if self.attribute_names.include? f.to_s
          write_attribute(f, value)
        else
          instance_variable_set("@#{f}", value)
          if self.master
            return self.master
          end
          self.master = Master.find_with_alternative_id(f, value)
        end
      end

      define_method :"#{f}" do
        if self.attribute_names.include? f.to_s
          read_attribute(f)
        else
          instance_variable_get("@#{f}")
        end
      end

    end
  else
    puts "Master does not respond to alternative_id_fields. Hopefully this is just during seeding"
  end

  def self.default_options

  end

  def set_referring_record ref_record_type, ref_record_id
    @ref_record_type = ref_record_type
    @ref_record_id = ref_record_id
  end


  def create_referring_record
    if @ref_record_type
      ref_item_class_name = @ref_record_type.singularize.camelize

      # Find the matching UserBase subclass that has this name, avoiding using the supplied param
      # in a way that could be risky by allowing code injection
      ic = UserBase.class_from_name ref_item_class_name

      # look up the item using the item_id parameter.
      @referring_record  = ic.find(@ref_record_id.to_i)

      if @referring_record
        ModelReference.create_with @referring_record, self
      end
    end
  end



  protected

    def check_master

      return if self.class.no_master_association

      msid = nil if msid.blank? && !msid.nil?
      if msid && !master_id
        m = Master.where(msid: msid).first
        raise "MSID set, but it does not match a master record" unless m
        self.master_id = m.id
      elsif msid && master_id
        raise "MSID and master_id set, but they do not correspond to the same record" unless self.master.msid == msid
      end

      raise FphsException.new "master not set in #{self} #{self.id}" if self.respond_to?(:master) && !(self.master_id && self.master) && !validating?
    end

    def no_user_validation
      (creatable_without_user && !persisted?) || validating? || self.class.no_master_association
    end


    def force_write_user
      return true if no_user_validation
      logger.debug "Forcing save of user in #{self}"
      return unless self.master if self.respond_to? :master
      mu = master_user
      raise "bad user (for master #{master}) being pulled from master_user (#{mu.is_a?(User) ? '' : 'not a user'}#{mu && mu.persisted? ? '': ' not persisted'})" unless mu.is_a?(User) && mu.persisted?

      write_attribute :user_id, mu.id
    end

    def user_set
      return true if no_user_validation

      unless self.user
        errors.add :user, "must be authenticated and set"
        logger.warn "User is not set. Failed user_set validation for #{self.inspect}"
      end
      self.user
    end

    def downcase_attributes

      ignore = /(item_type)?(notes)?(description)?(.+_notes)?(.+_description)?/

      self.attributes.reject {|k,v| k && k.match(ignore)[0].present?}.each do |k, v|

        logger.info "Downcasing attribute (#{k})"
        self.send("#{k}=".to_sym, v.downcase) if self.attributes[k].is_a? String
      end
      true
    end

    def check_can_save

      raise FphsException.new "This item is not editable (#{self.class.name}) #{self.id}" if persisted? && !can_edit?
      raise FphsException.new "This item can not be created (#{self.class.name})" if !persisted? && !can_create?
      true

    end

    def configurable_valid_if

      return true if @ignore_configurable_valid_if || !option_type_config.respond_to?(:valid_if)

      vi = option_type_config.valid_if
      return true if vi.empty?

      action_name = persisted? ? :update : :create
      return_failures = {}
      res = option_type_config.calc_valid_if action_name, self, return_failures: return_failures

      unless res
        if return_failures.empty?
          errors.add :field_validation, "failed. Check your entries and try again"
        else
          return_failures.each do |c_var, c_vals|

            c_vals.each do |table, cond|
              cond.each do |k, v|
                v = v.present? ? v : '(blank)'
                if v.is_a? Hash
                  v = "#{v.first.first.to_s.humanize.downcase}: #{v.first.last}"
                else
                  v = ": #{v}"
                end
                k = table == :this ? k : "#{table}.#{k}"
                if c_var == :all
                  errors.add k.to_sym, "is invalid. Expected value to be #{v}"
                elsif c_var == :any
                  errors.add k.to_sym, "is one of several possible fields that is invalid - one must match. Expected value #{v}"
                elsif c_var == :not_any
                  errors.add k.to_sym, "is invalid. Expected value not to be #{v}"
                elsif c_var == :not_all
                  errors.add k.to_sym, "is one of several possible fields that is invalid - none must match. Expected value not #{v}"
                end
              end
            end
          end
        end
        return
      else
        true
      end

    end

    def valid_embedded_item

      if embedded_item && !embedded_item.errors.empty?
        embedded_item.errors.each do |k, v|
          errors.add k, v
        end
      end
    end

end
