# frozen_string_literal: true

class Admin
  class AppTypeImport
    attr_accessor :import_results, :admin, :app_type,
                  :config_text, :format, :force_update,
                  :dry_run, :name, :skip_fail,
                  :dyn_cname,
                  :id_list, :found_with_conditions,
                  :config_item, :import_failures,
                  :current_key, :new_id

    #
    # Import an app type configuration from a yaml or json file
    # @param [String] config_text - YAML or JSON text
    # @param [Admin] admin - admin profile performing import
    # @param [String] name - optionally override the name of the app type at import
    # @param [Symbol] format - :json (default) or :yaml
    # @param [:force|:changed|nil] force_update - optionally force updated configuration items to current timestamp
    #                                  allowing previously failed imports to be overwritten
    #                                  or set to :changed to update changes, regardless of updated_at timestamp
    # @param [true|nil] dry_run - optionally run the import as a dry run, rolling back any database changes at the
    #                             end. A restart of the server should be forced to ensure consistency of state and DB
    # @return [Array] an array on [app_type, results]
    def self.import_config(config_text, admin,
                           name: nil, format: :json, force_update: nil, dry_run: nil, skip_fail: nil)

      importer = new(config_text, admin,
                     name: name,
                     format: format,
                     force_update: force_update,
                     dry_run: dry_run,
                     skip_fail: skip_fail)

      importer.do_import_config
    rescue StandardError, FphsException => e
      [importer, e]
    end

    #
    # Make a cleaner set of exception message and backtrace strings for display
    # @param [Exception] exception
    # @return [Hash]
    def self.clean_exception(exception)
      {
        'message' => exception.short_string_message,
        'backtrace' => exception.short_string_backtrace
      }
    end

    def initialize(config_text, admin, name: nil, format: :json, force_update: nil, dry_run: nil, skip_fail: nil)
      self.admin = admin
      self.config_text = config_text
      self.format = format
      self.force_update = force_update
      self.dry_run = dry_run
      self.name = name
      self.skip_fail = skip_fail
    end

    def do_import_config
      AppControl.define_models

      self.new_id = nil
      self.import_results = {}
      self.import_failures = {}
      results = { 'failures' => import_failures, 'updates / creations' => import_results }

      begin
        if skip_fail
          import_set
        else
          Admin::AppType.transaction do
            import_set
          end
        end
      rescue ActiveRecord::Rollback
        # Skip rollback
      end

      app_type = Admin::AppType.find(new_id) if new_id
      results.delete 'failures' if import_failures.empty? || !skip_fail

      # Ensure only imported user access controls are retained
      # if the valid_user_access_controls key was actually in the imported file.
      # If it wasn't present, the result was nil and we should skip this, since it
      # indicates we don't want to make any changes
      clean_user_access_controls if import_results['user_access_controls']
      app_type&.reload

      [app_type, results]
    end

    def import_set
      a_conf = app_type_config.slice('name', 'label', 'default_schema_name')

      # override the name if specified
      a_conf[:current_admin] = admin
      a_conf['name'] = name if name

      dsn = a_conf['default_schema_name']
      unless dsn.nil? || Admin::MigrationGenerator.current_search_paths&.include?(dsn)
        raise FphsException, 'Import of the app requires the FPHS_POSTGRESQL_SCHEMA environment variable ' \
                             "to include the default schema name of the app: #{dsn}"
      end

      self.app_type = find_or_create_with_config(a_conf)

      # set the app type to allow automatic migrations to work
      admin.matching_user_app_type = app_type
      app_type.setup_migrations
      force_report_short_names

      import_config_sub_items 'app_configurations', %w[name role_name]

      # Make two passes at loading general selections, the first time
      # rejecting dynamic items that may not yet be defined
      reject_items = proc { |k, v|
        k == :item_type && v.index(/^(activity_log__|dynamic_model__|external_identifier__)/)
      }
      import_config_sub_items 'associated_general_selections', %w[item_type value],
                              reject: reject_items

      import_config_sub_items 'associated_config_libraries', %w[name category format]

      import_config_sub_items 'associated_external_identifiers', ['name']

      import_config_sub_items 'associated_dynamic_models', ['table_name']

      import_config_sub_items 'valid_associated_activity_logs',
                              %w[item_type rec_type process_name]

      import_config_sub_items 'associated_general_selections', %w[item_type value]

      import_config_sub_items 'associated_reports', %w[short_name item_type]

      import_config_sub_items 'page_layouts', %w[layout_name panel_name]

      import_config_sub_items 'user_roles', ['role_name']

      import_config_sub_items 'role_descriptions', ['role_name', 'role_template']

      import_config_sub_items 'nfs_store_filters', %w[role_name resource_name filter]

      import_config_sub_items 'associated_message_templates',
                              %w[name message_type template_type]

      import_config_sub_items 'associated_protocols', ['name']

      import_config_sub_items 'protocols', ['name']

      import_config_sub_items 'associated_sub_processes', ['name'],
                              filter_on: ['protocol_name']

      import_config_sub_items 'associated_protocol_events', ['name'],
                              filter_on: %w[sub_process_name protocol_name]

      self.id_list = []

      import_config_sub_items 'valid_user_access_controls',
                              %w[resource_type resource_name role_name],
                              add_vals: { allow_bad_resource_name: true }

      app_type.reload
      self.new_id = app_type.id

      # Reset the app type to allow the actual value to be used
      admin.matching_user_app_type = nil

      # Rollback if a dry run was requested
      raise ActiveRecord::Rollback if dry_run

      new_id
    end

    #
    # Parse the configuration text
    # @return [Hash]
    def app_type_config
      return @app_type_config if @app_type_config

      if format == :json
        config = JSON.parse(config_text)
      elsif format == :yaml
        config = YAML.safe_load(config_text)
      else
        raise FphsException, 'specify app type import format as one of :json or :yaml'
      end

      @app_type_config = config['app_type']
      raise FphsException, "Incorrect format for configuration format #{format}" unless @app_type_config

      @app_type_config
    end

    #
    # Force update of reports that don't have a short_name (yet)
    def force_report_short_names
      rs = Report.active.where(short_name: nil)
      rs.each do |r|
        r.current_admin = admin
        r.gen_short_name
        r.save!
      end
    end

    #
    # Find or create an app type based on a configuration,
    # matching on the name
    def find_or_create_with_config(a_conf)
      Admin::AppType.find_by(name: a_conf['name']) || Admin::AppType.create!(a_conf)
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
    # @param [String] key - the key name from the configuration to import
    # @param [Array{String}] lookup_existing_with_fields - list of fields used to identify if a sub item already exists
    # @param [Proc | nil] reject - optional proc accepting |key, value| arguments that allows items in the
    #                              configuration to be rejected during the import. This allows a sub item of
    #                              to import a subset of its configuration at one stage and the remainder later
    # @param [Hash] add_vals - a hash representing attribute / values to add to every imported item
    # @param [Array[String]] filter_on - list attributes to compare between new and existing items to identify matches
    #                                  - these do not need to exist in the database, and can be methods
    # @return [Array{Object}] returns an array of the objects representing new and updated sub items
    def import_config_sub_items(key, lookup_existing_with_fields,
                                reject: nil, add_vals: {}, filter_on: nil)
      results = []
      failures = []
      self.current_key = key
      acs = config_for(key) # app_type_config[key] || app_type_config[orig_name]
      return unless acs

      acs = acs.reject(&reject) if reject
      # Ensure we apply them in the correct order (although this doesn't account for other types of resource)
      acs.sort! { |a, b| a['updated_at'] <=> b['updated_at'] }
      acs.each do |ci|
        self.config_item = ci
        item_changes = nil
        next if config_item['disabled']

        user = app_type_item_user(config_item['user_email'])
        next if user == :unknown

        app_type_item = find_app_type_item(lookup_existing_with_fields, filter_on)
        new_vals = new_values_from_config(lookup_existing_with_fields, add_vals)
        new_vals[:user] = user if user
        begin
          app_type_item, item_changes = create_or_update(app_type_item, new_vals)
        rescue StandardError, FphsException => e
          raise unless skip_fail

          fres = identifier_hash(app_type_item, found_with_conditions)
          fres['exception!'] = self.class.clean_exception(e)
          failures << fres
        end

        id_list << app_type_item.id if app_type_item && id_list
        results << item_changes if item_changes
      end
      import_failures[key] = failures if failures.present?
      import_results[key] = results
    end

    #
    # Create a new app type item, or update it based on the required rules
    # @param [ActiveRecord::Model] app_type_item
    # @param [Hash] new_vals
    # @return [Array]
    def create_or_update(app_type_item, new_vals)
      if !app_type_item
        app_type_item = item_changes = dyn_cname.create! new_vals
      elsif app_type_item && (
            app_type_item.updated_at.to_i <= config_item_timestamp.to_i ||
            force_update ||
            dyn_def_db_not_defined(app_type_item)
          )
        if force_update == :force || dyn_def_db_not_defined(app_type_item)
          new_vals['updated_at'] = DateTime.now
        elsif force_update == :changed
        # no change should be made
        else
          new_vals['updated_at'] = config_item_timestamp
        end
        item_changes = update_app_type_item(app_type_item, new_vals)
      end

      [app_type_item, item_changes]
    end

    #
    # Return a timestamp for the config item representing updated_at, created_at or the time now
    # to be used to compare with existing items
    # @return [DateTime]
    def config_item_timestamp
      config_item_updated_at = config_item['updated_at'] || config_item['created_at']
      config_item_updated_at ? Time.parse(config_item_updated_at) : DateTime.now
    end

    #
    # New values to be used to update / create an item, based on the config item
    # @param [Array] lookup_existing_with_fields - fields used to identify existing items
    # @param [Hash] add_vals - additional attributes to add to the result
    # @return [Hash]
    def new_values_from_config(lookup_existing_with_fields, add_vals)
      new_vals = config_item.except('user_email', 'user_id', 'app_type_id', 'admin_id', 'id',
                                    'created_at', 'updated_at',
                                    '_class_name')
      new_vals[:current_admin] = admin
      new_vals.slice(*lookup_existing_with_fields).each { |k, v| new_vals[k] = nil if v.blank? }
      new_vals.merge add_vals
    end

    #
    # Conditions used to lookup existing items
    # @param [Array] lookup_existing_with_fields - fields used to identify existing items
    # @return [Hash] conditions for #where
    def app_type_item_conditions(lookup_existing_with_fields)
      cond = config_item.slice(*lookup_existing_with_fields)
      cond.each { |k, v| cond[k] = nil if v.blank? }
      user = app_type_item_user(config_item['user_email'])
      cond[:user] = user if user
      cond
    end

    #
    # Lookup a user based on a config item user_email (if the existing items have a user_id attribute)
    # If user not found based on the user_email, and the user_email ends in '@template' then create the
    # user and return this instead
    # @param [<Type>] user_email <description>
    # @return [<Type>] <description>
    def app_type_item_user(user_email)
      has_user = dyn_cname.attribute_names.include?('user_id')
      return unless has_user

      # Check if the user exists, based on its email. If not, and the email ends with @template,
      # create a user as a placeholder
      user = Admin::AppType.user_from_email(user_email)
      if user == :unknown && user_email.end_with?('@template')
        user = User.create(email: user_email,
                           first_name: 'template',
                           last_name: 'template',
                           current_admin: admin)
      end

      user
    end

    #
    # Find the app type item that may exist based on the conditions
    # specified in the config item
    # @param [Array] lookup_existing_with_fields - fields used to identify existing items
    # @param [Array] filter_on - optional list of attributes/methods from the config item to refine the filter
    # @return [ActiveRecord::Model]
    def find_app_type_item(lookup_existing_with_fields, filter_on = nil)
      self.found_with_conditions = cond = app_type_item_conditions(lookup_existing_with_fields)
      app_type_item = dyn_cname.where(cond).reorder('').order('disabled asc nulls first, id desc')

      filter = config_item.slice(*filter_on) if filter_on
      app_type_item = filtered_results(app_type_item, filter) if filter
      app_type_item.first
    end

    #
    # Handles filtering of a list of items (either an association scope or direct query scope)
    # This receives the attributes from the current sub item definition as the filter,
    # simply looking within all the possible items passed in to limit the set
    # This allows filtering using attributes or methods, rather just DB columns
    # @param [ActiveRecord::Relation | Array] items - the scope or array to filter
    # @param [Hash] filter - key / value to filter items with
    # @return [Array] filtered items
    def filtered_results(items, filter)
      items.select do |item|
        res = true
        filter.each do |fk, fv|
          item_val = item.send(fk.to_s)
          item_val = nil if item_val.blank?
          fv = nil if fv.blank?
          res &&= (item_val == fv)
        end
        res
      end
    end

    #
    # Update an existing item and return a hash representing the
    # id and key fields for the item, plus any changed attributes.
    # Returns nil if there were no changes.
    # @param [ActiveRecord::Model] app_type_item
    # @param [Hash] new_vals
    # @return [Hash|nil] - changes, with identifiers
    def update_app_type_item(app_type_item, new_vals)
      new_vals.delete 'id'
      new_vals.delete :id
      new_vals['disabled'] = app_type_item.disabled unless app_type_item.disabled

      app_type_item.update! new_vals
      updated_hash(app_type_item, found_with_conditions)
    end

    #
    # The configuration for the current key in the configuration
    # @param [<Type>] key <description>
    # @return [<Type>] <description>
    def config_for(key)
      orig_name = key
      key = key.gsub(/^valid_/, '')

      not_directly_associated = true if key.starts_with? 'associated_'

      # Ensure a clean cache to reload previous items
      Rails.cache.clear
      self.dyn_cname = nil

      if not_directly_associated
        begin
          self.dyn_cname = Admin::AppType.class_from_name key.sub('associated_', '')
        rescue NameError
          raise
        end
      else
        self.dyn_cname = app_type.send(key)
      end

      app_type_config[key] || app_type_config[orig_name]
    end

    #
    # Provide just details of what has changed when updating the original object
    # @param [ActiveRecord] orig_obj
    # @param [Hash] item_identifiers
    # @return [Hash] of changes
    def updated_hash(orig_obj, item_identifiers)
      return unless orig_obj.saved_changes?

      identifier_hash(orig_obj, item_identifiers)
        .merge('changed attributes (from/to)' => orig_obj.previous_changes.to_h)
    end

    #
    # Prepare a hash identifying the current item
    # @param [ActiveRecord|nil] orig_obj
    # @param [Hash] item_identifiers
    # @return [Hash] of changes
    def identifier_hash(orig_obj, item_identifiers)
      res = {}
      res['id'] = orig_obj.id if orig_obj
      ii_user = item_identifiers['user']
      if ii_user
        item_identifiers['user'] = {
          'id' => ii_user.id,
          'email' => ii_user.email
        }
      end
      res.merge(item_identifiers)
    end

    #
    # If this is dynamic def return true if the underlying table / view is not defined
    # @param [ActiveRecord::Model] app_type_item
    # @return [true|false]
    def dyn_def_db_not_defined(app_type_item)
      app_type_item.respond_to?(:table_or_view) && !app_type_item.table_or_view
    end

    # Clean up user access controls that are not in the id_list
    # by disabling them.
    # Typically this is done after an import, ensuring that only the
    # imported user access controls are retained, and others that were
    # previously present are disabled.
    def clean_user_access_controls
      inv = app_type.user_access_controls.active.pluck(:id) - id_list

      inv.each do |i|
        el = Admin::UserAccessControl.find(i)
        res = el.disable! admin
        Rails.logger.info "Failed to clean up bad resource UAC: #{i}. #{el.errors.first}" unless res
      end

      app_type.valid_user_access_controls.where(resource_type: :report).each do |u|
        rn = u.resource_name
        next unless rn.present?

        unless rn.include?('_')
          u.update resource_name: Report.resource_name_for_named_report(rn),
                   current_admin: admin
        end
      end
    end
  end
end
