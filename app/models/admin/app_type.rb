# frozen_string_literal: true

class Admin::AppType < Admin::AdminBase
  self.table_name = 'app_types'
  include AdminHandler
  include SelectorCache

  has_many :user_access_controls, -> { order id: :asc }, autosave: true, class_name: 'Admin::UserAccessControl'
  has_many :app_configurations, -> { order id: :asc }, autosave: true, class_name: 'Admin::AppConfiguration'
  has_many :page_layouts, -> { order id: :asc }, autosave: true, class_name: 'Admin::PageLayout'
  has_many :user_roles, -> { order id: :asc }, autosave: true, class_name: 'Admin::UserRole'
  has_many :nfs_store_filters, -> { order id: :asc }, autosave: true, class_name: 'NfsStore::Filter::Filter'

  validates :name, presence: true
  validate :name_not_already_taken
  validates :label, presence: true
  after_save :set_access_levels

  attr_accessor :import_results

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
      app_type = Admin::AppType.find(olat)
    else
      active
    end
  end

  def self.all_ids_available_to(user)
    Rails.cache.fetch("all_app_type_ids_available_to::#{user.id}") do
      atavail = []

      active.each do |a|
        hat = user.has_access_to?(:access, :general, :app_type, alt_app_type_id: a.id)
        atavail << hat.app_type.id if hat
      end
      atavail
    end
  end

  def self.all_available_to(user)
    atavail = []

    active.each do |a|
      hat = user.has_access_to?(:access, :general, :app_type, alt_app_type_id: a.id)
      atavail << hat.app_type if hat
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

  def self.import_config(config_json, admin, name: nil, force_disable: false, format: :json)
    if format == :json
      config = JSON.parse(config_json)
    elsif format == :yaml
      config = YAML.safe_load(config_json)
    end

    app_type_config = config['app_type']
    raise FphsException, "Incorrect format for configuration format #{format}" unless app_type_config

    new_id = nil
    results = { 'app_type' => {} }
    id_list = []

    Admin::AppType.transaction do
      a_conf = app_type_config.slice('name', 'label')

      # override the name if specified
      a_conf[:current_admin] = admin

      a_conf['name'] = name if name

      app_type = Admin::AppType.where(name: a_conf['name']).first || Admin::AppType.create!(a_conf)

      res = results['app_type']

      ### Force update of reports that don't have a short_name (yet)
      rs = Report.active.where(short_name: nil)
      rs.each do |r|
        r.current_admin = admin
        r.gen_short_name
        r.save!
      end
      ###

      res['app_configurations'] = app_type.import_config_sub_items app_type_config, 'app_configurations', ['name', 'role_name']

      res['associated_config_libraries'] = app_type.import_config_sub_items app_type_config, 'associated_config_libraries', ['name', 'category', 'format']
      res['associated_dynamic_models'] = app_type.import_config_sub_items app_type_config, 'associated_dynamic_models', ['table_name'], create_disabled: force_disable
      res['associated_external_identifiers'] = app_type.import_config_sub_items app_type_config, 'associated_external_identifiers', ['name'], create_disabled: force_disable
      res['associated_activity_logs'] = app_type.import_config_sub_items app_type_config, 'valid_associated_activity_logs', ['item_type', 'rec_type', 'process_name'], create_disabled: force_disable

      res['associated_general_selections'] = app_type.import_config_sub_items app_type_config, 'associated_general_selections', ['item_type', 'value']
      res['associated_reports'] = app_type.import_config_sub_items app_type_config, 'associated_reports', ['short_name', 'item_type']

      res['page_layouts'] = app_type.import_config_sub_items app_type_config, 'page_layouts', ['layout_name', 'panel_name']
      res['user_roles'] = app_type.import_config_sub_items app_type_config, 'user_roles', ['role_name']
      res['nfs_store_filters'] = app_type.import_config_sub_items app_type_config, 'nfs_store_filters', ['role_name', 'resource_name', 'filter']

      res['associated_message_templates'] = app_type.import_config_sub_items app_type_config, 'associated_message_templates', ['name', 'message_type', 'template_type']

      res['associated_protocols'] = app_type.import_config_sub_items app_type_config, 'associated_protocols', ['name']
      res['associated_sub_processes'] = app_type.import_config_sub_items app_type_config, 'associated_sub_processes', ['name'], filter_on: ['protocol_name']
      res['associated_protocol_events'] = app_type.import_config_sub_items app_type_config, 'associated_protocol_events', ['name'], filter_on: ['sub_process_name', 'protocol_name']

      res['user_access_controls'] = app_type.import_config_sub_items app_type_config, 'valid_user_access_controls', ['resource_type', 'resource_name', 'role_name'], add_vals: { allow_bad_resource_name: true }, id_list: id_list

      app_type.reload
      new_id = app_type.id
    end

    app_type = find(new_id)
    app_type.clean_user_access_controls id_list
    app_type.reload

    [app_type, results]
  end

  def filtered_results(items, filter)
    f = items.select do |item|
      res = true
      filter.each { |fk, fv| res &&= (item.send(fk.to_s) == fv) }
      res
    end
    f
  end

  def import_config_sub_items(app_type_config, name, lookup_existing_with_fields, reject: nil, add_vals: {}, create_disabled: false, filter_on: nil, id_list: [])
    results = []
    orig_name = name
    name = name.gsub(/^valid_/, '')

    not_directly_associated = true if name.starts_with? 'associated_'

    if not_directly_associated
      begin
        cname = self.class.class_from_name name.sub('associated_', '')
      rescue NameError
        raise
      end
    else
      parent = self
      assoc_name = name
    end

    acs = app_type_config[name] || app_type_config[orig_name]
    return unless acs

    acs = acs.reject(&reject) if reject
    acs.each do |ac|
      el = nil

      next if ac['disabled']

      # Get the item if it has been set up automatically
      cond = ac.slice(*lookup_existing_with_fields)
      filter = ac.slice(*filter_on) if filter_on
      new_vals = ac.except('user_email', 'user_id', 'app_type_id', 'admin_id', 'id', 'created_at', 'updated_at')
      new_vals[:current_admin] = admin

      if parent
        has_user = parent.send(assoc_name).attribute_names.include?('user_id')

        if has_user
          # Check if the user exists, based on its email. If not, and the email ends with @template, create a user as a placeholder
          user = self.class.user_from_email ac['user_email']
          if user == :unknown && ac['user_email'].end_with?('@template')
            User.create(email: ac['user_email'], first_name: 'template', last_name: 'template', current_admin: admin)
            end
          cond[:user] = user
        end
        unless user == :unknown
          # Use the app type's admin as the current admin
          new_vals[:user] = user if has_user
          new_vals.merge! add_vals
          i = parent.send(assoc_name).where(cond).reorder('').order('disabled asc nulls first, id desc')
          i = filtered_results(i, filter) if filter
          i = i.first
          if i
            el = i
            el = nil unless el.changed?
            i.update! new_vals
          else
            new_vals['disabled'] = true if create_disabled
            i = el = parent.send(assoc_name).create! new_vals
          end
        end
      else
        new_vals.merge! add_vals

        i = cname.where(cond).reorder('').order('disabled asc nulls first, id desc')
        i = filtered_results(i, filter) if filter
        i = i.first

        if i
          el = i
          new_vals['disabled'] = true if i.respond_to?(:ready?) && !i.ready?
          el = nil unless el.changed?
          i.update! new_vals
        else
          new_vals['disabled'] = true if create_disabled
          i = el = cname.create! new_vals
        end
      end

      id_list << i.id if i

      next unless el

      results << if el.respond_to? :attributes
                   el.attributes
                 else
                   el
                 end
    end
    results
  end

  def clean_user_access_controls(id_list)
    # Invalid user access control ID list, so we can disable them
    vuc = valid_user_access_controls.pluck(:id)
    # inv =
    inv = user_access_controls.active.pluck(:id) - id_list #- vuc

    inv.each do |i|
      el = Admin::UserAccessControl.find(i)
      res = el.disable! admin
      Rails.logger.info "Failed to clean up bad resource UAC: #{i}. #{el.errors.first}" unless res
    end

    valid_user_access_controls.where(resource_type: :report).each do |u|
      rn = u.resource_name
      next unless rn.present?

      u.update resource_name: Report.resource_name_for_named_report(rn), current_admin: admin unless rn.include?('_')
    end
  end

  def valid_user_access_controls
    user_access_controls.valid_resources
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
      ", names, names, names).order(id: :asc)
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

    DynamicModel.active.where(table_name: names).order(id: :asc)
  end

  def associated_external_identifiers
    eids = ExternalIdentifier.active.map(&:name)
    names = user_access_controls.valid_resources.where(resource_type: :table).select { |a| a.access && a.resource_name.in?(eids) }.map(&:resource_name).uniq
    ExternalIdentifier.active.where(name: names).order(id: :asc)
  end

  def associated_reports
    names = user_access_controls.valid_resources.where(resource_type: :report).where("access IS NOT NULL and access <> ''").map(&:resource_name).uniq
    names = Report.active.map(&:alt_resource_name).uniq if names.include? '_all_reports_'

    Report.active.where("(REGEXP_REPLACE(item_type, '( |-)', '_') || '__' || short_name) in (?)", names).order(id: :asc)
  end

  def associated_general_selections
    gs = []

    associated_table_names.each do |tn|
      tnlike = "#{tn.singularize}_%"
      tnplurallike = "#{tn}_%"
      res = Classification::GeneralSelection.active.where('item_type LIKE ? or item_type LIKE ?', tnlike, tnplurallike).order(id: :asc)
      gs += res
    end

    gs.sort { |a, b| a.id <=> b.id }
  end

  def associated_protocols
    return [] unless name == 'zeus'

    Classification::Protocol.active.order(id: :asc)
  end

  def associated_sub_processes
    return [] unless name == 'zeus'

    protocol_ids = associated_protocols.pluck(:id)
    Classification::SubProcess.active.where(protocol_id: protocol_ids).order(id: :asc)
  end

  def associated_protocol_events
    return [] unless name == 'zeus'

    sub_processes = associated_sub_processes.pluck(:id)
    Classification::ProtocolEvent.active.where(sub_process_id: sub_processes).order(id: :asc)
  end

  def associated_message_templates
    ms = []
    associated_activity_logs.all.each do |a|
      a.extra_log_type_configs.each do |c|
        c.dialog_before.each do |_d, v|
          res = Admin::MessageTemplate.active.where(name: v[:name], message_type: 'dialog', template_type: 'content').first
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
          res = Admin::MessageTemplate.active.where(name: v[:name], message_type: 'dialog', template_type: 'content').first
          ms << res
        end
      end
    end
    ms.sort { |a, b| a.id <=> b.id }.uniq
  end

  def associated_config_libraries
    ms = []

    associated_activity_logs.all.each do |a|
      ms += ExtraLogType.config_libraries a
    end

    associated_dynamic_models.all.each do |a|
      ms += ExtraOptions.config_libraries a
    end

    associated_reports.all.each do |a|
      ms += ExtraOptions.config_libraries a
    end

    ms.sort { |a, b| a.id <=> b.id }.uniq
  end

  def export_config(format: :json)
    if format == :json
      JSON.pretty_generate(JSON.parse(to_json))
    elsif format == :yaml
      YAML.dump(JSON.parse(to_json))
    end
  end

  def as_json(options = {})
    options[:root] = true
    options[:methods] ||= []
    options[:include] ||= {}

    options[:methods] << :app_configurations
    options[:methods] << :valid_user_access_controls
    options[:methods] << :valid_associated_activity_logs
    options[:methods] << :associated_dynamic_models
    options[:methods] << :associated_external_identifiers
    options[:methods] << :associated_reports
    options[:methods] << :associated_general_selections
    options[:methods] << :page_layouts
    options[:methods] << :user_roles
    options[:methods] << :associated_message_templates
    options[:methods] << :associated_config_libraries
    options[:methods] << :associated_protocols
    options[:methods] << :associated_sub_processes
    options[:methods] << :associated_protocol_events
    options[:methods] << :nfs_store_filters

    super(options)
  end

  private

  def set_access_levels
    # if !persisted? || self.user_access_controls.length == 0
    #   Admin::UserAccessControl.create_all_for self, current_admin
    #   return true
    # end
  end
end
