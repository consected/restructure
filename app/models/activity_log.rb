class ActivityLog < ActiveRecord::Base

  SubProcessName = 'Activity'

  include AdminHandler
  include SelectorCache

  before_validation :prevent_item_type_change,  on: :update
  validates :name, presence: true, uniqueness: {scope: :disabled}
  validates :item_type, presence: true
  validate :check_item_type_and_rec_type
  after_commit :reload_routes
  after_commit :generate_protocol_entries
  after_commit :add_to_app_list


  # checks if this activity log works with the specified item_type and optionally rec_type based on admin activity log record configuration
  # if no rec_type is specified, then just the item_type will be used to match broadly,
  # even if the configuration specifies a rec_type as a requirement
  # Only enabled admin activity log records are used, excluding other possible options that are not configured.
  # Returns the item_type_name if true
  def self.works_with item_type, rec_type=nil
    item_type = item_type.downcase
    cond = {item_type: item_type}
    cond[:rec_type] = rec_type if rec_type
    res = self.enabled.where(cond).first
    return unless res
    res.item_type_name
  end

  def self.works_with_rec_types item_type
    self.enabled.where(item_type: item_type).all.map {|i| i.rec_type }
  end

  def blank_log_enabled?
    !blank_log_field_list.blank?
  end



  # return the activity log implementation class that corresponds to
  # this item (item_type / rec_type in an enabled admin activity log record)
  def self.al_class_for item

    item_type = item.item_type

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

    # attempt to get the activity log implementation class based on class name
    al_cn = al_cn.camelize
    begin
      fcn = "ActivityLog::#{al_cn}"
      al_class = fcn.constantize
    rescue => e
      logger.warn "Failed to get #{fcn} => \n#{e.backtrace[0..10].join("\n")}"
    end
    raise "Failed to get #{al_cn} " unless al_class
    return al_class
  end

  # The table name for the activity log implementation
  def table_name
    "activity_log_#{item_type_name}".pluralize
  end

  # List of attributes to be used in common template views
  # Use the defined field_list if it is not blank
  # Otherwise use attribute names from the model, removing common junk
  def view_attribute_list
    unless self.field_list.blank?
      self.field_list.split(',').map {|f| f.strip}.compact
    else
      self.attribute_names - ['id', 'master_id', 'disabled',parent_type ,"#{parent_type}_id", 'user_id', 'created_at', 'updated_at', 'rank', 'source'] + ['tracker_history_id']
    end
  end

  def view_blank_log_attribute_list
    unless self.blank_log_field_list.blank?
      self.blank_log_field_list.split(',').map {|f| f.strip}.compact
    end
  end

  # The class that an activity log implementation belongs to
  def item_class
    self.item_type.singularize.classify.constantize
  end

  def item_type_name
    return @item_type_name if @item_type_name
    tn = []
    tn << item_type
    tn << rec_type unless rec_type.blank?
    @item_type_name = tn.join('_')
  end

  # Full namespaced item type name, underscored with double underscores
  def full_item_type_name
    "activity_log__#{item_type_name}".singularize
  end

  # Full namespaced item types (pluralized) name, underscored with double underscores
  def full_item_types_name
    "activity_log__#{item_type_name}".pluralize
  end

  def rec_type_valid?
    return true if self.rec_type.blank?
    rcs = item_class.valid_rec_types
    # it is valid if there are no rec types in the list || the current rec type is included
    return !rcs || rcs.include?(rec_type)
  end

  def item_type_valid?
    return true if self.class.use_with_class_names.include?(self.item_type.pluralize)
    false
  end

  def model_def
    self.class.models[model_def_name]
  end

  def model_def_name
    item_type_name.singularize.to_sym
  end

  def activity_log_class_name
    "ActivityLog::#{item_type.classify}#{rec_type.classify}"
  end

  def activity_log_class
    activity_log_class_name.constantize
  end

  def model_assocation_name
    activity_log_class_name.pluralize.ns_underscore.to_sym
  end

  # the list of defined activity log implementation classes
  def self.al_classes
    @al_classes = ActivityLog.enabled.map{|a| "ActivityLog::#{[a.item_type, a.rec_type].join('_').classify}".constantize }
  end


  # The selection of possible class names that activity logs could be used with
  # This list is the full list of possible items, and only those configured and read by #works_with are actually available
  # for activity logging
  def self.use_with_class_names
    Master::PrimaryAssociations
  end



  # List of item types that can be used to define GeneralSelection drop downs
  # This does not represent the actual item types that are valid for selection when defining a new admin activity log record, which
  # is in fact provided by self.use_with_class_names
  def self.item_types

    list = []

    al_classes.each do |c|

      cn = c.attribute_names.select{|a| a.index('select_') == 0}.map{|a| a.to_sym} - [:disabled, :user_id, :created_at, :updated_at]
      cn.each do |a|
        list << "#{c.name.ns_underscore}_#{a}".to_sym
      end
    end

    list
  end

  def self.add_all_to_app_list
    self.active.each do |al|
      al.add_to_app_list
    end
  end

  # Optionally accept an association_block, allowing the association related methods such as #build to be overridden
  # in the master record association. Just passes this through to the add_master_assocation
  def add_to_app_list &association_block
    Application.add_to_app_list(:activity_log, self)
    add_master_association(&association_block)
  end

  def add_master_association &association_block

    # Add the association
    logger.info "Associated master: has_many #{self.model_assocation_name} with class_name: #{self.activity_log_class_name}"
    Master.has_many self.model_assocation_name, -> { order(self.action_when_attribute.to_sym => :desc, id: :desc)}, inverse_of: :master, class_name: self.activity_log_class_name, &association_block

    # Unlike external_id handlers (Scantron, etc) there is no need to update the master's nested attributes this model's symbol
    # since there is no link to advanced search
  end


  # set up a route for each available activity log definition
  def self.routes_load

    begin
      m = self.enabled
      return if m.length == 0

      Rails.application.routes.draw do
        resources :masters, only: [:show, :index, :new, :create] do

            m.each do |pg|
              mn = pg.model_def_name.to_s.pluralize.to_sym
              ic = pg.item_type.pluralize
              get "#{ic}/:item_id/activity_log/#{mn}/new", to: "activity_log/#{mn}#new"
              get "#{ic}/:item_id/activity_log/#{mn}/", to: "activity_log/#{mn}#index"
              get "#{ic}/:item_id/activity_log/#{mn}/:id", to: "activity_log/#{mn}#show"
              post "#{ic}/:item_id/activity_log/#{mn}", to: "activity_log/#{mn}#create"
              get "#{ic}/:item_id/activity_log/#{mn}/:id/edit", to: "activity_log/#{mn}#edit"
              patch "#{ic}/:item_id/activity_log/#{mn}/:id", to: "activity_log/#{mn}#update"
              put "#{ic}/:item_id/activity_log/#{mn}/:id", to: "activity_log/#{mn}#update"

              # used by links to get to activity logs without having to use parent item (such as a player contact with phone logs)
              get "activity_log/#{mn}/new", to: "activity_log/#{mn}#new"
              get "activity_log/#{mn}/:id", to: "activity_log/#{mn}#show"
              get "activity_log/#{mn}/", to: "activity_log/#{mn}#index"
              get "activity_log/#{mn}/:id/edit", to: "activity_log/#{mn}#edit"
              post "activity_log/#{mn}", to: "activity_log/#{mn}#create"
              # used by item flags to generate appropriate URLs
              get "activity_log__#{mn}/:id", to: "activity_log/#{mn}#show", as: "activity_log_#{pg.model_def_name.to_s}"

            end
        end
      end

    rescue ActiveRecord::StatementInvalid => e
      logger.warn "Not loading activity log routes. The table has probably not been created yet. #{e.backtrace.join("\n")}"
    end
  end

  def reload_routes
    Rails.application.reload_routes!
  end

  def generate_protocol_entries

    admin = self.current_admin
    Protocol.enabled.each do |p|
      sp = p.sub_processes.create! name: ActivityLog::SubProcessName, current_admin: admin
      sp.protocol_events.create! name: self.name, current_admin: admin
    end

  end

  def check_item_type_and_rec_type
    unless item_type_valid?
      errors.add(:item_type, "#{self.item_type} is invalid. It must be one of (#{self.class.use_with_class_names.join(",")})")
      return
    end
    unless rec_type_valid?
      errors.add(:rec_type, "(#{rec_type}) invalid for the selected item type #{item_type}.")
      return
    end
  end

end
