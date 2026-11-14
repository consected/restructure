# frozen_string_literal: true

module MasterTemplates
  # Fingerprint of everything baked into the cached masters template skeleton (issue #1481).
  # Shared by the skeleton fragment cache key and the prewarm warm marker so both follow
  # structural changes only; config edits are delivered lazily as template_config, except the
  # values that are rendered into the skeleton markup (see the activity log inputs below).
  #
  # Memoization is per instance: build one per view context or per prewarm pass, never share
  # an instance across requests.
  class SkeletonSignature
    # Activity log columns rendered into the skeleton by activity_logs/_unversioned_handlebars_templates:
    # the main and blank log button labels, the item list panel visibility (which also sets the
    # width classes) and the sort attribute of the activity log list
    ACTIVITY_LOG_SKELETON_COLUMNS = %i[
      item_type rec_type main_log_name blank_log_name hide_item_list_panel action_when_attribute
    ].freeze

    # @param app_type_id [Integer, nil]
    # @return [String] hex digest of the structural state for the app type
    def signature(app_type_id:)
      @signatures ||= {}
      @signatures[app_type_id] ||= compute_signature(app_type_id)
    end

    # @param user_or_admin [User, Admin, nil] the signed in (or forced) user or admin
    # @param paired_user [User, nil] the effective user, which provides the app type
    # @return [String] hex digest scoping the signature to the user and app type
    def cache_key(user_or_admin:, paired_user:)
      app_type_id = paired_user&.app_type_id
      scope = [user_or_admin&.class&.name, user_or_admin&.id, app_type_id, paired_user&.id]
      Digest::SHA256.hexdigest([signature(app_type_id:), *scope].to_json)
    end

    def definition_structure(definition)
      @definition_structures ||= {}
      cached_definition = if definition.class.respond_to?(:definition_cache)
                            definition.class.definition_cache[definition.id]
                          end
      definition = cached_definition if cached_definition && cached_definition.updated_at == definition.updated_at
      key = [definition.class.name, definition.id, definition.updated_at&.to_f,
             Dynamic::TemplateVersionTokens.resource_token(definition)]
      @definition_structures[key] ||= build_definition_structure(definition)
    end

    private

    def compute_signature(app_type_id)
      Digest::SHA256.hexdigest([
        Application.server_cache_version,
        Settings::OnlyLoadAppTypes,
        app_type_id,
        definition_sets,
        matching_panels(app_type_id),
        *HandlebarsPrecompiler.app_type_access_control_timestamps(app_type_id),
        Dynamic::TemplateVersionTokens.panel_chrome_token
      ].to_json)
    end

    def definition_sets
      [DynamicModel, ActivityLog, ExternalIdentifier].map do |definition_class|
        columns = definition_columns(definition_class)
        definitions = definition_class.active.reorder(:id).to_a
        [definition_class.name, definitions.map do |definition|
          [columns.map { |column| definition.public_send(column) }, definition_structure(definition)]
        end]
      end
    end

    def definition_columns(definition_class)
      resource_name_column = %i[table_name name].find do |column|
        column == :name || definition_class.column_names.include?(column.to_s)
      end
      columns = [:id, :name, resource_name_column].compact.uniq
      columns << :category if definition_class.column_names.include?('category')
      # Position orders the dynamic model blocks baked into the master panels
      columns << :position if definition_class.column_names.include?('position')
      columns += ACTIVITY_LOG_SKELETON_COLUMNS if definition_class == ActivityLog
      columns
    end

    def matching_panels(app_type_id)
      Admin::PageLayout.active
                       .where(app_type_id: [app_type_id, nil], layout_name: 'master')
                       .order(Arel.sql('app_type_id ASC NULLS LAST, panel_position ASC, id ASC'))
                       .pluck(:id, :app_type_id, :panel_name, :disabled)
    end

    def build_definition_structure(definition)
      option_configs = Array(definition.option_configs)
      activity_log = definition.is_a?(ActivityLog)
      structure = option_configs.map do |option_config|
        embed = option_config.embed
        embed = embed.except(:resource_model_def) if embed.is_a?(Hash)
        digest_inputs = {
          references: option_config.references,
          embed:,
          reference_caption_before: reference_caption_before(option_config)
        }
        digest_inputs[:activity_log_skeleton] = activity_log_option_skeleton(option_config) if activity_log
        [option_config.name.to_s, Digest::SHA256.hexdigest(digest_inputs.to_json)]
      end
      structure << ['activity_log_tab_caption', definition.configurations&.dig(:tab_caption)] if activity_log
      structure << ['alt_width_classes', alt_width_classes(definition, option_configs)]
      structure
    end

    # Only the reference_* captions are rendered into the reference action templates.
    def reference_caption_before(option_config)
      option_config.caption_before.as_json&.select { |key, _| key.to_s.start_with?('reference_') }
    end

    # The option type values that activity_logs/_unversioned_handlebars_templates renders into the
    # skeleton. The primary and blank log buttons take their labels from the definition's
    # main_log_name and blank_log_name, so only the other option types bake in a button label,
    # a width class (alt_width_classes, or e_sign) and the element for the button.
    def activity_log_option_skeleton(option_config)
      view_options = option_config.view_options || {}
      baked = { hide_unless_creatable: view_options[:hide_unless_creatable] }
      return baked if %i[primary blank_log].include?(option_config.name)

      baked.merge(
        button_label: option_config.button_label || option_config.label,
        e_sign: option_config.e_sign.present?,
        alt_width_classes: view_options[:alt_width_classes]
      )
    end

    # Baked into the dynamic model and external identifier containers of the master panels.
    # Activity logs bake their width classes in per option type (see #activity_log_option_skeleton),
    # not for the default option type.
    def alt_width_classes(definition, option_configs)
      return if definition.is_a?(ActivityLog)

      default_name = definition.default_option_type_name.to_s.underscore.to_sym
      option_configs.find { |option_config| option_config.name == default_name }
                    &.view_options&.dig(:alt_width_classes)
    end
  end
end
