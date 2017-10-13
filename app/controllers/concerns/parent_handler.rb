module ParentHandler
  extend ActiveSupport::Concern

  def item_class_name
    item_controller.singularize.ns_camelize
  end

  def item_class
    item_class_name.ns_constantize
  end

end
