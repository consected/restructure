class ExternalIdentifier < ActiveRecord::Base

  include DynamicModelHandler
  include AdminHandler


  def self.class_for field_name
    field_name.sub(/_id$/, '').ns_camelize.ns_constantize
  end



  def implementation_model_name
    name.ns_underscore.singularize
  end


  def self.routes_load
  end

  def external_id_range
    self.min_id..self.max_id
  end



  def add_master_association &association_block
    logger.debug "Add master association for #{self}"
    puts "---------------------------> Add master association for #{self} #{model_association_name}"
    # Define the association

    if self.pregenerate_ids
      # Some implementations, like Sage Assignments need a special build, which handles the allocation of an existing item from the table
      # when an instance is created. Within the structure we have, it is necessary to override the master.sage_assignments.build
      # method to ensure everything works as expected
      # Pass the new build method in to make the association build work

      Master.has_many model_association_name.to_sym,  inverse_of: :master do
        def build att=nil
          self.master_build_with_next_id proxy_association.owner, att
        end
      end
    else
      Master.has_many model_association_name.to_sym,  inverse_of: :master
    end
    # Now update the master's nested attributes this model's symbol
    Master.add_nested_attribute model_association_name.to_sym

  end



  def generate_model

    failed = false

    logger.info "Generating ExternalIdentifier model #{name}"
    puts  "*****************Generating ExternalIdentifier model #{name}"
    external_id_attribute = self.external_id_attribute
    external_id_edit_pattern = self.external_id_edit_pattern
    external_id_view_formatter = self.external_id_view_formatter
    external_id_range = self.external_id_range
    allow_to_generate_ids = self.pregenerate_ids
    prevent_edit = self.prevent_edit
    label = self.label
    name = self.name

    if enabled? && !failed

      begin


        # Main implementation class
        a_new_class = Class.new(UserBase) do

          self.table_name = name

          def self.external_id_attribute=v
            @external_id_attribute = v
          end

          def self.external_id_edit_pattern= v
            @external_id_edit_pattern = v
          end

          def self.external_id_range= v
            @external_id_range = v
          end

          def self.allow_to_generate_ids= v
            @allow_to_generate_ids = v
          end

          def self.prevent_edit= v
            @prevent_edit = v
          end

          def self.external_id_view_formatter= v
            @external_id_view_formatter = v
          end

          def self.label= v
            @label = v
          end

          self.external_id_attribute = external_id_attribute
          self.external_id_edit_pattern = external_id_edit_pattern
          self.external_id_range = external_id_range
          self.allow_to_generate_ids = allow_to_generate_ids
          self.prevent_edit = prevent_edit
          self.external_id_view_formatter = external_id_view_formatter
          self.label = label

        end

        # a_new_controller = Class.new(ActivityLog::ActivityLogsController) do
        #
        # end

        m_name = model_class_name

        klass = ExternalIdentifier
        res = Object.const_set(model_class_name, a_new_class)
        # Do the include after naming, to ensure the correct names are used during initialization
        res.include UserHandler
        res.include ExternalIdHandler

        c_name = "#{model_class_name.pluralize}Controller"
        # res2 = klass.const_set(c_name, a_new_controller)

    #    logger.debug "Model Name: #{m_name} + Controller #{c_name}. Def:\n#{res}\n#{res2}"

        add_model_to_list res
      rescue=>e
        failed = true
        logger.info "Failure creating an external identifier model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
        puts "Failure creating an external identifier model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
      end
    end
    if failed || !enabled?
      remove_model_from_list
    end

    res
  end


end

# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
ExternalIdentifier.define_models
