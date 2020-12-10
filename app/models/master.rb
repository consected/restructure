# frozen_string_literal: true

class Master < ActiveRecord::Base
  FilteredAssocPrefix = 'filtered__'

  MasterNestedAttribs = [
    Settings::DefaultSubjectInfoTableName.to_sym,
    Settings::DefaultSecondaryInfoTableName.to_sym,
    Settings::DefaultContactInfoTableName.to_sym,
    Settings::DefaultAddressInfoTableName.to_sym
  ] + %i[general_infos trackers tracker_histories
         not_trackers not_tracker_histories].freeze

  TrackerEventOrderClause = Arel.sql 'protocols.position asc, event_date DESC NULLS last, trackers.updated_at DESC NULLS last '
  TrackerHistoryEventOrderClause = Arel.sql 'event_date DESC NULLS last, tracker_history.updated_at DESC NULLS last '
  SubjectInfoRankOrderClause = Arel.sql 'rank desc nulls last '

  def self.subject_info_rank_order_clause
    SubjectInfoRankOrderClause
  end

  #
  # Attributes (typically crosswalk attributes) that can not be changed by users
  # Overridden by specific implementations
  def self.readonly_attrs
    []
  end

  #
  # Get all associations (by default has_many) defined currently as string names
  # @param [Symbol] alt_type allows other type of association to be requested
  # @return [Array{String}] list of names
  def self.get_all_associations(alt_type = nil)
    alt_type ||= :has_many
    reflect_on_all_associations(alt_type).map { |a| a.name.to_s }
  end

  def self.set_associations_for_subject_searches
    # inverse_of required to ensure the current_user propagates between associated models correctly
    has_many Settings::DefaultSubjectInfoTableName.to_sym,
             -> { order(Master.subject_info_rank_order_clause) },
             inverse_of: :master

    has_one Settings::DefaultSubjectInfoTableName.singularize.to_sym,
            -> { order(Master.subject_info_rank_order_clause) },
            inverse_of: :master

    has_many Settings::DefaultSecondaryInfoTableName.to_sym,
             inverse_of: :master

    has_many Settings::DefaultContactInfoTableName.to_sym,
             -> { order(RankNotNullClause) },
             inverse_of: :master

    has_many Settings::DefaultAddressInfoTableName.to_sym,
             -> { order(RankNotNullClause) },
             inverse_of: :master

    # Associations to allow advanced searches for NOT
    has_many :not_tracker_histories,
             -> { order(TrackerHistoryEventOrderClause) },
             class_name: 'TrackerHistory'

    has_many :not_trackers,
             -> { order(TrackerEventOrderClause) },
             class_name: 'Tracker'

    # This association is provided to allow 'simple' search on names in player_infos OR pro_infos
    has_many :general_infos,
             class_name: Settings::DefaultSubjectInfoTableName.singularize.camelize
  end

  include AlternativeIds
  include LimitedAccessControl
  # Move all the FPHS specific simple and advance search form functionality out of the way,
  # so the data functionality of the model can be clearly seen
  # and overrides can happen
  include Fphs::MasterSearchHandler

  AppControl.define_models

  after_initialize :init_vars_master

  belongs_to :user

  set_associations_for_subject_searches

  has_many :trackers,
           lambda {
             includes(:protocol)
               .preload(:protocol, :sub_process, :protocol_event, :user)
               .order(TrackerEventOrderClause)
           },
           inverse_of: :master

  has_many :tracker_histories,
           lambda {
             preload(:protocol, :sub_process, :protocol_event, :user)
               .order(TrackerHistoryEventOrderClause)
           },
           inverse_of: :master

  has_many :latest_tracker_history,
           -> { order(id: :desc).limit(1) },
           class_name: 'TrackerHistory',
           inverse_of: :master

  has_many :nfs_store__manage__containers,
           inverse_of: :master,
           class_name: 'NfsStore::Manage::Container'

  has_many :nfs_store__manage__stored_files,
           through: :nfs_store__manage__containers,
           source: :master,
           class_name: 'NfsStore::Manage::StoredFile'

  has_many :nfs_store__manage__archived_files,
           through: :nfs_store__manage__containers,
           source: :master,
           class_name: 'NfsStore::Manage::ArchivedFile'

  # Note that additional has_many associations are added dynamically by the external_id handlers,
  # such as Scantron, SageAssignment, etc. This is handled through the external_id_yyy_settings.rb call to Class.add_to_app_list
  # In doing so, we enable these models to be self contained and manage the configuration of the two-way associations with masters themselves,
  # without having to update the Master model directly. This is important to allow the command:
  # `rails generate rails g external_id_handler test_thing` to function without having to hack this master.rb file

  before_validation :set_user
  before_validation :prevent_user_updates, on: :update
  validates :user, presence: true

  # The main set of has_many associations that represents the primary data objects that can belong to a master record
  PrimaryAssociations = get_all_associations

  # DynamicModel associations take the form:
  #     master.player_contact_histories
  # i.e. the pluralized table name
  DynamicModel.enable_active_configurations

  # ItemFlag associations with master are generated dynamically, following the form:
  #   master.player_infos_item_flags
  ItemFlag.enable_active_configurations

  # Activity log associations with master are generated dynamically, following the form:
  #   master.activity_log__player_contact_phones
  # Notice the double underscore which represents the Module::Class delimiter
  ActivityLog.enable_active_configurations

  # ExternalIdentifier associations take the form:
  #    master.scantrons
  # i.e. the underscored pluralized name
  # This is placed here, since there is a dependency on MasterSearchHandler
  ExternalIdentifier.enable_active_configurations

  attr_accessor :force_order, :creating_master
  attr_reader :current_user, :embedded_item

  init_nested_attribs

  #
  # Ensure a string representation of a master is just its id, not revealing anything else
  def to_s
    (id || '').to_s
  end

  #
  # Find a Master with an id, crosswalk attribute or alternative id
  # @param [Hash] params
  # @options params [String] :type - a crosswalk attribute or external id field name
  # @options params [String] :id - the id value to match against
  # @return [Master|nil] the resulting Master or nil if not found
  def self.find_with(params)
    req_type = params[:type]

    if req_type&.to_sym&.in?(crosswalk_attrs) && params[:id]
      # The requested type is a master crosswalk attribute.
      # Find the master and retrieve the value
      Master.send("find_by_#{req_type}", params[:id])
    elsif req_type&.to_sym&.in?(Master.alternative_id_fields) && params[:id]
      # The requested type is a master crosswalk attribute.
      # Find the master and retrieve the value
      Master.find_with_alternative_id(req_type, params[:id])
    elsif params[:id]
      # Not a crosswalk, so the id is a Master id
      Master.find_by_id(params[:id])
    end
  end

  # Handle limited access controls in master queries
  # Scope results with inner joins on external identifier or dynamic model tables if they are in the user access control conditions
  def self.limited_access_scope(user)
    # Check if the resource is restricted through external identifier assignment
    er = Admin::UserAccessControl.limited_access_restrictions(user)

    res = all
    # For each required limited_access model, inner join it. If it also requires
    # an assign_access_to_user_id field ensure this matches the current user too
    er&.each do |e|
      assoc_name = e.resource_name.to_sym
      res = res.join_limit_to_assigned(assoc_name, user)
    end

    res
  end

  #
  # Check if a current admin has been set for certain administrative tasks
  # @return [Boolean]
  # Current admin is not stored, but may be used in validations for administrative level changes
  def current_admin=(ca)
    @current_admin = ca.is_a?(Admin)
  end

  #
  # Check if current_admin has been set to a valid admin
  def current_admin?
    @current_admin.is_a?(Admin)
  end

  #
  # Set the current user in order to verify access to master associated instances.
  # The current_user method on any models associated with a master will call this
  # method, to find the current authenticated user.
  # This allows controllers to set the current user in one place consistently,
  # while allowing models to enforce security on instances being returned.
  # @param [User] cu - current user
  # @return [User]
  def current_user=(cu)
    if cu.is_a? User
      @current_user = cu
    elsif cu.is_a? Integer
      @current_user = User.find cu
    else
      raise "Attempting to set current_user with non user: #{cu}"
    end
  end

  #
  # Prevent user from being set directly, to avoid accidental or malicious changes to the recorded user in records.
  # Users will be set during create and update automatically, based on the #current_user
  def user=(_u)
    raise 'can not set user='
  end

  def user_id=(_u)
    raise 'can not set user_id='
  end

  #
  # Get the association results for a named association
  # @param [Symbol] assoc_sym - name of association to lookup and run
  # @return [ActiveRecord::Relation] association results
  def assoc_named(assoc_sym)
    aa = self.class.get_all_associations
    raise FphsException, "non-existent model association (#{assoc_sym}) requested" unless aa.include? assoc_sym.to_s

    send(assoc_sym)
  end

  #
  # Some associations have an equivalent 'filtered' version, used to get lists that have removed items that do not
  # meet calc_showable_if rules defined in extra options
  # @param tname [String] the name of the association
  # @return [String] returns the filtered name if it exists, otherwise return the name that was passed
  def filtered_assoc_name(tname)
    tname = "#{FilteredAssocPrefix}#{tname}" if respond_to?("#{FilteredAssocPrefix}#{tname}")
    tname
  end

  #
  # Setup associations for each of the items listed in the
  # app configuration item :create_master_with for the user/role. Yields the
  # pluralized association name to the block passed
  # @param [User] user - current user
  def self.each_create_master_with_item(user)
    create_master_with = Admin::AppConfiguration.values_for(:create_master_with, user)
    create_master_with&.each do |cw|
      cw = cw.strip.pluralize
      unless get_all_associations.include? cw
        raise FphsException, "create master with configuration includes a non-existent model association (#{cw})"
      end

      yield cw
    end
  end

  #
  # Create a fully hydrated master record, potentially including
  # embedded parameters to create associated records and external identifiers.
  # Embed items listed in app configuration item :create_master_with for the user/role
  # @param [User] user - current user
  # @param [Boolean] empty - create an empty master, independent of :create_master_with
  # @param [ActionController::StrongParameters] with_embedded_params - associated parameters
  #   permitted to create instances
  # @param [Hash] extra_ids - hash representing extra identifier id field => value pairs
  # @return [Master] resulting persisted Master instance
  def self.create_master_record(user, empty: nil, with_embedded_params: nil, extra_ids: nil)
    raise 'no user specified' unless user

    vals = { current_user: user, creating_master: true }
    vals = vals.merge(extra_ids) if extra_ids
    m = Master.create!(vals)

    unless empty
      i = 0
      each_create_master_with_item(user) do |cw|
        with_embedded_params = nil if i > 0

        init_data = { creating_master: true }
        assoc = m.assoc_named(cw)

        init_data.merge! with_embedded_params.permit(assoc.permitted_params) if with_embedded_params

        assoc.create! init_data

        i += 1
      end
    end

    m.creating_master = false
    m
  end

  #
  # Build out a master record with associations
  # listed in app configuration item :create_master_with for the user/role
  # @param [User] user - current user
  # @param [Boolean] empty - create an empty master, independent of :create_master_with
  # @return [Master] new (not persisted) Master instance
  def self.new_master_record(user, empty: nil)
    raise 'no user specified' unless user

    m = Master.new(current_user: user, creating_master: true)

    unless empty
      each_create_master_with_item(user) do |cw|
        m.assoc_named(cw).build creating_master: true
      end
    end

    m.creating_master = false
    m
  end

  #
  # Set an item embedded in this instance.
  # @param [UserBase | Hash] item - instance, or a Hash to update existing @embedded_item with
  # @return [UserBase | nil]
  def embedded_item=(item)
    if item.is_a? UserBase
      @embedded_item = item
    elsif item.is_a?(Hash) && @embedded_item
      @embedded_item.master.current_user ||= current_user
      @embedded_item.update item
    end
  end

  #
  # Number of records to limit results to, based on the value set in Settings
  # If the value from this is blank (or not castable to an Integer), nil will be returned
  # @return [Integer | nil]
  def self.results_limit
    r = nil
    e = Settings::SearchResultsLimit
    r = e.to_i if e
    r = nil if r == 0
    r
  end

  #
  # Memoized count of associated tracker records
  def trackers_length
    @trackers_length ||= trackers.count
  end

  #
  # Get a hash of protocols that have been marked as completed, based on the configuration
  # of that defines the event for each that indicates a completion
  def tracker_completions
    TrackerHistory.completions self
  end

  #
  # The primary subject info model name (symbol) to be displayed in master result heading items
  # Valid models mix in ViewHandlers::Subject
  # @return [Symbol | nil]
  def subject_info_sym
    subject_info_sym = Admin::AppConfiguration.value_for(:header_subject_data_type, current_user)
    subject_info_sym = Settings::DefaultSubjectInfoTableName if subject_info_sym.blank?
    subject_info_sym.to_sym
  end

  #
  # The secondary subject info model name (symbol) to be displayed in master result heading items
  # Valid models mix in ViewHandlers::SecondaryInfo
  # @return [Symbol | nil]
  def secondary_info_sym
    secondary_info_sym = Admin::AppConfiguration.value_for(:header_secondary_data_type, current_user)
    secondary_info_sym = Settings::DefaultSecondaryInfoTableName if secondary_info_sym.blank?
    secondary_info_sym.to_sym
  end

  #
  # The address info model name (symbol) to be displayed in master results
  # Valid models mix in ViewHandlers::Address
  # @return [Symbol | nil]
  def address_info_sym
    address_info_sym = Admin::AppConfiguration.value_for(:data_type_address, current_user)
    address_info_sym = Settings::DefaultAddressInfoTableName if address_info_sym.blank?
    address_info_sym.to_sym
  end

  #
  # The contact info model name (symbol) to be displayed in master results
  # Valid models mix in ViewHandlers::Contact
  # @return [Symbol | nil]
  def contact_info_sym
    contact_info_sym = Admin::AppConfiguration.value_for(:data_type_contact, current_user)
    contact_info_sym = Settings::DefaultContactInfoTableName if contact_info_sym.blank?
    contact_info_sym.to_sym
  end

  #
  # The result headers show one or more ids. The ids default to the master id only,
  # but may be fully defined with the app configuration :show_ids_in_master_result
  # @return [Array]
  def show_ids_in_results
    return @show_ids_in_results if @show_ids_in_results

    res = Admin::AppConfiguration.values_for(:show_ids_in_master_result, current_user)
    res = if res.include? :none
            []
          else
            res - self.class.crosswalk_attrs - [:master_id]
          end

    @show_ids_in_results = res
  end

  #
  # Setup the JSON result for an index or instance style, set by extras[:style]
  # as an addition to standard as_json options.
  # This method may be overridden if required.
  # Any models included in the method implementation will not be pulled into
  # results where a user is not granted access to them through user access controls, which
  # has the effect of disabling them for an application that doesn't use them.
  # @param [Hash] extras - standard and additional as_json options
  # @option extras [Symbol] :style - :index for index style results, or anything else for instance style
  # @option extras [Boolean] :filtered_search_results - true if it is safe to show results without extra filtering
  # @option extras [User] :current_user - provides the user context for filtering and additional access if needed
  def as_json(extras = {})
    included_tables = {}

    self.current_user ||= extras[:current_user]
    extras.delete(:current_user)

    # If we are told these are filtered search results, they are already safe to
    # show without extra filtering at this level.
    if extras[:filtered_search_results]
      extras.delete(:filtered_search_results)
    else
      return {} unless allows_user_access
    end

    style = extras[:style]
    extras.delete(:style) if extras[:style]
    extras[:methods] ||= []

    raise FphsException, 'current_user not set for master when getting results' unless self.current_user

    if style == :index
      tname = subject_info_sym
      if current_user.has_access_to? :access, :table, tname
        tname = filtered_assoc_name(tname)

        included_tables[tname] = {
          order: self.class.subject_info_rank_order_clause,
          methods: %i[user_name accuracy_score_name rank_name source_name def_version vdef_version]
        }
      end

      tname = secondary_info_sym
      if current_user.has_access_to? :access, :table, tname
        included_tables[tname] = {
          methods: %i[def_version vdef_version]
        }
      end

    else

      include_item_flags = { include: [:item_flag_name], methods: %i[method_id item_type_us] }

      tname = subject_info_sym
      if current_user.has_access_to? :access, :table, tname
        tname = filtered_assoc_name(tname)

        included_tables[tname] = { order: self.class.subject_info_rank_order_clause,
                                   include: {
                                     item_flags: include_item_flags
                                   },
                                   methods: %i[user_name accuracy_score_name
                                               rank_name source_name tracker_history_id
                                               tracker_histories def_version vdef_version] }
      end

      tname = secondary_info_sym
      if current_user.has_access_to? :access, :table, tname
        included_tables[tname] = {
          include: {
            item_flags: include_item_flags
          },
          methods: %i[def_version vdef_version]
        }
      end

      tname = contact_info_sym
      if current_user.has_access_to? :access, :table, tname
        included_tables[tname] = {
          order: { rank: :desc },
          methods: %i[user_name rank_name source_name tracker_history_id tracker_histories def_version vdef_version],
          include: {
            item_flags: include_item_flags
          }
        }
      end

      tname = address_info_sym
      if current_user.has_access_to? :access, :table, tname
        included_tables[tname] = {
          order: { rank: :desc },
          methods: %i[user_name rank_name state_name country_name
                      source_name tracker_history_id tracker_histories def_version vdef_version],
          include: {
            item_flags: include_item_flags
          }
        }
      end

      tname = :tracker_histories
      if current_user.has_access_to? :access, :table, tname
        included_tables[:latest_tracker_history] = {
          methods: %i[protocol_name protocol_position sub_process_name
                      event_name user_name record_type_us record_type
                      record_id event_description event_milestone
                      def_version vdef_version]
        }

        extras[:methods] << :tracker_completions
      end
    end

    extras.merge!(include: included_tables)
    extras[:methods] << :header_prefix
    extras[:methods] << :header_title
    extras[:methods] << :trackers_length

    show_ids_in_results.each do |id_attr|
      extras[:methods] << id_attr
    end

    res = super(extras)

    # Handled the filtered lists, changing their names back to match the original expected objects names
    res.keys.each do |k|
      if k.start_with?(FilteredAssocPrefix)
        res[k.sub(FilteredAssocPrefix, '')] = res[k]
        res.delete(k)
      end
    end

    res
  end

  #
  # Calculate the substitutions for a master header prefix or title
  # @param [String] template - the template string with {{substitution}} markers
  # @return [String] substituted results for this master record's prefix or title
  def header_substitutions(template)
    html = false
    return unless template.present?

    template = Formatter::Substitution.substitute template, data: self, tag_subs: nil, ignore_missing: true
    template = CGI.escapeHTML template
    while template.include? '**'
      template = template.sub('**', '<b>')
      template = template.sub('**', '</b>')
      html = true
    end
    template.html_safe if html
    template
  end

  # Prefix to be used to display in master results to appear before the main results title
  def header_prefix
    template = Admin::AppConfiguration.value_for(:master_header_prefix, current_user)
    header_substitutions template
  end

  # Title to be used to display in master results
  # By default this is primary subject model name, etc, if not set in configuration
  def header_title
    template = Admin::AppConfiguration.value_for(:master_header_title, current_user)
    header_substitutions template
  end

  # Validate that the external identifier restrictions do not prevent access to this item
  def allows_user_access
    # but ignore the test if not persisted yet, since the external identifier may be added during the creation process
    er = Admin::UserAccessControl.limited_access_restrictions(current_user) unless creating_master

    # If no restrictions were specified, skip the iteration and, allow access
    return true unless er.present?

    # If restrictions were returned - go through each and validate an external ID
    # has been assigned to this master by calling its association
    # If all required instances (and their assign_access_to_user_id fields if needed) exist, allow access
    er&.each do |e|
      assoc_name = e.resource_name.to_sym
      assoc = send(assoc_name)
      return false unless assoc.limit_to_assigned(current_user).first
    end

    true
  end

  private

  def init_vars_master
    instance_var_init :current_admin
    instance_var_init :current_user
  end

  #
  # Validation method to
  # prevent updates of attributes (specific crosswalk attributes)
  def prevent_user_updates
    return unless self.class.respond_to? :readonly_attrs

    self.class.readonly_attrs.each do |attr|
      errors.add attr, 'can not be updated by users' if send("#{attr}_changed?")
    end
  end

  # Set the user attribute / association when saving
  # The current_user must be set using a persisted, active User
  def set_user
    cu = @current_user
    raise "Attempting to set user with non user: #{cu}" unless cu.is_a?(User) && cu.persisted? && cu.disabled

    write_attribute :user_id, cu.id
  end
end
