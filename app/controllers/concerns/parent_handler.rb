module ParentHandler
  extend ActiveSupport::Concern

  def item_class_name
    item_controller.singularize.ns_camelize
  end

  def item_class
    item_class_name.ns_constantize
  end

  def parent_item_instance
    item_class.find(params[:item_id])
  end

end
