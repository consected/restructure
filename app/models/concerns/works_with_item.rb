module WorksWithItem

  extend ActiveSupport::Concern

  included do
    belongs_to :user
    validates :user, presence: true
    validates :item, presence: true
    validate :works_with_class

    default_scope -> {where "disabled is null or disabled = false"}

  end

  class_methods do
    def works_with class_name
      # Get the value from the array and return it, so we can return a value that is not the original passed in (failing Brakeman test otherwise)
      pos = use_with_class_names.index(class_name.underscore)
      if pos
        use_with_class_names[pos.to_i].camelize
      else
        nil
      end
    end

    def use_with_class_names
      Master.reflect_on_all_associations(:has_many).select {|v| v.options[:source] != :item_flags}.collect {|v| v.plural_name.singularize}.sort
    end

  end

  def method_id
    self.item.master_id
  end

  def item_type_us
    self.item_type.underscore
  end

  def works_with_class
    self.class.use_with_class_names.include? item_type
  end
    
end
