module Dynamic
  #
  # Handle the config_trigger options, which if defined are run when dynamic definitions are saved
  class DefConfigTriggers
    attr_accessor :dynamic_def, :dynamic_def_type, :current_admin, :admin_matching_user, :option_configs, :category,
                  :app_type, :app_type_name, :default_role_name, :role_name, :access, :common_subname

    def initialize(dynamic_def)
      self.dynamic_def = dynamic_def
      self.dynamic_def_type = dynamic_def.class.name.underscore.to_sym
      self.current_admin = dynamic_def.current_admin
      self.admin_matching_user = current_admin.matching_user&.id
      self.option_configs = dynamic_def.option_configs
      self.category = dynamic_def.category
      self.app_type = current_admin.matching_user_app_type
      self.app_type_name = app_type&.name&.downcase
      self.common_subname = (category || app_type_name || 'app').downcase
      self.default_role_name = "user - #{common_subname}"

      unless admin_matching_user
        Rails.logger.warn "There is no admin matching user (#{current_admin&.email}) - will not add default configs to dynamic def #{dynamic_def.name}"
      end
      unless app_type
        Rails.logger.warn "There is no current app type - will not add default configs to dynamic def #{dynamic_def.name}"
      end

      nil
    end

    def self.process(dynamic_def)
      return if dynamic_def.disabled? || !dynamic_def.ready_to_generate?

      inst = new(dynamic_def)
      inst.handle_all_option_configs

      dynamic_def.force_option_config_parse
    end

    def handle_all_option_configs
      option_configs.each do |option_config|
        create_defaults(option_config)
        create_configs(option_config)
      end
    rescue StandardError => e
      Rails.logger.warn e
      Rails.logger.warn e.short_string_backtrace
      raise FphsException,
            "A failure occurred creating config for config trigger for: #{dynamic_def.model_association_name}.\n#{e}"
    end

    private

    def create_defaults(option_config)
      config_trigger = option_config&.config_trigger
      return unless config_trigger

      config = config_trigger.dig(:on_define, :create_defaults)
      return unless config

      setup config
      create_role_for_admin_matching_user(config, option_config)
      create_default_user_access_controls(config, option_config)
      create_default_embed(config, option_config)
      create_activity_log_page_layout(config, option_config)
    end

    def setup(config)
      uac = config[:user_access_control] || {}

      self.role_name = uac[:role_name] || default_role_name
      self.access = uac[:access] || :create
    end

    #
    # Create a role for the matching admin user only if the role hasn't already been created, even if it was disabled later.
    # The aim is to allow the admin to override the user role by disabling it if necessary
    def create_role_for_admin_matching_user(config, option_config)
      cond = { app_type_id: app_type.id,
               user_id: admin_matching_user,
               role_name: }
      exists = Admin::UserRole.find_by(cond)
      return if exists

      cond[:current_admin] = current_admin
      Admin::UserRole.create!(cond)
    end

    def create_default_user_access_controls(config, option_config)
      return unless config.has_key? :user_access_control

      resource_type = :table

      uac_cond = { role_name:,
                   app_type:,
                   resource_type:,
                   resource_name: dynamic_def.resource_name,
                   access: }
      create_missing_user_access_control(uac_cond)

      return unless dynamic_def_type == :activity_log

      uac_cond = { role_name:,
                   app_type:,
                   resource_type: :activity_log_type,
                   resource_name: option_config.resource_name,
                   access: }
      create_missing_user_access_control(uac_cond)
    end

    def create_default_embed(config, option_config)
      return unless config.has_key?(:embed) && dynamic_def_type == :activity_log

      # Create the corresponding dynamic model for embedding in the activity log
      embed = config[:embed].dup || {}
      allow_reconfiguration = embed.delete(:allow_reconfiguration)
      prefix_config_libraries = embed.delete(:prefix_config_libraries)
      prefix_config_libraries = [prefix_config_libraries] if prefix_config_libraries.is_a?(String)

      pl_text = ''
      prefix_config_libraries&.each do |pl|
        pl_text = "#{pl_text}\n# @library #{pl}"
      end

      options = <<~END_TEXT
        #{pl_text}
      END_TEXT

      return if option_config.name.in?(%w[primary blank_log])

      tname = dynamic_def.default_embed_table_name(option_config.name.downcase)

      fkey = dynamic_def.foreign_key_field_name
      schema_name = dynamic_def.schema_name

      emb_fields = "#{fkey} #{embed[:fields]&.join(' ')}"

      # Check for a match purely on the table and schema name
      emb_cond = {
        table_name: tname,
        schema_name:
      }

      exists = DynamicModel.find_by(table_name: tname)

      emb_cond.merge!(
        name: option_config.label,
        primary_key_name: :id,
        foreign_key_name: :master_id,
        category:,
        field_list: emb_fields,
        current_admin:
      )

      if exists
        return unless allow_reconfiguration

        # Update if reconfiguration is allowed and anything is specified in the embed config, otherwise skip
        emb_cond[:options] = options unless exists.options.present?
        exists.update!(emb_cond) unless embed.empty? || attributes_equal(exists, emb_cond)
      else
        exists = DynamicModel.create!(emb_cond)
      end

      uac_cond = { role_name:,
                   app_type:,
                   resource_type: :table,
                   resource_name: exists.resource_name,
                   access: }

      create_missing_user_access_control uac_cond
    end

    def create_activity_log_page_layout(config, option_config)
      return unless config.has_key?(:page_layout) && dynamic_def_type == :activity_log

      pl = config[:page_layout] || {}

      cond = {
        app_type_id: app_type.id,
        panel_name: common_subname.id_hyphenate,
        layout_name: 'master'
      }

      exist = Admin::PageLayout.find_by(cond)
      return if exist

      options_yaml = <<~END_YAML
        contains:
          resources:
          - #{dynamic_def.resource_name}

        view_options:
          initial_show: true
      END_YAML

      cond.merge!(
        panel_label: dynamic_def.name,
        options: options_yaml,
        panel_position: 100,
        current_admin:
      )

      Admin::PageLayout.create! cond
    end

    def create_configs(option_config)
      config_trigger = option_config&.config_trigger
      return unless config_trigger

      config = config_trigger.dig(:on_define, :create_configs)
      return nil unless config

      subdata = if dynamic_def_type == :activity_log
                  dynamic_def.implementation_class.new(
                    master: Settings.admin_master,
                    extra_log_type: option_config.name
                  )
                else
                  dynamic_def
                end

      config = config.transform_values do |cval|
        cval.map do |item|
          item.transform_values do |v|
            if v.is_a?(String) && v.include?('{{')
              Formatter::Substitution.substitute(v, data: subdata, tag_subs: nil)
            else
              v
            end
          end
        end
      end
      config = config.merge(name: app_type_name)
      at_config = { app_type: config }
      Admin::AppTypeImport.import_config(at_config,
                                         current_admin,
                                         format: :raw)
    end

    #
    # Create a missing user access control, ignoring the access type
    # so that we don't attempt to create duplicates that will fail validation.
    # If the access on an existing UAC needs to change, get the result from
    # this method then update access manually.
    # @param [Hash] uac_cond
    # @return [Admin::UserAccessControl]
    def create_missing_user_access_control(uac_cond)
      find_cond = uac_cond.except(:access, 'access')
      exists = Admin::UserAccessControl.active.find_by(find_cond)
      return if exists

      uac_cond[:current_admin] = current_admin
      newuac = Admin::UserAccessControl.create!(uac_cond)

      Admin::UserAccessControl.active.reload
      dynamic_def.class.active_model_configurations force_update: true
      newuac
    end

    def attributes_equal(instance, match_attr)
      sk_match_attr = match_attr.stringify_keys.transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
      sk_match_attr.delete('current_admin')
      instance.attributes.slice(*sk_match_attr.keys) == sk_match_attr
    end
  end
end
