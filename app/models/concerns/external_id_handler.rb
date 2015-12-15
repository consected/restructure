module ExternalIdHandler

  extend ActiveSupport::Concern
  
  included do
    
    
    add_master_association
  end
  
  class_methods do
    
    def prevent_edit= val
      @prevent_edit = val
    end
    def prevent_create= val
      @prevent_create = val
    end
    
    def external_id_attribute= val
      @external_id_attribute = val
    end
    
    def id_formatter= val
      @id_formatter = val
    end
    
    def prevent_edit?
      return @prevent_edit unless @prevent_edit.nil?
      false
    end
    def prevent_create?
      return @prevent_create unless @prevent_create.nil?
      false
    end
    
    def external_id_attribute
      @external_id_attribute || :external_id
    end

    def id_formatter
      @id_formatter || ''
    end

    def plural_name
      name.underscore.pluralize
    end
    
    def hyphenated_plural_name
      name.underscore.pluralize.hyphenate
    end
    def label
      @label || self.name.underscore.humanize.titleize
    end
  
    
    def add_to_app_list
      Application.add_to_app_list(:external_id, self)
    end
    
    def add_master_association
      logger.info "Calling: Master.has_many #{plural_name.to_sym},  inverse_of: :master"
      
      Master.has_many plural_name.to_sym,  inverse_of: :master unless plural_name == 'sage_assignments'
      
      Master.add_nested_attribute  plural_name.to_sym
      

    end
  end
end

