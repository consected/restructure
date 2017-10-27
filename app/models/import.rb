class Import < ActiveRecord::Base
  belongs_to :user

  validate :check_csv_columns

  attr_accessor :items, :csv_rows


  def self.accepts_models
    Master::AllAssociations
  end


  def self.import_csv csv, primary_table, current_user, filename
    import = Import.new
    csv_rows = CSV.parse(csv, headers: true, header_converters: :symbol)
    import.primary_table = primary_table
    # The user attribute is allowed to be set on Import
    # This has the required side-effect that the models being created form the CSV data
    # will get their user at creation time  based on this
    import.user = current_user
    import.item_count = csv_rows.length
    import.csv_rows = csv_rows
    import.filename = filename
    import.build_objects_from_data
    import.save
    return import

  end

  def self.item_class_for primary_table
    primary_table.singularize.ns_camelize.ns_constantize
  end

  def item_class
    self.primary_table.singularize.ns_camelize.ns_constantize
  end

  def self.permitted_params_for primary_table
    item_class_for(primary_table).attribute_names - ['id', 'user_id', 'created_at', 'updated_at']
  end

  def permitted_params_for_primary_table
    self.class.permitted_params_for primary_table
  end

  def build_objects_from_data
    objects = []
    return true unless self.csv_rows
    csv_rows.each do |row|
      new_obj = self.item_class.new(row.to_h)

      attempt_match_on_secondary_key new_obj

      objects << new_obj
    end
    self.items = objects
  end

  # If necessary, match on secondary key field.
  def attempt_match_on_secondary_key new_obj
    new_obj.match_with_parent_secondary_key current_user: self.user
    if new_obj.item
      new_obj.item.master.current_user = self.user
      if new_obj.respond_to?('master_id=') && !new_obj.master_id
        new_obj.master = new_obj.item.master
      end
    end
  end

  private

    def check_csv_columns
      return true unless self.csv_rows
      keys = self.csv_rows.first.to_h.keys
      res = keys - self.permitted_params_for_primary_table.map(&:to_sym)
      if res.length > 0
        errors.add "some columns", "in the CSV file do not match the table columns. The acceptable columns are: #{permitted_params_for_primary_table.join(', ')}. Unexpected columns in the CSV file are: #{res.join(', ')}"
      end
    end

    def self.setup_accepted_models
      self.accepts_models.each do |m|
        define_method :"#{m}_attributes=" do |attrs|
        end
      end
    end

  # Do the setup!
  self.setup_accepted_models

end
