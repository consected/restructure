module ExternalIdHandler

  extend ActiveSupport::Concern
  
  included do
    
    attr_accessor :create_count, :just_assigned
    
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
    
    def external_id_view_formatter= val
      @id_formatter = val
    end
    
    def external_id_range= val
      @external_id_range = val
    end
    
    def external_id_edit_pattern= val
      @external_id_pattern = val
    end
    
    def label= val
      @label
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

    def external_id_view_formatter
      @id_formatter || ''
    end

    def external_id_range
      @external_id_range || (1..9999999999)
    end
    
    def external_id_edit_pattern
      @external_id_pattern || '\\d{0,10}'
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
  
    # Optionally accept an association_block, allowing the association related methods such as #build to be overridden
    # in the master record association. Just passes this through to the add_master_assocation 
    def add_to_app_list &association_block
      
      self.validates external_id_attribute, presence: true,  numericality: { only_integer: true, greater_than_or_equal_to: external_id_range.min, less_than_or_equal_to: external_id_range.max }
      
      Application.add_to_app_list(:external_id, self)
      add_master_association &association_block
    end
    
    def add_master_association &association_block
      #puts "Calling: Master.has_many #{plural_name.to_sym},  inverse_of: :master. Association block defined? #{!!association_block}"
      
      # Define the association
      Master.has_many plural_name.to_sym,  inverse_of: :master, &association_block 
      # Now update the master's nested attributes this model's symbol
      Master.add_nested_attribute plural_name.to_sym
      
    end
    
    
    
    # For external ID models that require an auto-generated or auto-assigned (from an existing list) ID,
    # the master association build method will use this method.
    # By default, the next available ID will be generated randomly. 
    def master_build_with_random_id owner, att=nil
      if att
        self.assign_random_id owner
      else
        self.new master: owner
      end
    end
    
    # We assign the random id 
    def assign_random_id master
      item = self.new master: master      
      item[external_id_attribute] = self.generate_random_id      
      item.just_assigned = true
      item
    end

    # Generate a random number with no leading zeros or spaces in the defined external_id_range
    def generate_random_id  
      m = external_id_range.max
      add = (m+1)/10
      upper = m - add      
      SecureRandom.random_number(upper) + add      
    end

    # SageAssignments for example expand on the master_build_with_random_id method
    # in order to pluck the next available pre-generated ID from a list.
    def master_build_with_next_id owner, att=nil
      if att
        self.assign_next_available_id owner
      else
        self.new master: owner
      end
    end    
    def assign_next_available_id master

      item = self.next_available master      
      item.just_assigned = true
      item.master = master
      item

    end
        
    
  end
end

