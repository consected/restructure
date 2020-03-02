class ExternalIdentifier < ActiveRecord::Base

  include DynamicModelDefHandler
  include AdminHandler

  DefaultRange = (1..9999999999)

  validates :name, presence: {scope: :active}
  validates :label, presence: {scope: :active}
  validates :external_id_attribute, presence: {scope: :active}
  validates :min_id, presence: true, numericality: {greater_than_or_equal_to: 0}, unless: :alphanumeric?
  validates :max_id, presence: true, numericality: {greater_than_or_equal_to: 0}, unless: :alphanumeric?
  validate :name_format_correct
  validate :config_uniqueness
  validate :id_range_correct
  after_validation :implementation_table_tests
  after_save :generate_usage_reports

  def self.implementation_prefix
    ""
  end



  def self.class_for field_name
    e = self.active.where(external_id_attribute: field_name).first
    return nil unless e
    return e.implementation_class
  end

  def resource_name
    name
  end

  def table_name
    name
  end

  def implementation_model_name
    name.ns_underscore.singularize
  end

  # List of item types that can be used to define Classification::GeneralSelection drop downs
  # This does not represent the actual item types that are valid for selection when defining a new external identifier model record
  def self.item_types

    list = []

    implementation_classes.each do |c|

      cn = c.attribute_names.select{|a| a.start_with?('select_') || a.end_with?('_selection') || a.in?(%w(source rec_type rank)) }.map{|a| a.to_sym} - [:disabled, :user_id, :created_at, :updated_at]
      cn.each do |a|
        list << "#{c.name.ns_underscore.pluralize}_#{a}".to_sym
      end
    end

    list
  end

  # the list of defined activity log implementation classes
  def self.implementation_classes
    @implementation_classes = active_model_configurations.map{|a| "#{a.model_class_name.classify}".constantize }
  end


  def self.routes_load

    mn = nil
    begin
      m = active_model_configurations
      return if m.length == 0
      Rails.application.routes.draw do
        resources :masters, only: [:show, :index, :new, :create] do

            m.each do |pg|
              mn = pg
              Rails.logger.info "Setting up routes for #{mn}"
              resources pg.model_association_name, except: [:destroy]
            end
        end
      end

    rescue ActiveRecord::StatementInvalid => e
      logger.warn "Not loading activity log routes. The table #{mn} has probably not been created yet. #{e.backtrace.join("\n")}"
    end


  end

  def external_id_range
    if self.min_id && self.max_id
      self.min_id..self.max_id
    else
      DefaultRange
    end
  end

  def usage_report rep_type
    Report.active.where(name: usage_report_name(rep_type)).first
  end

  def usage_report_name rep_type
    "#{self.name.humanize.titleize} #{rep_type}"
  end



  def add_master_association &association_block
    logger.debug "Add master association for #{self}"

    return if disabled
    remove_assoc_class('Master')

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

        def create att={}
          obj = self.master_build_with_next_id proxy_association.owner, att
          obj.save
          obj
        end

        def create! att={}
          obj = self.master_build_with_next_id proxy_association.owner, att
          obj.save!
          obj
        end
      end
    else
      Master.has_many model_association_name.to_sym,  inverse_of: :master
    end
    # Now update the master's nested attributes this model's symbol
    Master.add_nested_attribute model_association_name.to_sym

    Master.add_alternative_id_method external_id_attribute

  end



  def generate_model

    logger.info "---------------------------------------------------------------------------
