class ActivityLog < ActiveRecord::Base

  include AdminHandler
  include SelectorCache

  before_validation :prevent_item_type_change,  on: :update
  validates :name, presence: true, uniqueness: true
  validates :item_type, presence: true
  validate :rec_type_valid?


  
  # checks if this activity log works with the specified item_type and optionally rec_type
  # if no rec_type is specified, then just the item_type will be used to match broadly,
  # even if the configuration specifies a rec_type as a requirement
  def self.works_with item_type, rec_type=nil
    item_type = item_type.downcase
    cond = {item_type: item_type}
    cond[:rec_type] = rec_type if rec_type
    res = self.enabled.where(cond).first
    return unless res
    res.table_name
  end

  def self.works_with_rec_types item_type
    self.enabled.where(item_type: item_type).all.map {|i| i.rec_type }    
  end


  # return the class that corresponds to this item (item_type / rec_type)
  def self.al_class item

    item_type = item.item_type

    return @al_class if @al_class
        # To start, see if the Activity Log works with this item
    al_cn = ActivityLog.works_with item_type

    # If Activity Log broadly works with this item
    # attempt the same test with the rec_type set to see if there is a more specific match
    if item.respond_to?(:rec_type) && !item.rec_type.blank?
      al_cn_rc = ActivityLog.works_with item_type, item.rec_type
      al_cn = al_cn_rc if al_cn_rc
    end

    #  return if the Activity Log does not work with this item_type / rec_type combo
    return nil unless al_cn

    # attempt to get the class based on class name
    al_cn = al_cn.camelize
    begin
      fcn = "ActivityLog::#{al_cn}"
      @al_class = fcn.constantize
    rescue => e
      logger.warn "Failed to get #{fcn} => \n#{e.backtrace[0..10].join("\n")}"
    end
    raise "Failed to get #{al_cn} " unless @al_class
    return @al_class
  end

  def table_name
    item_type_name
  end

  def item_type_name
    return @item_type_name if @item_type_name
    tn = []
    tn << item_type
    tn << rec_type unless rec_type.blank?
    @item_type_name = tn.join('_')
  end

  def rec_type_valid?
    return if rec_type.blank?

    if GeneralSelection.selector_attributes([:name], item_type: "#{item_type.pluralize}_rec_type").length == 0
      errors.add(:rec_type, "(#{rec_type}) invalid for the selected item type")
    end

  end


  def model_def
    self.class.models[model_def_name]
  end

  def model_def_name
    table_name.singularize.to_sym
  end


  def self.al_classes
    @al_classes = [ActivityLog::PlayerContactPhone]
  end

  # list of item types that can be used to define GeneralSelection drop downs
  def self.item_types

    list = []

    al_classes.each do |c|
      c.attribute_names.each do |a|
        list << "#{c.name.underscore.gsub('/', '_')}_#{a}".to_sym
      end
    end

    list
  end


  # Optionally accept an association_block, allowing the association related methods such as #build to be overridden
  # in the master record association. Just passes this through to the add_master_assocation
  def add_to_app_list &association_block

    self.validates external_id_attribute, presence: true,  numericality: { only_integer: true, greater_than_or_equal_to: external_id_range.min, less_than_or_equal_to: external_id_range.max }

    Application.add_to_app_list(:external_id, self)
    add_master_association(&association_block)
  end


  def self.routes_load

    m = self.enabled
    

    Rails.application.routes.draw do
      resources :masters, only: [:show, :index, :new, :create] do
        
          m.each do |pg|
            mn = pg.model_def_name.to_s.pluralize.to_sym
            
            get ":item_controller/:item_id/activity_log/#{mn}/new", to: "activity_log/#{mn}#new"
            get ":item_controller/:item_id/activity_log/#{mn}/", to: "activity_log/#{mn}#index"
            get ":item_controller/:item_id/activity_log/#{mn}/:id", to: "activity_log/#{mn}#show"
            post ":item_controller/:item_id/activity_log/#{mn}", to: "activity_log/#{mn}#create"
            put ":item_controller/:item_id/activity_log/#{mn}/:id", to: "activity_log/#{mn}#edit"
          end
        
      end
    end
  end

end
