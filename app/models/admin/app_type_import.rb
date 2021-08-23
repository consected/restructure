# frozen_string_literal: true

module Admin::AppTypeImport
  extend ActiveSupport::Concern

  included do
    attr_accessor :import_results
  end

  class_methods do
    def import_config(config_json, admin, name: nil, force_disable: false, format: :json)
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
        a_conf = app_type_config.slice('name', 'label', 'default_schema_name')

        # override the name if specified
        a_conf[:current_admin] = admin
        a_conf['name'] = name if name

        app_type = find_or_create_with_config(a_conf)

        # set the app type to allow automatic migrations to work
        admin.matching_user_app_type = app_type
        app_type.setup_migrations

        res = results['app_type']

        force_report_short_names

        res['app_configurations'] =
          app_type.import_config_sub_items app_type_config, 'app_configurations', %w[name role_name]

        # Make two passes at loading general selections, the first time
        # rejecting dynamic items that may not yet be defined
        reject_items = proc { |k, v|
          k == :item_type && v.index(/^(activity_log__|dynamic_model__|external_identifier__)/)
        }
        res['associated_general_selections'] =
          app_type.import_config_sub_items app_type_config, 'associated_general_selections', %w[item_type value],
                                           reject: reject_items

        res['associated_config_libraries'] =
          app_type.import_config_sub_items app_type_config, 'associated_config_libraries', %w[name category format]

        res['associated_dynamic_models'] =
          app_type.import_config_sub_items app_type_config, 'associated_dynamic_models', ['table_name'],
                                           create_disabled: force_disable

        res['associated_external_identifiers'] =
          app_type.import_config_sub_items app_type_config, 'associated_external_identifiers', ['name'],
                                           create_disabled: force_disable

        res['associated_activity_logs'] =
          app_type.import_config_sub_items app_type_config, 'valid_associated_activity_logs',
                                           %w[item_type rec_type process_name], create_disabled: force_disable

        res['associated_general_selections'] =
          app_type.import_config_sub_items app_type_config, 'associated_general_selections', %w[item_type value]

        res['associated_reports'] =
          app_type.import_config_sub_items app_type_config, 'associated_reports', %w[short_name item_type]

        res['page_layouts'] =
          app_type.import_config_sub_items app_type_config, 'page_layouts', %w[layout_name panel_name]

        res['user_roles'] =
          app_type.import_config_sub_items app_type_config, 'user_roles', ['role_name', 'role_template']

        res['role_descriptions'] =
          app_type.import_config_sub_items app_type_config, 'role_descriptions', ['role_name']

        res['nfs_store_filters'] =
          app_type.import_config_sub_items app_type_config, 'nfs_store_filters', %w[role_name resource_name filter]

        res['associated_message_templates'] =
          app_type.import_config_sub_items app_type_config, 'associated_message_templates',
                                           %w[name message_type template_type]

        res['associated_protocols'] =
          app_type.import_config_sub_items app_type_config, 'associated_protocols', ['name']

        # Earlier versions exported all protocols, not just those associated with an app. Attempt to load this as well
        res['protocols'] = app_type.import_config_sub_items app_type_config, 'protocols', ['name']

        res['associated_sub_processes'] =
          app_type.import_config_sub_items app_type_config, 'associated_sub_processes', ['name'],
                                           filter_on: ['protocol_name']

        res['associated_protocol_events'] =
          app_type.import_config_sub_items app_type_config, 'associated_protocol_events', ['name'],
                                           filter_on: %w[sub_process_name protocol_name]

        res['user_access_controls'] =
          app_type.import_config_sub_items app_type_config, 'valid_user_access_controls',
                                           %w[resource_type resource_name role_name],
                                           add_vals: { allow_bad_resource_name: true },
                                           id_list: id_list

        app_type.reload
        new_id = app_type.id

        # Reset the app type to allow the actual value to be used
        admin.matching_user_app_type = nil
      end

      app_type = find(new_id)
      # Ensure only imported user access controls are retained
      app_type.clean_user_access_controls id_list
      app_type.reload

      [app_type, results]
    end

    ### Force update of reports that don't have a short_name (yet)
    def force_report_short_names
      rs = Report.active.where(short_name: nil)
      rs.each do |r|
        r.current_admin = admin
        r.gen_short_name
        r.save!
      end
    end

    # Find or create an app type based on a configuration,
    # matching on the name
    def find_or_create_with_config(a_conf)
      Admin::AppType.where(name: a_conf['name']).first || Admin::AppType.create!(a_conf)
    end
  end

  #
  # Handles filtering of a list of items (either an association scope or direct query scope)
  # if #import_config_sub_items specified *filter_on*
  # This receives the attributes from the current sub item definition as the filter,
  # simply looking within all the possible items passed in to limit the set
  # @param [ActiveRecord::Relation | Array] items - the scope or array to filter
  # @param [Hash] filter - key / value to filter items with
  # @return [Array] filtered items
  def filtered_results(items, filter)
    items.select do |item|
      res = true
      filter.each { |fk, fv| res &&= (item.send(fk.to_s) == fv) }
      res
    end
  end

  #
  # Import sub items related to the app type. These are all the components that make up an app.
  # Importing will create items that do not yet exist, or update items if they are newer than the existing item.
  # There are two categories of sub items: directly assoicated and not directly associated
  # - directly associated: have an app_type_id specifying absolute ownership by the app through an association
  # - not directly associated: are only related to the app loosely, typically through the presence of user
  #                            access controls referencing the item in the app
  #
  # @param [Hash] app_type_config - the full app type configuration to import the sub item from
  # @param [String] name - the key name from the configuration to import
  # @param [Array{String}] lookup_existing_with_fields - list of fields used to identify if a sub item already exists
  # @param [Proc | nil] reject - optional proc accepting |key, value| arguments that allows items in the
  #                              configuration to be rejected during the import. This allows a sub item of
  #                              to import a subset of its configuration at one stage and the remainder later
  # @param [Hash] add_vals - a hash representing attribute / values to add to every imported item
  # @param [Boolean] create_disabled - force the item to be created with disabled: true
  #                                    (has no effect on update of existing items)
  # @param [Array[String]] filter_on - list fields to compare between new and existing items to identify matches
  # @param [Array] id_list - pass (by reference) an empty array which ids of new or updated items will be added to
  # @return [Array{Object}] returns an array of the objects representing new and updated sub items
  def import_config_sub_items(app_type_config, name, lookup_existing_with_fields, reject: nil, add_vals: {}, create_disabled: false, filter_on: nil, id_list: [])
    results = []
    orig_name = name
    name = name.gsub(/^valid_/, '')

    not_directly_associated = true if name.starts_with? 'associated_'

    # Ensure a clean cache to reload previous items
    Rails.cache.clear

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
            User.create(email: ac['user_email'], first_name: 'template', last_name: 'template',
                        current_admin: admin)
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
          new_vals['disabled'] = true if i.respond_to?(:ready_to_generate?) && !i.ready_to_generate?
          new_vals.delete 'id'
          new_vals.delete :id
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

  # Clean up user access controls that are not in the id_list
  # by disabling them.
  # Typically this is done after an import, ensuring that only the
  # imported user access controls are retained, and others that were
  # previously present are disabled.
  def clean_user_access_controls(id_list)
    inv = user_access_controls.active.pluck(:id) - id_list

    inv.each do |i|
      el = Admin::UserAccessControl.find(i)
      res = el.disable! admin
      Rails.logger.info "Failed to clean up bad resource UAC: #{i}. #{el.errors.first}" unless res
    end

    valid_user_access_controls.where(resource_type: :report).each do |u|
      rn = u.resource_name
      next unless rn.present?

      unless rn.include?('_')
        u.update resource_name: Report.resource_name_for_named_report(rn),
                 current_admin: admin
      end
    end
  end
end
