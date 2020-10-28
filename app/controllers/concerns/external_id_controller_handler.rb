module ExternalIdControllerHandler

  extend ActiveSupport::Concern


  class_methods do

    def external_id_attribute
      @external_id_attribute = definition.external_id_attribute
    end

    def name
      @name = definition.name
    end

    def allow_to_generate_ids
      @allow_to_generate_ids = definition.pregenerate_ids
    end

  end

  def implementation_class
    cnf = controller_name.singularize.classify
    @implementation_class = cnf.constantize
  end

end
