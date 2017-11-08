class ExternalIdentifier < ActiveRecord::Base

  include DynamicModelHandler
  include AdminHandler

  validates :name, presence: true
  validates :label, presence: true
  validates :external_id_attribute, presence: true
  validates :min_id, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :max_id, presence: true, numericality: {greater_than_or_equal_to: 0}
  validate :name_format_correct
  validate :config_uniqueness
  validate :id_range_correct
  after_validation :implementation_table_tests



  def self.class_for field_name
    e = self.active.where(external_id_attribute: field_name).first
    return nil unless e
    return e.implementation_class
  end



  def implementation_model_name
    name.ns_underscore.singularize
  end


  def self.routes_load

    begin
      m = self.active
      return if m.length == 0

      Rails.application.routes.draw do
        resources :masters, only: [:show, :index, :new, :create] do

            m.each do |pg|
              resources pg.model_association_name, except: [:destroy]
            end
        end
      end

    rescue ActiveRecord::StatementInvalid => e
      logger.warn "Not loading activity log routes. The table has probably not been created yet. #{e.backtrace.join("\n")}"
    end


  end

  def external_id_range
    self.min_id..self.max_id
  end



  def add_master_association &association_block
    logger.debug "Add master association for #{self}"

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

        a_new_controller = Class.new(ApplicationController) do

            protected
              # By default the external id edit form is handled through a common template. To provide a customized form, copy the content of
              # "common_templates/external_id_edit_form.html.erb" to views/<name>/_edit_form.html.erb
              def edit_form
                'common_templates/external_id_edit_form'
              end

            private

              def secure_params
                res = params.require(self.class.name.singularize.to_sym).permit(:master_id, self.class.external_id_attribute.to_sym)
                # Extra protection to avoid possible injection of an alternative value
                # when we should be using a generated ID
                res[self.class.external_id_attribute.to_sym] = nil if self.class.allow_to_generate_ids
                res
              end

              def self.external_id_attribute
                @external_id_attribute
              end
              def self.name
                @name
              end

              def self.external_id_attribute=v
                @external_id_attribute = v
              end
              def self.name=v
                @name = v
              end

              def self.allow_to_generate_ids= v
                @allow_to_generate_ids = v
              end
              def self.allow_to_generate_ids
                @allow_to_generate_ids
              end

              self.allow_to_generate_ids = allow_to_generate_ids
              self.external_id_attribute = external_id_attribute
              self.name = name
        end

        m_name = model_class_name

        klass = Object
        klass.send(:remove_const, model_class_name) if implementation_class_defined?(klass)
        res = klass.const_set(model_class_name, a_new_class)
        # Do the include after naming, to ensure the correct names are used during initialization
        res.include UserHandler
        res.include ExternalIdHandler

        c_name = full_implementation_controller_name
        klass.send(:remove_const, c_name) if implementation_controller_defined?(klass)
        res2 = klass.const_set(c_name, a_new_controller)
        res2.include MasterHandler

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

  def update_tracker_events

    return unless self.label && !disabled
    Tracker.add_record_update_entries self.name.singularize, current_admin, 'record'
  end


  def implementation_table_tests
    if ActiveRecord::Base.connection.table_exists? self.name
      # Check for the actual database columns, since the class has not been created yet, and will not be until after_commit
      unless ActiveRecord::Base.connection.columns(self.name).map(&:name).include?(self.external_id_attribute.to_s)
        raise FphsException.new("external_id_attribute does not exist as an attribute (named #{self.external_id_attribute}) in the table #{self.name}")
      end

    else
      # Can't enable the configuration until the table exists
      unless self.disabled
        raise FphsException.new("name: #{name} does not exist as a table in the database. Ensure the DB table #{name} has been created. Run:
        ruby -e \"require './db/table_generators/external_identifiers_table.rb'; TableGenerators.external_identifiers_table('#{name}', '#{external_id_attribute}')\"
        to generate the SQL for this table.
         ")
      end
    end

  end

  def id_range_correct
    errors.add :max_id, "must be greater than min_id"  unless max_id > min_id
  end

  def name_format_correct
    errors.add :name, "must be a lowercase, underscored, DB table name" unless name.downcase.ns_underscore == name
  end

  def config_uniqueness
    errors.add :name, "must be unique" if !self.disabled && self.class.active.where(name: self.name.downcase).length > 0
    errors.add :external_id_attribute, "must be unique" if !self.disabled && self.class.active.where(external_id_attribute: self.external_id_attribute.downcase).length > 0
  end

  def check_implementation_class

    if !disabled
      res = implementation_class.new rescue nil
      raise FphsException.new "The implementation of #{model_class_name} was not completed. Ensure the DB table #{name} has been created. Run:
      ruby -e \"require './db/table_generators/external_identifiers_table.rb'; TableGenerators.external_identifiers_table('#{name}', '#{external_id_attribute}')\"
      to generate the SQL for this table.
       " unless res
    end
  end

end

# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
ExternalIdentifier.define_models
