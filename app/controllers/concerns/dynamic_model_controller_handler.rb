module DynamicModelControllerHandler
  extend ActiveSupport::Concern

  class_methods do
    def model_class_name
      @model_class_name = definition.model_class_name
    end
  end

  def edit_form
    'common_templates/edit_form'
  end

  def implementation_class
    return @implementation_class if @implementation_class

    cn = self.class.model_class_name
    cnf = "DynamicModel::#{cn}"
    @implementation_class = cnf.constantize
  end
end
