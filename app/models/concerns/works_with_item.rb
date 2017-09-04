module WorksWithItem

  extend ActiveSupport::Concern

  included do
    belongs_to :user
    # Ensure the user id is saved
    before_validation :force_write_user

    validates :user, presence: true

    validate :works_with
    default_scope -> {where "disabled is null or disabled = false"}

  end

  class_methods do
    

  end

  def creatable_without_user
    false
  end

  def method_id
    self.item.master_id
  end

  def item_type_us
    self.item_type.underscore
  end

  # used for validation to check this activity log type works with the parent item
  def works_with
    self.class.use_with_class_names.include? item_type
  end

  def item_type
    self.class.name.singularize.underscore
  end

  

  protected

    def master_user

      if respond_to?(:master) && master        
        current_user = master.current_user
        current_user
      elsif item.respond_to?(:master) && item.master
        current_user = item.master.current_user
        current_user
      else
        raise "master is nil and can't be used to get the current user" unless master || item.master
        nil
      end
    end

    def force_write_user
      return true if creatable_without_user && !persisted?
      mu = master_user
      raise "bad user being pulled from master_user (#{mu.is_a?(User) ? '' : 'not a user'}#{mu && mu.persisted? ? '': ' not persisted'})" unless mu.is_a?(User) && mu.persisted?

      write_attribute :user_id, mu.id
    end

end
