# frozen_string_literal: true

module Dynamic
  module ActivityLogImplementer
    extend ActiveSupport::Concern
    include GeneralDataConcerns

    included do
      belongs_to :master, inverse_of: assoc_inverse
      # It is necessary to force the class name of the parent, since
      # the association will attempt to use the class within the ActivityLog module otherwise
      # which effectively refers the implementation back to itself
      belongs_to parent_type, class_name: "::#{parent_class.name}", optional: true
      has_many :item_flags, as: :item, inverse_of: :item

      after_initialize :set_action_when
      after_initialize :format_sync_fields

      # don't validate the association with the parent item_data
      # blank activity logs do not have one
      # validates parent_type, presence: true

      validates :master_id, presence: true

      after_save :sync_tracker

      attr_writer :alt_order
    end

    class_methods do
      #
      # The secondary_key to use for lookups of records using #find_by_secondary_key
      # @return [String] field name
      def secondary_key
        definition.secondary_key
      end

      def final_setup
        Rails.logger.debug "Running final setup for #{name}"
        default_scope -> { order id: :desc }
      end

      def is_activity_log
        true
      end

      # get the attributes that are common between the parent item and the new logged item
      def fields_to_sync
        attribute_names & parent_class.attribute_names - %w[id master_id user_id created_at updated_at item_id]
      end

      # gets the class names that this activity log model can be used with, from the admin definition
      def use_with_class_names
        ActivityLog.use_with_class_names
      end

      def assoc_inverse
        # The plural model name
        name.ns_underscore.pluralize.to_sym
      end

      # # Find the record in the admin activity log that defines this activity log
      # def admin_activity_log
      #   res = ActivityLog.active.select{|s| s.table_name == self.table_name}
      #   raise "Found incorrect number (#{res.length}) of admin activity logs for table name #{self.table_name} from possible list of #{ActivityLog.active.length}" if res.length != 1
      #   res.first
      # end

      # List of attributes to be used in common template views
      # Use the defined field_list if it is not blank
      # Otherwise use attribute names from the model, removing common junk
      def view_attribute_list
        al = definition
        res = if al.field_list.blank?
                attribute_names - ['id', 'master_id', 'disabled', parent_type, "#{parent_type}_id", 'user_id',
                                   'created_at', 'updated_at', 'rank', 'source'] + ['tracker_history_id']
              else
                al.view_attribute_list + ['tracker_history_id']
              end
        res.map(&:to_sym)
      end

      # List of attributes to be used in blank log template views
      # Use the defined blank_log_field_list if it is not blank
      # Otherwise use the view_attribute_list
      def view_blank_log_attribute_list
        al = definition
        res = if al.blank_log_field_list.blank?
                view_attribute_list.clone
              else
                definition.view_blank_log_attribute_list.map(&:to_s) + ['tracker_history_id']
              end
        res.map(&:to_sym)
      end

      # resource_name used by user access controls
      # This is the resource name for the total process
      # The method #resource_name represents the resource_name for the extra_log_type
      def resource_name
        definition.resource_name
      end

      # Resource name for a single instance of the model
      def resource_item_name
        definition.resource_item_name
      end

      # The user relevant data attributes in the parent class
      def parent_data_names
        parent_class.attribute_names - %w[id master_id disabled user_id admin_id created_at updated_at rank rec_type]
      end

      # Default attribute name for the 'completed when' field
      def action_when_attribute
        :completed_when
      end

      def uses_item_flags?(user)
        Classification::ItemFlagName.enabled_for? name.ns_underscore, user
      end

      def human_name_for(extra_log_type)
        extra_log_type.to_s.humanize
      end

      def parent_type
        @parent_type = definition.item_type.to_sym
      end

      def parent_rec_type
        @parent_rec_type = definition.rec_type.to_sym
      end

      def action_when_attribute
        @action_when_attribute = definition.action_when_attribute.to_sym
      end

      def activity_log_name
        @activity_log_name = definition.name
      end

      def permitted_params
        fts = fields_to_sync.map(&:to_sym)
        attribute_names.map(&:to_sym) -
          [:user_id, :created_at, :updated_at, "#{parent_type}_id".to_sym, parent_type, :tracker_id] +
          [:item_id] -
          fts
      end

      # Hash of activity log types that can be created or not, based on
      # -
      # - user access controls
      # - creatable_if rules (if a current activity is specified)
      # Each key is listed and has value nil if not creatable, or the resource name of the type if creatable
      # For example:
      #   {:register=>"activity_log__ipa_sample__register", :transport=>nil, :receive=>nil }
      # indicates that the 'register' activity is creatable, but 'transport' and 'receive' are not
      # @params [User|nil] current_user - the user to check creatable items against
      # @params [ActivityLog|nil] def_record - the definition record for the activity log (default: current definition)
      # @params [UserBase|nil] current_activity - optionally, an activity log implementation instance to
      #   calculate data related creatable
      # @return [Hash]
      def creatables(current_user, def_record: nil, current_activity: nil, include_references: true)
        def_record ||= definition
        res = {}
        orig_elt = current_activity['extra_log_type']

        def_record.option_configs.each do |c|
          result = current_user.has_access_to?(:create, :activity_log_type, c.resource_name)
          if current_activity
            current_activity['extra_log_type'] = c.name&.to_s
            result &&= c.calc_if(:creatable_if, current_activity)
          end
          result &&= !(c.view_options && c.view_options[:only_create_as_reference]) unless include_references
          res[c.name] = result ? c.resource_name : nil
        end

        current_activity['extra_log_type'] = orig_elt

        res
      end
    end

    def model_data_type
      :activity_log
    end

    # resource_name used by user access controls
    # This method represents the resource_name for the extra_log_type
    # The resource name for the total process is the class method {resource_name}
    def resource_name
      extra_log_type_config.resource_name
    end

    def human_name
      return extra_log_type_config.label if extra_log_type_config.label.present?

      extra_log_type.to_s.humanize
    end

    def to_s
      data
    end

    def alt_order
      return unless extra_log_type_config&.view_options

      da = extra_log_type_config.view_options[:alt_order]
      da = [da] unless da.is_a? Array
      res = ''
      # collect potential date / time pairs from adjacent fields
      dtp = nil
      da.each do |n|
        v = attributes[n]
        if v.is_a? Date
          # Set the date portion of the date / time pair, but don't store it yet
          dtp = DateTime.new(v.year, v.month, v.day, 0, 0, 0, Time.current.send(:zone))
        elsif v.is_a? Time
          if dtp
            # A date portion of a date / time pair is present, so add the time and store to the result
            res = DateTime.new(dtp.year, dtp.month, dtp.day, v.hour, v.min, 0, v.send(:zone))
            # Clear the date / time pair now we are done with it
            dtp = nil
          else
            # Since no date portion was already available, just store the time (this is based on 2001-01-01 date)
            res += v.to_i.to_s
          end
        else
          # If a date / time pair is set, but was not yet stored, then a date portion was provided, but no time.
          # Store that date to the result from the previous iteration, before storing the value for the current attribute.
          # Remember to clear the date / time pair after storing
          res += dtp.to_s if dtp
          dtp = nil
          res += v if v
        end
      end

      res
    end

    def no_master_association
      false
    end

    #
    # Override the standard extra_log_type attribute to handle
    # primary and blank activity log types.
    # Since this form of activity log definition is not recommended
    # this override should eventually be deprecated
    # @return [Symbol] extra log type name
    def extra_log_type
      elt = super()
      if elt.blank?
        elt = item ? :primary : :blank_log
      end

      elt.to_sym
    end

    def option_type
      extra_log_type
    end

    def extra_log_type_config
      option_type_config
    end

    # default record updates tracking is not performed, since we sync tracker separately
    def no_track
      false
    end

    # these models belong to an item from the perspective of user interaction, rather than master
    # although equally there is a master association
    def belongs_directly_to
      item
    end

    # simple way of getting the item from the actual parent association
    def item
      @item ||= send(self.class.parent_type)
    end

    def item_id
      item&.id
    end

    # set the association
    def item_id=(i)
      send("#{self.class.parent_type}_id=", i)
    end

    # set the action_when attribute to the current date time, if it is not already set
    def set_action_when
      self.action_when = DateTime.now if action_when.blank?
      action_when
    end

    # action_when represents the date or timestamp attribute that is used to order results
    # Often this will be the created_at attribute value, although it may represent an alternative value
    # the action_when attribute may vary from one activity log model to another. Get the value
    def action_when
      action = self.class.action_when_attribute
      send(action)
    end

    # Set the action_when attribute (which may be a timestamp or integer)
    # If a timestamp is received and the target attribute is and integer,
    # then it will be implicitly cast to an.
    # If the id attribute is the target, then do not set anything,
    # since this will break the primary key. Just return silently.
    # @param [DateTime|Integer] date_or_int
    def action_when=(date_or_int)
      return if self.class.action_when_attribute == :id

      action = self.class.action_when_attribute
      send("#{action}=", date_or_int)
    end

    def save_action
      extra_log_type_config.calc_save_action_if self
    end

    def creatables(include_references: true)
      self.class.creatables master.current_user,
                            def_record: current_definition,
                            current_activity: self,
                            include_references:
    end

    def update_action
      @was_created || @was_updated
    end

    def can_edit?
      return @can_edit unless @can_edit.nil?

      @can_edit = false
      resname = extra_log_type_config.resource_name

      # First, check if the user can actually access this type of activity log to edit it
      res = master.current_user.has_access_to? :edit, :activity_log_type, resname
      unless res
        Rails.logger.info "Can not edit activity_log_type #{resname} due to lack of access"
        return
      end

      # either use the editable_if configuration if there is one,
      # or only allow the latest item to be used otherwise
      res = calc_can :edit
      if res == false
        Rails.logger.info "Can not edit activity_log_type #{resname} due to editable_if calculation"
        return

      elsif res.nil?
        @latest_item ||= master.send(self.class.assoc_inverse).unscope(:order).order(id: :desc).limit(1).first
        res = user_id == master.current_user.id && @latest_item.id == id
        unless res
          Rails.logger.info "Can not edit activity_log_type #{resname} since it has been overridden by a later item"
          return
        end
      end

      # Finally continue with the standard checks if none of the previous have failed
      @can_edit = super()
    end

    def can_create?
      return @can_create unless @can_create.nil?

      unless extra_log_type_config
        msg = "can_create? does not have an extra_log_type_config for #{self} -- #{extra_log_type}"
        Rails.logger.warn msg
        Rails.logger.warn "extra_log_type: #{extra_log_type}"
        Rails.logger.warn "option_configs_names: #{self.class.definition.option_configs_names}"
        raise FphsException, msg
      end

      @can_create = false
      res = master.current_user.has_access_to? :create, :activity_log_type, extra_log_type_config.resource_name

      unless res
        Rails.logger.info "Can not create activity_log_type #{extra_log_type_config.resource_name} due to lack of access"
      end

      @can_create = !!(res && super())
    end

    def can_access?
      return @can_access unless @can_access.nil?

      @can_access = false
      res = master.current_user.has_access_to? :access, :activity_log_type, extra_log_type_config.resource_name

      unless res
        Rails.logger.info "Can not access activity_log_type #{extra_log_type_config.resource_name} due to lack of access"
      end

      @can_access = !!(res && super())
    end

    # Extend the standard access check with a check on the extra_log_type resource
    def allows_current_user_access_to?(perform, with_options = nil)
      unless master.current_user
        raise FphsException, 'no master.current_user in activity_log_handler allows_current_user_access_to?'
      end

      if extra_log_type_config&.resource_name
        res = master.current_user.has_access_to? perform, :activity_log_type, extra_log_type_config.resource_name
      end
      res && super(perform, with_options)
    end

    def current_user
      master&.current_user
    end

    def current_user=(cu)
      master.current_user = cu
    end

    # An app specific DB trigger may have have created a message notification record.
    # Check for new records, and work from there.
    def check_for_notification_records
      Messaging::MessageNotification.handle_notification_records self
    end
  end
end
