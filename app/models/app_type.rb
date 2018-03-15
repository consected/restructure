class AppType < ActiveRecord::Base
  include AdminHandler
  include SelectorCache

  has_many :user_access_controls, autosave: true
  has_many :app_configurations, autosave: true

  validates :name, presence: true
  validates :label, presence: true
  after_save :set_access_levels

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

  def self.import_config config_json, admin, name: nil

    config = JSON.parse(config_json)


    app_type_config = config['app_type']
    raise FphsException.new "Incorrect format for configuration JSON" unless app_type_config

    AppType.transaction do
      a_conf = app_type_config.slice('name', 'label')

      # override the name if specified
      a_conf[:current_admin] = admin

      a_conf['name'] = name if name


      app_type = AppType.where(name: a_conf['name']).first || AppType.create!(a_conf)

      results = {'app_type' => {}}

      res = results['app_type']


      res['app_configurations'] = app_type.import_config_sub_items app_type_config, 'app_configurations', ['name']

      res['associated_dynamic_models'] = app_type.import_config_sub_items app_type_config, 'associated_dynamic_models', ['table_name'], create_disabled: true
      res['associated_external_identifiers'] = app_type.import_config_sub_items app_type_config, 'associated_external_identifiers', ['name'], create_disabled: true
      res['associated_activity_logs'] = app_type.import_config_sub_items app_type_config, 'associated_activity_logs', ['item_type', 'rec_type'], create_disabled: true

      res['associated_general_selections'] = app_type.import_config_sub_items app_type_config, 'associated_general_selections', ['item_type', 'value']
      res['associated_reports'] = app_type.import_config_sub_items app_type_config, 'associated_reports', ['name']

      app_type.user_access_controls.active.each do |a|
        a.update!(access: nil, current_admin: admin)
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
      cname = name.sub('associated_', '').classify.constantize
    else
      parent = self
      assoc_name = name
    end

    acs = app_type_config[name]
    acs = acs.reject(&reject) if reject
    acs.each do |ac|
      el = nil

      unless ac['disabled']
        # Get the item if it has been set up automatically
        cond = ac.slice(*lookup_existing_with_fields)
        new_vals = ac.except('user_email', 'user_id', 'app_type_id', 'admin_id', 'id', 'created_at', 'updated_at')
        new_vals[:current_admin] = admin

        if parent
          cond[:user] = user = self.class.user_from_email ac['user_email']
          unless user == :unknown
            # Use the app type's admin as the current admin
            new_vals[:user] = user
            new_vals.merge! add_vals
            i = parent.send(assoc_name).active.where(cond).first

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
          i = cname.active.where(cond).first

          if i
            el = i
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
    ActivityLog.active.where("((rec_type is null or rec_type = '') and item_type in (?)) or ((item_type || '_' || rec_type) in (?))", names, names)
  end

  def associated_dynamic_models
    names = user_access_controls.active.where(resource_type: :table).select {|a| a.access && a.resource_name.start_with?( 'dynamic_model__')}.map{|n| n.resource_name.sub('dynamic_model__', '')}.uniq
    DynamicModel.active.where(table_name: names)
  end

  def associated_external_identifiers
    eids = ExternalIdentifier.active.map(&:name)
    names = user_access_controls.active.where(resource_type: :table).select {|a| a.access && a.resource_name.in?(eids)}.map(&:resource_name).uniq
    ExternalIdentifier.active.where(name: names)
  end

  def associated_reports
    names = user_access_controls.active.where(resource_type: :report).select {|a| a.access }.map(&:resource_name).uniq
    Report.active.where(name: names)
  end

  def associated_general_selections
    gs = []

    associated_table_names.each do |tn|
      tnlike = "#{tn.singularize}_%"
      tnplurallike = "#{tn}_%"
      res = GeneralSelection.active.where("item_type LIKE ? or item_type LIKE ?", tnlike, tnplurallike)
      gs += res
    end

    gs
  end


  def export_config
    self.to_json
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

    super(options)
  end

  private

    def set_access_levels
      if !persisted? || self.user_access_controls.length == 0
        UserAccessControl.create_all_for self, current_admin
        return true
      end
    end

end
