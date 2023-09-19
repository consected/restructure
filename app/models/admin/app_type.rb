# frozen_string_literal: true

class Admin
  class AppType < Admin::AdminBase
    self.table_name = 'app_types'
    include AdminHandler
    include SelectorCache
    include AppTypeExport

    has_many :user_access_controls, -> { order id: :asc }, autosave: true, class_name: 'Admin::UserAccessControl'
    has_many :app_configurations, -> { order id: :asc }, autosave: true, class_name: 'Admin::AppConfiguration'
    has_many :page_layouts, -> { order id: :asc }, autosave: true, class_name: 'Admin::PageLayout'
    has_many :user_roles, -> { order id: :asc }, autosave: true, class_name: 'Admin::UserRole'
    has_many :role_descriptions, -> { order id: :asc }, autosave: true, class_name: 'Admin::RoleDescription'
    has_many :nfs_store_filters, -> { order id: :asc }, autosave: true, class_name: 'NfsStore::Filter::Filter'
    has_many :protocols, -> { order id: :asc }, autosave: true, class_name: 'Classification::Protocol'

    validates :name, presence: true
    validate :name_not_already_taken
    validates :label, presence: true

    after_create :add_template_access
    after_create :setup_migrations
    after_create :add_admin_user_access

    attr_accessor :associated_external_identifier_names,
                  :associated_activity_log_names,
                  :associated_dynamic_model_names

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
        Admin::AppType.active.where(id: olat).reload
      else
        active.reload
      end
    end

    def self.all_ids_available_to(user)
      return unless user

      Rails.cache.fetch("all_app_type_ids_available_to::#{user.id}") do
        all_available_to(user).map(&:id)
      end
    end

    def self.all_available_to(user)
      return unless user

      atavail = []
      olat = Settings::OnlyLoadAppTypes
      active.each do |a|
        hat = user.has_access_to?(:access, :general, :app_type, alt_app_type_id: a.id)
        atavail << hat.app_type if hat && (!olat || hat.app_type_id.in?(olat))
      end
      atavail.compact
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

    def active_on_server?
      self.class.active_app_types.include?(self) &&
        Admin::MigrationGenerator.current_search_paths.include?(default_schema_name)
    end

    def valid_user_access_controls
      user_access_controls.valid_resources.reorder('').order(id: :asc)
    end

    # Select any tables that have some kind of access
    def associated_table_names
      user_access_controls.valid_resources([:table]).where(resource_type: :table).select(&:access).map(&:resource_name).uniq
    end

    def valid_associated_activity_logs
      associated_activity_logs valid_resources_only: true
    end

    # Select activity logs that have some kind of access, typically scoped to a specific app type
    # @return [ActiveRecord::Relation]
    def associated_activity_logs(valid_resources_only: false, not_resource_names: nil)
      nrn = not_resource_names

      uacs = if valid_resources_only
               user_access_controls.valid_resources([:table])
             else
               user_access_controls.active
             end

      get_names =
        uacs.where(resource_type: :table)
            .select { |a| a.access && a.resource_name.start_with?('activity_log__') && (nrn.nil? || !a.resource_name.in?(nrn)) }
      names = get_names.map { |n| n.resource_name.singularize.sub('activity_log__', '') }.uniq
      names += get_names.map { |n| n.resource_name.sub('activity_log__', '') }.uniq
      self.associated_activity_log_names = names

      ActivityLog.active.where("
        (rec_type is NULL OR rec_type = '') AND (process_name IS NULL OR process_name = '') AND item_type in (?)
    OR (process_name IS NULL OR process_name = '') AND (item_type || '_' || rec_type) in (?)
    OR (rec_type IS NULL OR rec_type = '') AND (item_type || '_' || process_name) in (?)
    ", names, names, names).reorder('').order(id: :asc)
    end

    def associated_dynamic_models(valid_resources_only: true, not_resource_names: nil)
      nrn = not_resource_names

      uacs = if valid_resources_only
               user_access_controls.valid_resources([:table])
             else
               user_access_controls.active
             end

      self.associated_dynamic_model_names =
        uacs.where(resource_type: :table)
            .select { |a| a.access && a.resource_name.start_with?('dynamic_model__') && (nrn.nil? || !a.resource_name.in?(nrn)) }
            .map { |n| n.resource_name.sub('dynamic_model__', '') }
            .uniq

      DynamicModel.active.where(table_name: associated_dynamic_model_names).reorder('').order(id: :asc)
    end

    #
    # Get external identifiers that are active and associated with this app type
    # though user access controls being assigned to them
    # @return [ActiveRecord::Relation] external identifiers returned
    def associated_external_identifiers(not_resource_names: nil)
      nrn = not_resource_names
      eids = ExternalIdentifier.active.pluck(:name)

      self.associated_external_identifier_names =
        user_access_controls
        .valid_resources([:table])
        .where(resource_type: :table)
        .select { |a| a.access && a.resource_name.in?(eids) && (nrn.nil? || !a.resource_name.in?(nrn)) }
        .map(&:resource_name)
        .uniq

      ExternalIdentifier.active.where(name: associated_external_identifier_names).reorder('').order(id: :asc)
    end

    def associated_reports
      names = user_access_controls
              .valid_resources([:report]).where(resource_type: :report)
              .where("access IS NOT NULL and access <> ''")
              .map(&:resource_name)
              .uniq
      names = Report.active.map(&:alt_resource_name).uniq if names.include? '_all_reports_'

      Report.active.where("(REGEXP_REPLACE(item_type, '( |-)', '_', 'g') || '__' || short_name) in (?)",
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

      Classification::ItemFlagName
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
                  .find_by(
                    name: v[:name],
                    message_type: 'dialog',
                    template_type: 'content'
                  )
            ms << res if res
          end
          c.save_trigger.each do |_d, st|
            ns = st[:notify] || []
            ns = [ns] if ns.is_a? Hash

            ns.each do |v|
              lt = v[:layout_template]
              ct = v[:content_template]
              mt = v[:type]

              res = Admin::MessageTemplate.active.find_by(name: lt, message_type: mt, template_type: 'layout')
              ms << res if res
              res = Admin::MessageTemplate.active.find_by(name: ct, message_type: mt, template_type: 'content')
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
                  .find_by(
                    name: v[:name],
                    message_type: 'dialog',
                    template_type: 'content'
                  )
            ms << res if res
          end
        end
      end

      Admin::MessageTemplate
        .active
        .where(
          name: ["ui page css - #{name}", "ui page js - #{name}"],
          message_type: 'plain',
          template_type: 'content'
        )
        .each do |res|
        ms << res if res
      end

      ms.compact!
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

    def add_template_access
      Admin::UserAccessControl.create!(role_name: Settings::AppTemplateRole, app_type: self,
                                       resource_type: :general, resource_name: :app_type,
                                       access: :read,
                                       user: User.template_user, current_admin: current_admin)
    end

    def setup_migrations
      return true unless Settings::AllowDynamicMigrations

      return true if self.class.active.where(default_schema_name: default_schema_name).count > 1

      migration_generator = Admin::MigrationGenerator.new(default_schema_name)
      migration_generator.add_schema
    end

    #
    # Immediately after creating an app type, add an explicit user access control
    # for the  admin's matching user
    def add_admin_user_access
      user = current_admin.matching_user
      return true unless user

      Admin::UserAccessControl.create app_type: self,
                                      access: :read,
                                      resource_type: :general,
                                      resource_name: :app_type,
                                      user: user,
                                      current_admin: current_admin
    end
  end
end
