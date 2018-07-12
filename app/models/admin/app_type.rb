class Admin::AppType < Admin::AdminBase

  self.table_name = 'app_types'
  include AdminHandler
  include SelectorCache

  has_many :user_access_controls, -> { order id: :asc }, autosave: true, class_name: "Admin::UserAccessControl"
  has_many :app_configurations, -> { order id: :asc }, autosave: true, class_name: "Admin::AppConfiguration"
  has_many :page_layouts, -> { order id: :asc }, autosave: true, class_name: "Admin::PageLayout"
  has_many :user_roles, -> { order id: :asc }, autosave: true, class_name: "Admin::UserRole"

  validates :name, presence: true
  validates :label, presence: true
  after_save :set_access_levels

  attr_accessor :import_results

  def to_s
    name
  end

  def self.all_available_to user
    atavail = []

    self.active.each do |a|
      hat = user.has_access_to?(:access, :general, :app_type, alt_app_type_id: a.id)
      atavail << hat.app_type if hat
    end
    atavail
  end

  def self.all_by_name
    res = {}

    self.active.each do |a|
      res[a.id.to_s] = a.name.underscore
    end

    res
  end

  def self.user_from_email user_email
    user = nil
    if user_email
      user = User.active.where(email: user_email).first
      user ||= :unknown
    end

    user
  end

  def self.import_config config_json, admin, name: nil, force_disable: false

    config = JSON.parse(config_json)


    app_type_config = config['app_type']
    raise FphsException.new "Incorrect format for configuration JSON" unless app_type_config

    Admin::AppType.transaction do
      a_conf = app_type_config.slice('name', 'label')

      # override the name if specified
      a_conf[:current_admin] = admin

      a_conf['name'] = name if name


      app_type = Admin::AppType.where(name: a_conf['name']).first || Admin::AppType.create!(a_conf)

      results = {'app_type' => {}}

      res = results['app_type']


      res['app_configurations'] = app_type.import_config_sub_items app_type_config, 'app_configurations', ['name']

      res['associated_dynamic_models'] = app_type.import_config_sub_items app_type_config, 'associated_dynamic_models', ['table_name'], create_disabled: force_disable
      res['associated_external_identifiers'] = app_type.import_config_sub_items app_type_config, 'associated_external_identifiers', ['name'], create_disabled: force_disable
      res['associated_activity_logs'] = app_type.import_config_sub_items app_type_config, 'associated_activity_logs', ['item_type', 'rec_type', 'process_name'], create_disabled: force_disable

      res['associated_general_selections'] = app_type.import_config_sub_items app_type_config, 'associated_general_selections', ['item_type', 'value']
      res['associated_reports'] = app_type.import_config_sub_items app_type_config, 'associated_reports', ['name']

      res['page_layouts'] = app_type.import_config_sub_items app_type_config, 'page_layouts', ['layout_name', 'panel_name']
      res['user_roles'] = app_type.import_config_sub_items app_type_config, 'user_roles', ['role_name']

      res['associated_message_templates'] = app_type.import_config_sub_items app_type_config, 'associated_message_templates', ['name', 'message_type', 'template_type']

      res['associated_protocols'] = app_type.import_config_sub_items app_type_config, 'associated_protocols', ['name']
      res['associated_sub_processes'] = app_type.import_config_sub_items app_type_config, 'associated_sub_processes', ['name', 'protocol_name']
      res['associated_protocol_events'] = app_type.import_config_sub_items app_type_config, 'associated_protocol_events', ['name', 'sub_process_name', 'protocol_name']

      app_type.user_access_controls.active.each do |a|
        unless a.update(access: nil, current_admin: admin)
          puts "Failed to update UAC #{a.inspect}. #{a.errors.first}"
          a.disable!
        end
      end
      res['user_access_controls'] = app_type.import_config_sub_items app_type_config, 'user_access_controls', ['resource_type', 'resource_name'], add_vals: {allow_bad_resource_name: true}, reject: Proc.new {|a| a['access'].nil?}
      app_type.reload
      return app_type, results
    end


  end

  def import_config_sub_items app_type_config, name, lookup_existing_with_fields, reject: nil, add_vals: {}, create_disabled: false

    results = []

    if name.starts_with? 'associated_'
      not_directly_associated = true
    end

    if not_directly_associated
      begin
        cname = self.class.class_from_name name.sub('associated_', '')
      rescue NameError => e
        raise
      end
    else
      parent = self
      assoc_name = name
    end

    acs = app_type_config[name]
    return unless acs
    acs = acs.reject(&reject) if reject
    acs.each do |ac|
      el = nil

      unless ac['disabled']
        # Get the item if it has been set up automatically
        cond = ac.slice(*lookup_existing_with_fields)
        new_vals = ac.except('user_email', 'user_id', 'app_type_id', 'admin_id', 'id', 'created_at', 'updated_at')
        new_vals[:current_admin] = admin

        if parent
          has_user = parent.send(assoc_name).attribute_names.include?('user_id')
          cond[:user] = user = self.class.user_from_email ac['user_email'] if has_user
          unless user == :unknown
            # Use the app type's admin as the current admin
            new_vals[:user] = user if has_user
            new_vals.merge! add_vals
            i = parent.send(assoc_name).where(cond).order('disabled asc nulls first, id desc').first

            if i
              el = i
              i.update! new_vals
            else
              new_vals['disabled'] = true if create_disabled
              el = parent.send(assoc_name).create! new_vals
            end
          end
        else
          new_vals.merge! add_vals

          i = cname.where(cond).order('disabled asc nulls first, id desc').first

          if i
            el = i
            new_vals['disabled'] = true if i.respond_to?(:ready?) && !i.ready?
            i.update! new_vals
          else
            new_vals['disabled'] = true if create_disabled
            el = cname.create! new_vals
          end
        end
        results << el if el
      end
    end
    results
  end


  # Select any tables that have some kind of access
  def associated_table_names
    user_access_controls.active.where(resource_type: :table).select {|a| a.access }.map(&:resource_name).uniq
  end

  # Select activity logs that have some kind of access
  def associated_activity_logs
    names = user_access_controls.active.where(resource_type: :table).select {|a| a.access && a.resource_name.start_with?( 'activity_log__')}.map{|n| n.resource_name.singularize.sub('activity_log__', '')}.uniq
    ActivityLog.active.where("((rec_type is null or rec_type = '') and item_type in (?)) or ((item_type || '_' || rec_type) in (?))", names, names).order(id: :asc)
  end

  def associated_dynamic_models
    names = user_access_controls.active.where(resource_type: :table).select {|a| a.access && a.resource_name.start_with?( 'dynamic_model__')}.map{|n| n.resource_name.sub('dynamic_model__', '')}.uniq
    DynamicModel.active.where(table_name: names).order(id: :asc)
  end

  def associated_external_identifiers
    eids = ExternalIdentifier.active.map(&:name)
    names = user_access_controls.active.where(resource_type: :table).select {|a| a.access && a.resource_name.in?(eids)}.map(&:resource_name).uniq
    ExternalIdentifier.active.where(name: names).order(id: :asc)
  end

  def associated_reports
    names = user_access_controls.active.where(resource_type: :report).select {|a| a.access }.map(&:resource_name).uniq
    names = Report.active.pluck(:name).uniq if names.include? '_all_reports_'
    Report.active.where(name: names).order(id: :asc)
  end

  def associated_general_selections
    gs = []

    associated_table_names.each do |tn|
      tnlike = "#{tn.singularize}_%"
      tnplurallike = "#{tn}_%"
      res = Classification::GeneralSelection.active.where("item_type LIKE ? or item_type LIKE ?", tnlike, tnplurallike).order(id: :asc)
      gs += res
    end

    gs.sort {|a, b| a.id <=> b.id}
  end

  def associated_protocols
    return [] unless self.name == 'zeus'
    Classification::Protocol.active.order(id: :asc)
  end

  def associated_sub_processes
    return [] unless self.name == 'zeus'
    protocol_ids = associated_protocols.pluck(:id)
    Classification::SubProcess.active.where(protocol_id: protocol_ids).order(id: :asc)
  end

  def associated_protocol_events
    return [] unless self.name == 'zeus'
    sub_processes = associated_sub_processes.pluck(:id)
    Classification::ProtocolEvent.active.where(sub_process_id: sub_processes).order(id: :asc)
  end

  def associated_message_templates
    ms = []
    associated_activity_logs.all.each do |a|
      a.extra_log_type_configs.each do |c|
        c.dialog_before.each do |d, v|
          res = Admin::MessageTemplate.active.where(name: v[:name], message_type: 'dialog', template_type: 'content').first
          ms << res
        end
      end
    end
    associated_dynamic_models.all.each do |a|
      a.option_configs.each do |c|
        c.dialog_before.each do |d, v|
          res = Admin::MessageTemplate.active.where(name: v[:name], message_type: 'dialog', template_type: 'content').first
          ms << res
        end
      end
    end
    ms.sort {|a, b| a.id <=> b.id}
  end


  def export_config
    JSON.pretty_generate(JSON.parse self.to_json)
  end

  def as_json options={}

    options[:root] = true
    options[:methods] ||= []
    options[:include] ||= {}

    options[:methods] << :app_configurations
    options[:methods] << :user_access_controls
    options[:methods] << :associated_activity_logs
    options[:methods] << :associated_dynamic_models
    options[:methods] << :associated_external_identifiers
    options[:methods] << :associated_reports
    options[:methods] << :associated_general_selections
    options[:methods] << :page_layouts
    options[:methods] << :user_roles
    options[:methods] << :associated_message_templates
    options[:methods] << :associated_protocols
    options[:methods] << :associated_sub_processes
    options[:methods] << :associated_protocol_events

    super(options)
  end

  private

    def set_access_levels
      if !persisted? || self.user_access_controls.length == 0
        Admin::UserAccessControl.create_all_for self, current_admin
        return true
      end
    end

end
