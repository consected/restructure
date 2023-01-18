class Imports::Import < ActiveRecord::Base
  belongs_to :user

  validate :accepted_model
  validate :check_csv_columns

  attr_accessor :items, :csv_rows

  #
  # List of all models that can be imported
  # @param [User] user - optionally limit the result to the specified user and current app type
  # @return [Array{String}]
  def self.accepts_models(user = nil)
    uac = Admin::UserAccessControl.active.where(resource_type: :table)
    if user
      uac = uac.scope_user_and_role(user)
      uac.pluck(:resource_name).uniq
    end

    tables = uac.where(resource_type: 'table').valid_resources.pluck(:resource_name).sort
    tables -= %w[item_flags]
    # mtables = Master.get_all_associations
    (tables + ['masters']).sort
  end

  #
  # Setup an Import instance with the supplied params
  # @param [String] primary_table to be imported to
  # @param [User] current_user performing the import
  # @param [String] filename to record
  # @return [Import] resulting Import instance
  def self.setup_import(primary_table, current_user, filename)
    import = Imports::Import.new
    import.primary_table = primary_table
    import.user = current_user
    import.filename = filename
    import.save
    import
  end

  #
  # After setting up an Import instance, run an import of the supplied CSV
  # @param [String] csv - full CSV text
  # @return [Import] self
  def import_csv(csv)
    csv_rows = CSV.parse(csv, headers: true, header_converters: :symbol)
    # The user attribute is allowed to be set on Import
    # This has the required side-effect that the models being created form the CSV data
    # will get their user at creation time  based on this
    self.item_count = csv_rows.length
    self.csv_rows = csv_rows
    return self unless check_csv_columns

    build_objects_from_data
    # force retaining of errors, since save will clear them
    duperrors = errors.dup
    save
    unless duperrors.empty?
      duperrors.to_h.each do |k, e|
        errors.add k, e
      end
    end
    self
  end

  #
  # Generate *num* blank items for population by a user
  # @param [Integer] num - number of items to add
  def generate_blank_items(num)
    self.items ||= []
    num.times do
      item = item_class.new
      item.attribute_names.each do |a|
        item[a] = nil
      end
      self.items << item
    end
  end

  #
  # Get the class for the named table (really a model name)
  # @param [String] primary_table - table name
  # @return [Class|nil] returns the Class or nil if the model does not exist
  def self.item_class_for(primary_table)
    primary_table.singularize.ns_camelize.ns_constantize
  rescue NameError
    logger.debug "No class defined for primary table: #{primary_table}"
    nil
  end

  #
  # Get the class for the *primary_table* attribute
  # Will raise an error if it doesn't exist
  # @return [Class]
  def item_class
    primary_table.singularize.ns_camelize.ns_constantize
  end

  #
  # Set up a list of permitted parameters to be used by strong parameters during instantiation.
  # @param [String] primary_table - named table / model
  # @param [Boolean] include_alt_ids - default (true) to add in the alternative IDs that allow
  #   imports using crosswalk and external identifiers in the CSV. If false, only master_id is allowed
  # @return [Array{String}] list of acceptable parameters
  def self.permitted_params_for(primary_table, include_alt_ids = true)
    pt = item_class_for(primary_table)
    return unless pt

    res = pt.attribute_names - %w[id user_id created_at updated_at]
    res += Master.alternative_id_fields.map(&:to_s) if include_alt_ids && res.include?('master_id')
    res.uniq!
    res
  end

  #
  # Performs {Import#permitted_params_for} on the instance *primary_table*
  def permitted_params_for_primary_table(include_alt_ids = true)
    self.class.permitted_params_for primary_table, include_alt_ids
  end

  #
  # Process a row of entries to handle special types (arrays).
  # The results are applied directly to the specified object, to avoid
  # issues with what is permitted by attribute assignments.
  # @param [UserBase] object instance
  # @param [CSV::Row] row
  def process_columns(obj, row)
    row.each do |k, v|
      next unless item_class.columns.find { |c| c.name == k.to_s }.array?

      if v&.start_with? '['
        obj[k] = JSON.parse(v)
      elsif v.is_a? String
        obj[k] = v.split(',')
      end
    end

    row
  end

  # Instantiate the primary_table / model for each CSV row previously set up in {#import_csv}.
  # Sets #items with an array of instances, with current_user set
  # @return [Array]
  def build_objects_from_data
    objects = []
    return true unless csv_rows

    csv_rows.each do |row|
      begin
        new_obj = item_class.new(row.to_h)
        process_columns(new_obj, row)
        attempt_match_on_secondary_key new_obj

        if new_obj.respond_to?(:master) &&
           !new_obj.class.no_master_association &&
           !new_obj.master &&
           new_obj.master_id

          # This will most likely fail, but provides an error back to the caller
          new_obj.master = Master.find(new_obj.master_id)
        end

        new_obj.current_user ||= user if new_obj.respond_to? :current_user
        new_obj[:user_id] ||= user_id if new_obj.respond_to? :user_id
      rescue FphsException => e
        errors.add 'import error', e.message
      rescue StandardError => e
        errors.add 'unexpected error', e.message
      end
      objects << new_obj
    end
    self.items = objects
  end

  # If necessary, match on secondary key field to set the master for an object
  # @param [Class] new_obj - the object to attempt to match to a master
  # @return [<Type>] <description>
  def attempt_match_on_secondary_key(new_obj)
    return false unless new_obj.respond_to?(:item)
    return false unless new_obj.respond_to?(:match_with_parent_secondary_key)

    new_obj.match_with_parent_secondary_key current_user: user
    return unless new_obj.item

    new_obj.item.master.current_user = user
    new_obj.master = new_obj.item.master if new_obj.respond_to?('master_id=') && !new_obj.master_id
    new_obj.item
  end

  #
  # Check the CSV rows being provided do not attempt to set columns that
  # don't exist as permitted params in imported model
  # @return [Boolean] true if good
  def check_csv_columns
    return true unless csv_rows

    keys = csv_rows.first.to_h.keys
    excess = keys - permitted_params_for_primary_table.map(&:to_sym)
    if excess.present?
      errors.add 'some columns', 'in the CSV file do not match the table columns. ' \
        "Unexpected columns in the CSV file are: #{excess.join(', ')}"
      return false
    end
    true
  end

  #
  # Is this model accepting imports?
  # @param [String] primary_table
  # @return [Boolean]
  def self.accepted_model(primary_table)
    Imports::Import.accepts_models.include?(primary_table)
  end

  #
  # Called to set up the models that accept import
  def self.setup_accepted_models
    accepts_models.each do |m|
      define_method :"#{m}_attributes=" do |attrs|
      end
    end
  end

  private

  # Only allow creation and update for models that are accepted, to avoid
  # either leakage of data structures or import into tables that are
  # not acceptable
  def accepted_model
    Imports::Import.accepted_model(primary_table)
  end

  # Do the setup!
  setup_accepted_models
end
