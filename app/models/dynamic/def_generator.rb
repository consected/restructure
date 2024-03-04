# frozen_string_literal: true

module Dynamic
  module DefGenerator
    extend ActiveSupport::Concern

    included do
      after_save :generate_model, if: -> { ready_to_generate? }
      after_save :check_implementation_class

      after_save :add_master_association, if: -> { @regenerate }
      after_save :add_user_access_controls, if: -> { @regenerate }
      after_save :reset_active_model_configurations!

      after_commit :update_tracker_events, if: -> { @regenerate }
      after_commit :clean_schema, if: -> { @regenerate }
      after_commit :other_regenerate_actions
      after_commit :handle_disabled, if: -> { disabled }

      attr_accessor :force_regenerate
    end

    class_methods do
      #
      # Run through the configurations to implement them and make them available for use
      # Since ActivityLog types actually preload DynamicModel and ExternalIdentifier types
      # typically this is only called as ``::ActivityLog.define_models`
      def define_models
        preload

        begin
          dma = active_model_configurations

          logger.info "Generating models #{name} #{dma.length}"

          dma.each do |dm|
            dm.generate_model
            # Force the admin for cases that this is run outside of the admin console
            # It is expected that this is mostly when originally seeding the database
            dm.current_admin ||= dm.admin

            dm.update_tracker_events
          end
        rescue Exception => e
          msg = "Failed to generate models. Hopefully this is only during a migration. \n***** #{e.inspect}"
          puts msg
          puts e.backtrace.join("\n")
          Rails.logger.warn msg
        end
      end

      # Reload routes when a definition is regenerated
      def routes_reload
        return unless @regenerate

        Rails.application.reload_routes!
        Rails.application.routes_reloader.reload!
      end

      # Enable active configurations for the dynamic type
      # This checks that underlying tables are available, the implementation
      # class is defined, and then it adds associations to Master
      # Both log and put any errors to stdout, since this may run in a migration
      # and a log alone won't be visible to the end user
      # To ensure that the db migrations can run,
      # check for the existence of the appropriate admin table
      # before attempting to do anything. Otherwise Rake tasks fail and
      # the admin table can't be generated, preventing setup of the app.
      # @param [true|nil] disable_on_failure - default nil - disables definition on failure
      #                                      - Since this is destructive, use is most likely only in test
      def enable_active_configurations(disable_on_failure: nil)
        if Admin::MigrationGenerator.table_or_view_exists? table_name
          active_model_configurations.each do |dm|
            klass = if dm.is_a? ExternalIdentifier
                      Object
                    else
                      dm.class.name.constantize
                    end

            if dm.ready_to_generate? && dm.implementation_class_defined?(klass, fail_without_exception: true)
              dm.add_master_association
            else
              msg = "Failed to enable #{dm} #{dm.id} #{dm.resource_name}. Table ready? #{dm.table_or_view_ready?}. #{disable_on_failure && 'Disabling!'}"
              puts msg
              Rails.logger.warn msg
              dm.class.where(id: dm.id).update_all(disabled: true) if disable_on_failure
            end
          end
        else
          msg = "Table doesn't exist yet: #{table_name}"
          puts msg
          Rails.logger.warn msg
        end
      end

      #
      # Reload the models and configurations any definitions that
      # do not match the memoized version, since these may have changed on
      # another server in the cluster.
      def refresh_outdated
        utd = up_to_date?
        # If up to date, or not previously set
        # (and therefore we are on our first load and everything will have just been set up) just return
        return if utd || utd.nil?

        Rails.logger.warn "Refreshing outdated #{name}"

        defs = active_model_configurations.reorder('').order('updated_at desc nulls last')
        any_new = false
        defs.each do |d|
          rn = d.resource_name
          u = d.updated_at
          m = Resources::Models.find_by(resource_name: rn)&.model&.definition

          unless d.table_or_view_ready?
            Rails.logger.warn "refresh_outdated dynamic def #{d.class.name} table or view is not ready"
            next
          end

          klass = if d.is_a? ExternalIdentifier
                    Object
                  else
                    d.class.name.constantize
                  end

          # Skip if the model was previous set and the updated timestamps match AND the implementation class is defined
          next if m && m.updated_at == u && d.implementation_class_defined?(klass, fail_without_exception: true)

          Rails.logger.warn "Refreshing #{rn}, last updated at #{u}"
          this_is_new = !m
          any_new ||= this_is_new
          d.force_regenerate = true
          d.generate_model
          d.check_implementation_class
          d.force_option_config_parse
          d.add_master_association
          # d.add_user_access_controls
          d.reset_active_model_configurations! if this_is_new
          # d.update_tracker_events
          d.other_regenerate_actions
        end

        routes_reload if any_new
      end

      # Cache the current definitions that are in use within the appropriate dynamic definition class,
      # so that an implementation can always look up the current definition rapidly
      def definition_cache
        @definition_cache ||= {}
      end

      # End of class_methods
    end

    #
    # Simple test to see if the controller associated with the implementation model is defined
    # @param [Module | Class] parent_class is the parent for the controller, to handle namespacing issues
    # @return [Boolean]
    def implementation_controller_defined?(parent_class = Module)
      return false unless full_implementation_controller_name

      # Check that the class is defined
      klass = parent_class.const_get(full_implementation_controller_name)
      klass.is_a?(Class)
    rescue NameError
      false
    end

    # Is the implementation class for this configuration defined so that it
    # can be instantiated?
    # @param [Module | Class] parent_class
    # @param [Hash] opt options
    # @option opt [String] :class_name is an alternative class name within the
    #   parent class to test. This can be used to avoid namespacing issues
    # @option opt [Boolean] :fail_without_exception if true we return a Boolean rather than raising an exception
    # @return [Boolean] true if the class is defined, and false or a raised exception depending on the options
    def implementation_class_defined?(parent_class = Module, opt = {})
      icn = opt[:class_name] || full_implementation_class_name
      return false unless icn

      # Check that the class is defined
      klass = parent_class.const_get(icn)
      res = klass.is_a?(Class)

      return false unless res

      begin
        unless table_or_view_ready?
          raise FphsException, "Won't try to get class #{icn} - table or view not ready #{table_name}"
        end

        # Check if it can be instantiated correctly - if it can't, allow it to raise an exception
        # since this is seriously unexpected
        klass.new
      rescue Exception => e
        err = "Failed to instantiate the class #{icn} in parent #{parent_class}: #{e}"
        logger.warn err
        raise FphsException, err unless opt[:fail_without_exception]

        # By default, return false if an error occurred attempting the initialization.
        # In certain cases (for example, checking if a class exists so it can be removed), returning true if the
        # class is defined regardless of whether it can be initialized makes most sense. Provide an option to support this.
        opt[:fail_without_exception_newable_result]
      end
    rescue NameError => e
      logger.warn e
      false
    end

    #
    # Decide whether to regenerate a model based on it not existing already in the namespace
    # @return [Class | nil] truthy result unless the model exists in the namespace
    def prevent_regenerate_model
      return if force_regenerate || !ready_to_generate?

      got_class = begin
        full_implementation_class_name.constantize
      rescue StandardError
        nil
      end
      return unless got_class&.to_s&.start_with?(self.class.implementation_prefix)

      return unless fields_match_columns?

      table_changed = got_class.table_name != table_name
      if table_changed
        msg = "Table name changed in definition #{self}: " \
              "current #{got_class.table_name} != #{table_name}"
        Rails.logger.warn msg
        puts msg if Rails.env.test?
        return
      end

      got_class
    end

    #
    # Check the defined field list matches the columns in the database. If not,
    # we may need to regenerate the model
    def fields_match_columns?
      fields = all_implementation_fields(only_real: true)
      # fields.reject! { |f| f.index(/^embedded_report_|^placeholder_/) }

      (fields.sort - table_columns.map { |c| c.name.to_s }.sort).empty?
    end

    # Is the definition ready for a class to be defined?
    # Is it enabled and does it have an underlying table?
    def ready_to_generate?
      !disabled && table_or_view_ready?
    end

    #
    # Check if the underlying database table exists
    # @return [boolean]
    def table_or_view_ready?
      Admin::MigrationGenerator.table_or_view_exists?(table_name)
    rescue StandardError => e
      @extra_error = e
      false
    end

    # Tracker events are required for each dynamic class. It is the
    # responsibility of the individual definition classes to handle this
    def update_tracker_events
      raise 'DynamicModel configuration implementation must define update_tracker_events'
    end

    # After a regeneration, certain other cleanups may be required
    def other_regenerate_actions
      return if disabled

      self.class.prev_latest_update = updated_at
      self.class.preload
      Rails.logger.info 'Reloading column definitions'
      implementation_class.reset_column_information
      Rails.logger.info 'Refreshing item types'
      Classification::GeneralSelection.item_types refresh: true
    end

    # After disabling an item, clean up any mess
    def handle_disabled
      Rails.logger.info 'Refreshing item types'
      begin
        Classification::GeneralSelection.item_types refresh: true
      rescue NameError => e
        Rails.logger.info "Failed to clear general selections for #{model_class_name}"
      end

      remove_model_from_list
      remove_assoc_class 'Master'
      remove_implementation_class
      remove_implementation_controller_class
    end

    # A list of model names and definitions is stored in the class so we can
    # quickly see what dynamic classes are available elsewhere
    # Add an item to this list
    def add_model_to_list(m)
      tn = implementation_model_name
      self.class.models[tn] = m
      logger.info "Added new model #{tn}"
      self.class.model_names << tn unless self.class.model_names.include? tn
      Resources::Models.add(m)
    end

    # Remove an item from the list of available dynamic classes
    # @param [String] tn (optional)
    def remove_model_from_list(tn = nil)
      tn ||= implementation_model_name
      logger.info "Removed disabled model #{tn}"
      self.class.models.delete(tn)
      self.class.model_names.delete(tn)
      Resources::Models.remove(resource_name:)
    end

    # Dump the old association
    def remove_assoc_class(in_class_name, alt_target_class = nil, short_class_name = nil)
      cns = in_class_name.to_s.split('::')
      klass = if cns.first == 'DynamicModel'
                cns[0..1].join('::').constantize
              else
                cns.first.constantize
              end

      short_class_name = cns.last unless alt_target_class || short_class_name
      alt_target_class ||= model_class_name.pluralize
      alt_target_class = alt_target_class.gsub('::', '')
      assoc_ext_name = "#{short_class_name}#{alt_target_class}AssociationExtension"
      return unless klass.constants.include?(assoc_ext_name.to_sym)

      klass.send(:remove_const, assoc_ext_name) if implementation_class_defined?(Object)
    rescue StandardError => e
      logger.debug "Failed to remove #{assoc_ext_name} : #{e}"
    end

    def remove_implementation_class(alt_prefix_class = nil)
      klass = alt_prefix_class || prefix_class
      # This may fail if an underlying dependent class (parent class) has been redefined by
      # another dynamic implementation, such as external identifier
      return unless implementation_class_defined?(klass, fail_without_exception: true,
                                                         fail_without_exception_newable_result: true)

      klass.send(:remove_const, model_class_name)
    rescue StandardError => e
      logger.info <<~END_TEXT
        *************************************************************************************
        Failed to remove the old definition of #{model_class_name}. #{e.inspect}
        *************************************************************************************
      END_TEXT
    end

    def remove_implementation_controller_class
      klass = prefix_class
      return unless implementation_controller_defined?(klass)

      # This may fail if an underlying dependent class (parent class) has been redefined by
      # another dynamic implementation, such as external identifier
      klass.send(:remove_const, full_implementation_controller_name)
    rescue StandardError => e
      logger.info <<~END_TEXT
        *************************************************************************************
        Failed to remove the old definition of #{full_implementation_controller_name}. #{e.inspect}
        *************************************************************************************
      END_TEXT
    end

    #
    # Create a user access control for the item with a template role, to
    # ensure that it is correctly exported from an app type, even
    # if no real end users or roles have been applied to it
    # The underlying call will update an existing user access control if it
    # already exists.
    # This is called by an after_save trigger, and may also be used in specs directly
    # when the force named argument is typically used
    # @param [boolean] force the action to happen even
    #    if the item is not ready or is disabled
    # @param [Admin::AppType] app_type to add the user access control to
    # @return [Admin::UserAccessControl] the created or updated user access control
    def add_user_access_controls(force: false, app_type: nil)
      changed_name = if respond_to? :table_name
                       saved_change_to_table_name?
                     elsif respond_to? :name
                       saved_change_to_name?
                     end

      return unless !persisted? || saved_change_to_disabled? || changed_name || force

      begin
        if ready_to_generate? || disabled? || force
          app_type ||= admin.matching_user_app_type
          Admin::UserAccessControl.create_template_control admin,
                                                           app_type,
                                                           :table,
                                                           model_association_name,
                                                           disabled:
        end
      rescue StandardError => e
        raise FphsException,
              "A failure occurred creating user access control for app with: #{model_association_name}.\n#{e}"
      end
    end

    #
    # Get the field_list (or an alternative attribute string) as a
    # cleaned up array of strings
    # The string is a space or comma separated list
    # @param [String] for_attrib string from an alternative attribute
    # @return [Array{String}] strings representing the list of fields
    def field_list_array(for_attrib: nil)
      for_attrib ||= field_list
      for_attrib.split(/[,\s]+/).map(&:strip).compact if for_attrib
    end

    #
    # Database table column definitions
    def table_columns
      ActiveRecord::Base.connection.columns(table_name)
    end

    #
    # Check if the implementation class has been correctly defined
    # This checks that the underlying database table has been created.
    # If the table is not available, (and we are in the development environment)
    # a migration for the appropriate schema will be written (and run)
    def check_implementation_class
      return unless !disabled && errors.empty?

      # Check the implementation class is actually defined and can be instantiated
      begin
        res = implementation_class_defined?
      rescue StandardError => e
        err = "Failed to instantiate the class #{full_implementation_class_name}: #{e}"
        logger.warn err
        errors.add :name, err
        # Force exit of callbacks
        raise FphsException, err
      end

      # For some reason the underlying table exists but the class doesn't. Inform the admin
      return if res

      err = "The implementation of #{model_class_name} was not completed. " \
            "The DB table #{table_name} has #{table_or_view_ready? ? '' : 'NOT '}been created"
      logger.warn err
      errors.add :name, err
      # Force exit of callbacks
      raise FphsException, err
    end

    #
    # Active model configurations are memoized in a class attribute and need to be reset on a change
    def reset_active_model_configurations!
      self.class.reset_active_model_configurations!
    end

    # If we have forced a regeneration of classes, for example if a new DB table
    # has been created, don't restart the server, just clear the schema cache
    # This is called from an after_commit trigger
    def clean_schema
      # AppControl.restart_server # if Rails.env.production?
      ActiveRecord::Base.connection.schema_cache.clear!
    end

    # Get a complete set of all tables to be accessed by model reference configurations,
    # with a value representing what they are associated from.
    def all_referenced_tables
      res = []

      option_configs.map(&:references).compact.each do |act_refs|
        act_refs.each do |ref_name, outer_config|
          outer_config.each do |full_name, ref_config|
            details = ref_config.slice(:to_table_name, :to_schema_name, :to_model_class_name, :to_class_type,
                                       :from, :without_reference, :no_master_association)
            details.merge! reference_name: ref_name, full_ref_name: full_name
            res << details
          end
        end
      end

      res
    rescue StandardError => e
      raise FphsException, <<~END_TEXT
        Failed to use the extra log options. It is likely that the 'references:' attribute of one of
        activities is not formatted as expected, or a @library inclusion has an error. #{e}
      END_TEXT
    end
  end
end
