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

  def allows_nil_master?
    false
  end


  def creatable_without_user
    false
  end

  def can_edit?
    self.allows_current_user_access_to? :edit
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

  def allows_current_user_access_to? perform, with_options=nil
    raise FphsException.new "no master_user in allows_current_user_access_to?" unless master_user

    res = self.class.allows_user_access_to? master_user, perform, with_options=nil
    return false unless res

    if respond_to?(:master) && master
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
    !!user.has_access_to?( perform, :table, named, with_options)
  end

  def referenced_from
    ModelReference.find_where_referenced_from self
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

  protected

    def check_master
      msid = nil if msid.blank? && !msid.nil?
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

      ignore = /(item_type)?(notes)?(description)?(.+_notes)?/

      self.attributes.reject {|k,v| k && k.match(ignore)[0].present?}.each do |k, v|

        logger.info "Downcasing attribute (#{k})"
        self.send("#{k}=".to_sym, v.downcase) if self.attributes[k].is_a? String
      end
      true
    end

    def check_can_save

      raise FphsException.new "This item is not editable (#{self.class.name})" if persisted? && !can_edit?
      raise FphsException.new "This item can not be created (#{self.class.name})" if !persisted? && !can_create?
      true

    end

end
