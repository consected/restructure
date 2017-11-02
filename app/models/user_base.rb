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


  # This validation ensures that the user ID has been set in the master object
  # It implicitly reinforces security, in that the user must be authenticated for
  # the user to have been set
  validate :user_set

  def allows_nil_master?
    false
  end


  def creatable_without_user
    false
  end


  # Simple wrapper around #valid? that ensures certain validation methods avoid running and breaking outside of
  # the time we actually need them to run (save and create).
  def check_valid?
    self.validating = true
    res = self.valid?
    self.validating = false
    res
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

  def master_user

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

  def assoc_inverse_name
    self.class.name.ns_underscore.pluralize
  end

  # add the alternative_id_fields from the master as attributes, so we can use them for matching
  Master.alternative_id_fields.each do |f|

    define_method :"#{f}=" do |value|
      if self.attribute_names.include? f.to_s
        write_attribute(f, value)
      else
        instance_variable_set("@#{f}", value)
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


  protected

    def check_master
      if msid && !master_id
        m = Master.where(msid: msid).first
        raise "MSID set, but it does not match a master record" unless m
        self.master_id = m.id
      elsif msid && master_id
        raise "MSID and master_id set, but they do not correspond to the same record" unless self.master.msid == msid
      end

      raise "master not set in #{self}" if self.respond_to?(:master) && !(self.master_id && self.master) && !validating?
    end


    def force_write_user
      return true if creatable_without_user && !persisted? || validating?
      logger.debug "Forcing save of user in #{self}"
      return unless self.master if self.respond_to? :master
      mu = master_user
      raise "bad user (for master #{master}) being pulled from master_user (#{mu.is_a?(User) ? '' : 'not a user'}#{mu && mu.persisted? ? '': ' not persisted'})" unless mu.is_a?(User) && mu.persisted?

      write_attribute :user_id, mu.id
    end

    def user_set
      return true if (creatable_without_user && !persisted?) || validating?

      unless self.user
        errors.add :user, "must be authenticated and set"
        logger.warn "User is not set. Failed user_set validation for #{self.inspect}"
      end
      self.user
    end

    def downcase_attributes

      ignore = ['item_type']

      self.attributes.reject {|k,v| ignore.include? k}.each do |k, v|

        logger.info "Downcasing attribute (#{k})"
        self.send("#{k}=".to_sym, v.downcase) if self.attributes[k].is_a? String
      end
      true
    end

end
