# require_dependency(Rails.root.join('app', 'models', 'scantron.rb'))
# require_dependency(Rails.root.join('app', 'models', 'sage_assignment.rb'))
class ExternalIdentifier < ActiveRecord::Base

  include DynamicModelHandler
  include AdminHandler


  def self.class_for field_name
    field_name.sub(/_id$/, '').ns_camelize.ns_constantize
  end

  def self.find_by_external_id value
    self.where(external_id_attribute => value).first
  end



  def model_name
    name.ns_underscore.singularize
  end


  def self.routes_load
  end

  def external_id_range
    self.min_id..self.max_id
  end



  def add_master_association &association_block
    logger.debug "Add master association for #{self}"
    # Define the association
    Master.has_many model_association_name.to_sym,  inverse_of: :master, &association_block
    # Now update the master's nested attributes this model's symbol
    Master.add_nested_attribute model_association_name.to_sym

  end



  def generate_model

    puts "--------------------> #{self.name}  <-----------------------"

    if self.pregenerate_ids
      # Some implementations, like Sage Assignments need a special build, which handles the allocation of an existing item from the table
      # when an instance is created. Within the structure we have, it is necessary to override the master.sage_assignments.build
      # method to ensure everything works as expected
      # Pass the new build method in to make the association build work
      self.add_to_app_list do
        def build att=nil
          self.master_build_with_next_id proxy_association.owner, att
        end
      end

    else

      self.add_to_app_list

    end

  end

end

# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
ExternalIdentifier.define_models