************** GENERATING ExternalIdentifier MODEL #{self.name} ****************
---------------------------------------------------------------------------"

    klass = Object
    failed = false
    @regenerate = nil


    if enabled? && !failed
      begin

        definition = self

        if prevent_regenerate_model
          logger.info "Already defined class #{model_class_name}."
          # Refresh the definition in the implementation class
          implementation_class.definition = definition
          return
        end

        # Main implementation class
        a_new_class = Class.new(UserBase) do

          def self.definition= d
            @definition = d
            # Force the table_name, since it doesn't include external_identifer_ as a prefix, which is the Rails convention for namespaced models
            self.table_name = d.name
          end

          def self.definition
            @definition
          end

          self.definition = definition

          # allow views to be used, where a primary key index is not defined, but the
          # integer id field is guaranteed to be unique in the source table.
          self.primary_key = :id

        end

        a_new_controller = Class.new(ExternalIdentifier::ExternalIdentifierController) do

          def self.definition= d
            @definition = d
          end

          def self.definition
            @definition
          end

          self.definition = definition

        end

        begin
          # This may fail if an underlying dependent class (parent class) has been redefined by
          # another dynamic implementation, such as external identifier
          klass.send(:remove_const, model_class_name) if implementation_class_defined?(klass, fail_without_exception: true, fail_without_exception_newable_result: true)
        rescue => e
          logger.info "*************************************************************************************"
          logger.info "Failed to remove the old definition of #{model_class_name}. #{e.inspect}"
          logger.info "*************************************************************************************"
        end

        res = klass.const_set(model_class_name, a_new_class)
        # Do the include after naming, to ensure the correct names are used during initialization
        res.include UserHandler
        res.include ExternalIdHandler
        res.include LimitedAccessControl


        # Setup the controller
        c_name = full_implementation_controller_name
        begin
          klass.send(:remove_const, c_name) if implementation_controller_defined?(klass)
        rescue => e
          logger.info "*************************************************************************************"
          logger.info "Failed to remove the old definition of #{c_name}. #{e.inspect}"
          logger.info "*************************************************************************************"
        end

        res2 = klass.const_set(c_name, a_new_controller)
        res2.include ExternalIdControllerHandler

        add_model_to_list res
      rescue=>e
        failed = true
        logger.info "Failure creating an external identifier model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
        puts "Failure creating an external identifier model definition. #{e.inspect}\n#{e.backtrace.join("\n")}"
      end
    end
    if failed || !enabled?
      remove_model_from_list
      reset_master_fields
    end

    reset_master_fields if res

    @regenerate = res
  end

  def update_tracker_events

    return unless self.label && !disabled
    Tracker.add_record_update_entries self.name.singularize, current_admin, 'record'
    # flag items are added when item flag names are added to the list
    #Tracker.add_record_update_entries self.name.singularize, current_admin, 'flag'
  end

  def reset_master_fields
    Master.reset_external_id_matching_fields!
  end


  def implementation_table_tests

    if self.name.blank? || self.external_id_attribute.blank?
      return
    end
    if ActiveRecord::Base.connection.table_exists? self.name
      # Check for the actual database columns, since the class has not been created yet, and will not be until after_commit
      unless ActiveRecord::Base.connection.columns(self.name).map(&:name).include?(self.external_id_attribute.to_s)
        raise FphsException.new("external_id_attribute does not exist as an attribute (named #{self.external_id_attribute}) in the table #{self.name}")
      end

    else
      # Can't enable the configuration until the table exists
      unless self.disabled || !self.errors.empty?
        raise FphsException.new("name: #{name} does not exist as a table in the database. Ensure the DB table #{name} has been created. Run:
        \`db/table_generators/generate.sh external_identifiers_table create #{name} #{external_id_attribute}\`
        to generate the SQL for this table.
        IMPORTANT: to save this configuration, check the Disabled checkbox and re-submit.
         ")
      end
    end

  end

  def id_range_correct
    return if max_id.nil? || min_id.nil?
    errors.add(:max_id, "must be greater than min id")  unless max_id.nil? || max_id && max_id > min_id
  end

  def name_format_correct
    errors.add :name, "must not be #{name}" if name.downcase == 'externals' || name.downcase == 'exts'
    errors.add :name, "must be a lowercase, underscored, DB table name" unless name.downcase.ns_underscore == name
    errors.add :name, "not acceptable - must be plural and avoid numbers after underscores in names" unless name.to_sym == model_association_name
    # Unfortunately we have clash in the existing scantrons naming. Ignore this case and work around as necessary.
    errors.add :external_id_attribute, "must not be named #{external_id_attribute} or external_id. Consider using the name '#{name.singularize}_ext_id'" if ("#{name.singularize}_id" == external_id_attribute || external_id_attribute == 'external_id') && name.downcase != 'scantrons'
    errors.add :external_id_attribute, "must end in '_id'. Consider using the name '#{name.singularize}_ext_id'" unless external_id_attribute.end_with? 'id'
  end

  def config_uniqueness
    res =  self.class.active.where(name: self.name.downcase).where.not(id: self.id)
    errors.add :name, "must be unique" if !self.disabled && res.length > 0
    res = self.class.active.where(external_id_attribute: self.external_id_attribute.downcase).where.not(id: self.id)
    errors.add :external_id_attribute, "must be unique" if !self.disabled && res.length > 0
  end

  def check_implementation_class

    if !disabled && errors.empty?
      res = implementation_class.new rescue nil
      raise FphsException.new "The implementation of #{model_class_name} was not completed. Ensure the DB table #{name} has been created. Run:
      \`db/table_generators/generate.sh external_identifiers_table create #{name} #{external_id_attribute}\`
      to generate the SQL for this table.
      IMPORTANT: to save this configuration, check the Disabled checkbox and re-submit.
       " unless res
    end
  end

  def generate_usage_reports
    if !disabled && errors.empty?
      r = usage_report('Assigned')
      unless r
        Report.create! name: usage_report_name('Assigned'),
                    item_type: "External ID Usage",
                    report_type: 'regular_report',
                    auto: false,
                    searchable: false,
                    current_admin: self.admin,
                    position: 100,
                    sql: "select id, #{self.external_id_attribute}, master_id, user_id from #{self.name} where master_id is not null"
      end

      r = usage_report('Search')
      unless r
        Report.create! name: usage_report_name('Search'),
                    item_type: "External ID Search",
                    report_type: 'search',
                    auto: false,
                    searchable: true,
                    current_admin: self.admin,
                    position: 100,
                    sql: "select * from #{self.name} where #{self.external_id_attribute} = :#{self.external_id_attribute}",
                    search_attrs: "
#{self.external_id_attribute}:
  number:
    all: true
    multiple: single
"
      end

      if self.pregenerate_ids?
        r = usage_report('Unassigned')
        unless r
          Report.create! name: usage_report_name('Unassigned'),
                      item_type: "External ID Usage",
                      report_type: 'regular_report',
                      auto: false,
                      searchable: false,
                      current_admin: self.admin,
                      position: 100,
                      sql: "select id, #{self.external_id_attribute} from #{self.name} where master_id is null"
        end
      end
    end
  end

end

# Force the initialization. Do this here, rather than an initializer, since forces a reload if rails reloads classes in development mode.
# ExternalIdentifier.define_models
