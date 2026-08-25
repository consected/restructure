# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the notify save trigger.
    # Direct-config pattern: config is a Hash of notification keys, or an Array
    # of such Hashes for multiple notifications.
    # Runtime: SaveTriggers::Notify wraps a single Hash into an array and iterates
    # direct config hashes; it does not use an outer named-entry label.
    class Notify < Base
      trigger_name :notify
      pattern :direct_config
      allowed_keys %i[
        type role users emails phones phone_records list_type default_country_code
        from_user_email ignore_no_recipients layout_template content_template
        content_template_text subject calendar_invite attachments extra_substitutions
        importance when on_complete on_failure if app_type user
      ]
      standard_hook_key_types
      # app_type/user accept a literal id/name, a {{substitution}}, or a conditional
      # Hash reference (e.g. {this: {field: return_value}}) - resolved via
      # FieldDefaults before being passed to the id/name lookups (see
      # SaveTriggers::Notify#init_attribs and #resolve_app_type).
      key_type :string_or_integer_or_hash, :app_type, :user
      key_type :string_or_hash, :type, :list_type, :default_country_code, :layout_template,
               :content_template, :content_template_text, :subject, :importance
      key_type :scalar_or_array_or_hash, :role, :users, :emails, :phones, :phone_records
      key_type :hash, :from_user_email, :calendar_invite, :extra_substitutions, :when
      key_type :array, :attachments
      key_type :boolean, :ignore_no_recipients

      class << self
        # Validate a config hash (or array of config hashes) including semantic checks.
        # @param config [Hash, Array, Object] the trigger's configuration
        # @return [Array<String>]
        def validate_config(config)
          return config.flat_map { |entry| validate_config(entry) } if config.is_a?(Array)
          return [] unless config.is_a?(Hash)

          warnings = validate_structural_config(config)
          warnings.concat(semantic_warnings(config))
          warnings
        end

        private

        def semantic_warnings(config)
          hash = config.transform_keys(&:to_sym)
          warnings = []

          check_type_semantics(hash, warnings)
          check_importance_semantics(hash, warnings)
          check_subject_semantics(hash, warnings)
          check_layout_template_semantics(hash, warnings)
          check_content_template_semantics(hash, warnings)
          check_role_semantics(hash, warnings)
          check_users_semantics(hash, warnings)
          check_app_type_semantics(hash, warnings)
          check_user_semantics(hash, warnings)

          warnings
        end

        def check_type_semantics(hash, warnings)
          if hash[:type].nil?
            warnings << 'type is required'
          elsif literal_string?(hash[:type])
            type_val = hash[:type].to_s.downcase
            valid_types = Messaging::MessageNotification::ValidMessageTypes
            unless valid_types.include?(type_val)
              warnings << "type '#{hash[:type]}' must be one of: #{valid_types.join(', ')}"
            end
          end
        end

        def check_importance_semantics(hash, warnings)
          return unless hash.key?(:importance) && !hash[:importance].nil?
          return unless literal_string?(hash[:importance])

          imp_val = hash[:importance].to_s.capitalize
          valid_imp = Messaging::MessageNotification::ValidImportance
          return if valid_imp.include?(imp_val)

          warnings << "importance '#{hash[:importance]}' must be one of: #{valid_imp.join(', ')}"
        end

        def check_subject_semantics(hash, warnings)
          return unless literal_string?(hash[:type]) && hash[:type].to_s.downcase == 'email'
          if hash.key?(:subject) && !hash[:subject].nil? && (hash[:subject].is_a?(Hash) || hash[:subject].to_s.present?)
            return
          end

          warnings << 'subject is required when type is email'
        end

        def check_layout_template_semantics(hash, warnings)
          if hash[:layout_template].blank?
            warnings << 'layout_template is required'
          elsif literal_string?(hash[:layout_template])
            msg_type = literal_message_type(hash)
            tmpl = find_layout_template(hash[:layout_template], type: msg_type)
            unless tmpl
              msg = "layout_template '#{hash[:layout_template]}' not found"
              msg += " for #{msg_type}" if msg_type
              warnings << msg
            end
          end
        end

        def check_content_template_semantics(hash, warnings)
          if hash[:content_template].blank? && hash[:content_template_text].blank?
            warnings << 'content_template or content_template_text is required'
          elsif hash[:content_template].present? && literal_string?(hash[:content_template])
            msg_type = literal_message_type(hash)
            tmpl = find_content_template(hash[:content_template], type: msg_type)
            unless tmpl
              msg = "content_template '#{hash[:content_template]}' not found"
              msg += " for #{msg_type}" if msg_type
              warnings << msg
            end
          end
        end

        def check_role_semantics(hash, warnings)
          roles = literal_values(hash[:role]).select { |val| literal_string?(val) }
          return if roles.empty?

          active_role_names = active_role_names_for_validation(app_type: role_app_type(hash))
          roles.each do |role|
            next if active_role_names.include?(role.to_s)

            warnings << "role '#{role}' is not a known active role"
          end
        end

        def check_users_semantics(hash, warnings)
          user_ids = literal_values(hash[:users]).filter_map do |val|
            next unless val.is_a?(Integer) || (literal_string?(val) && val.to_s.match?(/\A-?\d+\z/))

            val.to_i
          end
          return if user_ids.empty?

          user_ids.each do |user_id|
            warnings.concat(validate_user_ref(user_id, 'users'))
          end
        end

        def check_app_type_semantics(hash, warnings)
          warnings.concat(validate_app_type_ref(hash[:app_type], 'app_type'))
        end

        def check_user_semantics(hash, warnings)
          warnings.concat(validate_user_ref(hash[:user], 'user'))
        end

        def literal_values(val)
          return [] if val.nil? || val.is_a?(Hash)

          values = val.is_a?(Array) ? val : [val]
          values.grep_v(Hash)
        end

        def active_role_names_for_validation(app_type: nil)
          return [] if app_type == false

          Admin::UserRole.active_role_names(app_type && { app_type: })
        rescue ActiveRecord::StatementInvalid
          []
        end

        def role_app_type(hash)
          app_type = hash[:app_type]
          return unless app_type.is_a?(Integer) || literal_string?(app_type)

          Admin::AppType.find_active_by_name_or_id(app_type, only_active_on_server: true) || false
        rescue ActiveRecord::RecordNotFound
          false
        end

        def literal_string?(val)
          (val.is_a?(String) || val.is_a?(Symbol)) && !val.to_s.include?('{{')
        end

        # The literal, valid message type from config[:type], or nil if it's a
        # template/conditional value or not a recognized type (can't narrow the lookup).
        def literal_message_type(hash)
          return unless literal_string?(hash[:type])

          type_val = hash[:type].to_s.downcase
          type_val if Messaging::MessageNotification::ValidMessageTypes.include?(type_val)
        end

        def find_layout_template(name, type: nil)
          Admin::MessageTemplate.active.layout_templates.named(name, type:)
        rescue ActiveRecord::StatementInvalid
          nil
        end

        def find_content_template(name, type: nil)
          Admin::MessageTemplate.active.content_templates.named(name, type:)
        rescue ActiveRecord::StatementInvalid
          nil
        end
      end
    end
  end
end
