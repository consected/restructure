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
      else
        nil
      end
    end

    def force_write_user
      return true if creatable_without_user && !persisted?

      raise "bad user being pulled from master_user" unless master_user.is_a?(User) && master_user.persisted?

      write_attribute :user_id, master_user.id
    end

end
