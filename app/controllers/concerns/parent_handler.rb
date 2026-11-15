module ParentHandler
  extend ActiveSupport::Concern

  def item_class_name
    item_controller.singularize.ns_camelize
  end

  # Resolve the parent item's model class through the Resources::Models registry.
  # This is an allow-list lookup: only registered model classes can be returned, so
  # user-influenced input (params[:item_controller]) cannot trigger arbitrary
  # constant autoloading via String#constantize.
  # Returns nil if the name does not match a registered model.
  def item_class
    Resources::Models.find_model(item_class_name)
  end

  def parent_item_instance
    klass = item_class
    raise FphsException, "Invalid item class: #{item_class_name}" unless klass

    klass.find(params[:item_id])
  end

end
