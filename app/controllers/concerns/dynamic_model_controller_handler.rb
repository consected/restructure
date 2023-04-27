module DynamicModelControllerHandler

  extend ActiveSupport::Concern


  class_methods do


    def model_class_name
      @model_class_name = definition.model_class_name
    end

    # Annoyingly this needs to be forced, since const_set in generate_model does not
    # appear to set the parent class correctly, unlike for models
    # Possibly this is a Rails specific override, but the parent is set correctly
    # when a controller is created as a file in a namespaced folder, so rather
    # than fighting it, just force the known parent here.
  end

  def edit_form
    'common_templates/edit_form'
  end

  def implementation_class
    cn = self.class.model_class_name
    cnf = "DynamicModel::#{cn}"
    cnf.constantize
  end



end
