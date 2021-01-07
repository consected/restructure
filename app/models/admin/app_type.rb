# frozen_string_literal: true

class Admin::AppType < Admin::AdminBase
  self.table_name = 'app_types'
  include AdminHandler
  include SelectorCache
  include AppTypeImport
  include AppTypeExport

  has_many :user_access_controls, -> { order id: :asc }, autosave: true, class_name: 'Admin::UserAccessControl'
  has_many :app_configurations, -> { order id: :asc }, autosave: true, class_name: 'Admin::AppConfiguration'
  has_many :page_layouts, -> { order id: :asc }, autosave: true, class_name: 'Admin::PageLayout'
  has_many :user_roles, -> { order id: :asc }, autosave: true, class_name: 'Admin::UserRole'
  has_many :nfs_store_filters, -> { order id: :asc }, autosave: true, class_name: 'NfsStore::Filter::Filter'
  has_many :protocols, -> { order id: :asc }, autosave: true, class_name: 'Classification::Protocol'

  validates :name, presence: true
  validate :name_not_already_taken
  validates :label, presence: true

  after_create :setup_migrations

  def name_not_already_taken
    return true if disabled

    !already_taken(:name)
  end

  def to_s
    name
  end

  def self.active_app_types
    olat = Settings::OnlyLoadAppTypes
    if olat
      Admin::AppType.find(olat)
    else
      active
    end
  end

  def self.all_ids_available_to(user)
    Rails.cache.fetch("all_app_type_ids_available_to::#{user.id}") do
      all_available_to(user).map(&:id)
    end
  end

  def self.all_available_to(user)
    atavail = []
    olat = Settings::OnlyLoadAppTypes
    active.each do |a|
      hat = user.has_access_to?(:access, :general, :app_type, alt_app_type_id: a.id)
      atavail << hat.app_type if hat && (!olat || hat.app_type_id.in?(olat))
    end
    atavail
  end

  def self.all_by_name
    res = {}

    active.each do |a|
      res[a.id.to_s] = a.name.underscore
    end

    res
  end

  def self.user_from_email(user_email)
    user = nil
    if user_email
      user = User.active.where(email: user_email).first
      user ||= :unknown
    end

    user
  end

  def valid_user_access_controls
    user_access_controls.valid_resources.reorder('').order(id: :asc)
  end

  # Select any tables that have some kind of access
  def associated_table_names
    user_access_controls.valid_resources.where(resource_type: :table).select(&:access).map(&:resource_name).uniq
  end

  def valid_associated_activity_logs
    associated_activity_logs valid_resources_only: true
  end

  # Select activity logs that have some kind of access, typically scoped to a specific app type
  # @return [ActiveRecord::Relation]
  def associated_activity_logs(valid_resources_only: false)
    uacs = if valid_resources_only
             user_access_controls.valid_resources
           else
             user_access_controls.active
           end

    get_names = uacs.where(resource_type: :table)
                    .select { |a| a.access && a.resource_name.start_with?('activity_log__') }
    names = get_names.map { |n| n.resource_name.singularize.sub('activity_log__', '') }.uniq
    names += get_names.map { |n| n.resource_name.sub('activity_log__', '') }.uniq

    ActivityLog.active.where("
         (rec_type is NULL OR rec_type = '') AND (process_name IS NULL OR process_name = '') AND item_type in (?)
      OR (process_name IS NULL OR process_name = '') AND (item_type || '_' || rec_type) in (?)
      OR (rec_type IS NULL OR rec_type = '') AND (item_type || '_' || process_name) in (?)
      ", names, names, names).reorder('').order(id: :asc)
  end

  def associated_dynamic_models(valid_resources_only: true)
    uacs = if valid_resources_only
             user_access_controls.valid_resources
           else
             user_access_controls.active
           end

    names = uacs.where(resource_type: :table)
                .select { |a| a.access && a.resource_name.start_with?('dynamic_model__') }
                .map { |n| n.resource_name.sub('dynamic_model__', '') }.uniq

    DynamicModel.active.where(table_name: names).reorder('').order(id: :asc)
  end

  def associated_external_identifiers
    eids = ExternalIdentifier.active.map(&:name)
    names = user_access_controls
            .valid_resources
            .where(resource_type: :table)
            .select { |a| a.access && a.resource_name.in?(eids) }
            .map(&:resource_name).uniq

    ExternalIdentifier.active.where(name: names).reorder('').order(id: :asc)
  end

  def associated_reports
    names = user_access_controls.valid_resources.where(resource_type: :report).where("access IS NOT NULL and access <> ''").map(&:resource_name).uniq
    names = Report.active.map(&:alt_resource_name).uniq if names.include? '_all_reports_'

    Report.active.where("(REGEXP_REPLACE(item_type, '( |-)', '_') || '__' || short_name) in (?)",
                        names).reorder('').order(id: :asc)
  end

  def associated_general_selections
    gs = []

    associated_table_names.each do |tn|
      tnlike = "#{tn.singularize}_%"
      tnplurallike = "#{tn}_%"
      res = Classification::GeneralSelection
            .active
            .where('item_type LIKE ? or item_type LIKE ?',
                   tnlike,
                   tnplurallike)
            .order(id: :asc)
      gs += res
    end

    gs.sort { |a, b| a.id <=> b.id }
  end

  def associated_protocols
    t = Classification::Protocol
    t.active.where(app_type: self).or(t.where(app_type: nil)).reorder('').order(id: :asc)
  end

  def associated_sub_processes
    protocol_ids = associated_protocols.pluck(:id)
    Classification::SubProcess.active.where(protocol_id: protocol_ids).reorder('').order(id: :asc)
  end

  def associated_protocol_events
    sub_processes = associated_sub_processes.pluck(:id)
    Classification::ProtocolEvent.active.where(sub_process_id: sub_processes).reorder('').order(id: :asc)
  end

  def associated_item_flag_names
    tns = associated_table_names
    sing_and_plur_tns = tns + tns.map(&:singularize)

    ifns = Classification::ItemFlagName
           .active
           .where(item_type: sing_and_plur_tns)
           .reorder('')
           .order(id: :asc)
  end

  def associated_message_templates
    ms = []
    associated_activity_logs.all.each do |a|
      a.option_configs.each do |c|
        c.dialog_before.each do |_d, v|
          res = Admin::MessageTemplate
                .active
                .where(
                  name: v[:name],
                  message_type: 'dialog',
                  template_type: 'content'
                )
                .first
          ms << res
        end
        c.save_trigger.each do |_d, st|
          ns = st[:notify] || []
          ns = [ns] if ns.is_a? Hash

          ns.each do |v|
            lt = v[:layout_template]
            ct = v[:content_template]
            mt = v[:type]

            res = Admin::MessageTemplate.active.where(name: lt, message_type: mt, template_type: 'layout').first
            ms << res if res
            res = Admin::MessageTemplate.active.where(name: ct, message_type: mt, template_type: 'content').first
            ms << res if res
          end
        end
      end
    end
    associated_dynamic_models.all.each do |a|
      a.option_configs.each do |c|
        c.dialog_before.each do |_d, v|
          res = Admin::MessageTemplate
                .active
                .where(
                  name: v[:name],
                  message_type: 'dialog',
                  template_type: 'content'
                )
                .first
          ms << res
        end
      end
    end
    ms.sort { |a, b| a.id <=> b.id }.uniq
  end

  # Which configurations are associated with this app indirectly,
  # by being referenced as a user access control in the app.
  # If there is no user access control, no user can access the
  # model / table, so we assume it is not used.
  # This assumption is reinforced, since new items within an app
  # create a user access control associated with a special user
  # template@template that ensures that we can export configurations
  # that are not directly used, or for which there are no other
  # matching user records on the destination server
  def associated_config_libraries
    ms = []

    associated_activity_logs.all.each do |a|
      ms += OptionConfigs::ActivityLogOptions.config_libraries a
    end

    associated_dynamic_models.all.each do |a|
      ms += OptionConfigs::DynamicModelOptions.config_libraries a
    end

    associated_external_identifiers.all.each do |a|
      ms += OptionConfigs::ExternalIdentifierOptions.config_libraries a
    end

    associated_reports.all.each do |a|
      ms += OptionConfigs::ReportOptions.config_libraries a
    end

    ms.sort { |a, b| a.id <=> b.id }.uniq
  end

  def setup_migrations
    return true unless Rails.env.development?

    return true if self.class.where(default_schema_name: default_schema_name).count > 1

    migration_generator = Admin::MigrationGenerator.new(default_schema_name)
    migration_generator.add_schema
  end
end
