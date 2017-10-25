class Import < ActiveRecord::Base
  belongs_to :user

  attr_accessor :items


  def self.setup_accepted_models
    self.accepts_models.each do |m|
      define_method :"#{m}_attributes=" do |attrs|

      end
      # define_method :"#{m}" do
      #   self.items
      # end
    end
  end

  def self.accepts_models
    ['activity_log__player_contact_phones']
  end

  def self.import_csv csv, primary_table, current_user
    import = Import.new
    csv_rows = CSV.parse(csv, headers: true, header_converters: :symbol)
    import.primary_table = primary_table
    import.user = current_user
    import.item_count = csv_rows.length

    logger.debug "CSV Rows: #{csv_rows.inspect}"

    objects = []
    csv_rows.each do |row|
      logger.debug "Building item class for #{import.item_class.name}"
      objects << import.item_class.new(row.to_h)
    end

    import.items = objects
    import.save!
    return import
  end

  def self.item_class_for primary_table
    primary_table.singularize.ns_camelize.ns_constantize
  end

  def item_class
    self.primary_table.singularize.ns_camelize.ns_constantize
  end

  def self.permitted_params_for primary_table
    item_class_for(primary_table).attribute_names
  end


  self.setup_accepted_models

end
