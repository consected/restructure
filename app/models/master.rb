class Master < ActiveRecord::Base


  include AlternativeIds
  AppControl.define_models


  after_initialize :init_vars_master

  belongs_to :user

  # inverse_of required to ensure the current_user propagates between associated models correctly
  has_many :player_infos, -> { order(PlayerInfoRankOrderClause)  } , inverse_of: :master
  has_one :player_info, -> { order(PlayerInfoRankOrderClause)  } , inverse_of: :master

  has_many :pro_infos , inverse_of: :master
  has_many :player_contacts, -> { order(RankNotNullClause)}, inverse_of: :master

  has_many :addresses, -> { order(RankNotNullClause)}  , inverse_of: :master
  has_many :trackers, -> { includes(:protocol).preload(:protocol, :sub_process, :protocol_event, :user).order(TrackerEventOrderClause)}, inverse_of: :master
  has_many :tracker_histories, -> { preload(:protocol, :sub_process, :protocol_event, :user).order(TrackerHistoryEventOrderClause) }, inverse_of: :master


  has_many :latest_tracker_history, -> { order(id: :desc).limit(1)},  class_name: 'TrackerHistory', inverse_of: :master

  has_many :nfs_store__manage__containers, inverse_of: :master, class_name: 'NfsStore::Manage::Container'
  has_many :nfs_store__manage__stored_files , through: :nfs_store__manage__containers, source: :master, class_name: 'NfsStore::Manage::StoredFile'
  has_many :nfs_store__manage__archived_files , through: :nfs_store__manage__containers, source: :master, class_name: 'NfsStore::Manage::ArchivedFile'

  # Note that additional has_many associations are added dynamically by the external_id handlers,
  # such as Scantron, SageAssignment, etc. This is handled through the external_id_yyy_settings.rb call to Class.add_to_app_list
  # In doing so, we enable these models to be self contained and manage the configuration of the two-way associations with masters themselves,
  # without having to update the Master model directly. This is important to allow the command:
  # `rails generate rails g external_id_handler test_thing` to function without having to hack this master.rb file

  before_validation :set_user
  before_validation :prevent_user_updates,  on: :update
  validates :user, presence: true
  before_create :assign_msid

  # The main set of has_many associations that represents the primary data objects that can belong to a master record
  PrimaryAssociations = reflect_on_all_associations(:has_many).map{|a| a.name.to_s}



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


  #TODO
  # Move all the simple and advance search form functionality out of the way, so the data functionality of the model can be clearly seen
  include MasterSearchHandler

  # ExternalIdentifier associations take the form:
  #    master.scantrons
  # i.e. the underscored pluralized name
  # This is placed here, since there is a dependence on MasterSearchHandler
  ExternalIdentifier.enable_active_configurations



  attr_accessor :force_order, :creating_master


  def to_s
    (id || '').to_s
  end

  # Scope results with inner joins on external identifier tables if they are in the user access control conditions
  def self.external_identifier_assignment_scope(user)
    # Check if the resource is restricted through external identifier assignment
    er = Admin::UserAccessControl.external_identifier_restrictions(user)

    if er
      list = er.map {|e| e.resource_name.to_sym }
      joins(*list)
    else
      all
    end
  end

  def accuracy_rank
    pi = player_infos.first
    return -1000 unless pi
    pi.accuracy_rank
  end

  def self.get_all_associations alt_type=nil
    alt_type ||= :has_many
    reflect_on_all_associations(alt_type).map{|a| a.name.to_s}
  end

  # Current admin is not stored, but may be used in validations for administrative level changes
  def current_admin=ca
    @current_admin = ca.is_a?(Admin)
  end

  def is_admin?
    !!@current_admin
  end

  def current_user= cu

    if cu.is_a? User
      @current_user = cu
    elsif cu.is_a? Integer
      @current_user = User.find cu
    else
      raise "Attempting to set current_user with non user: #{cu}"
    end
  end

  def current_user
    # Do not get the user association when requesting the current_user, since we
    # do not want the value that has been persisted in the data
    @current_user
  end

  # Prevent user from being set directly, to avoid accidental or malicious changes to the recorded user in records
  def user= u
    raise "can not set user="
  end

  def user_id= u
    raise "can not set user_id="
  end

  def assoc_named assoc_sym
    aa = self.class.get_all_associations
    raise FphsException.new "non-existent model association (#{assoc_sym}) requested" unless aa.include? assoc_sym.to_s
    self.send(assoc_sym)
  end

  def self.each_create_master_with_item user
    # Create each of the items listed in the configuration item :create_master_with (comma separated)
    create_master_with = Admin::AppConfiguration.value_for :create_master_with, user
    if create_master_with
      create_master_with.split(',').each do |cw|
        cw = cw.strip.pluralize
        raise FphsException.new "create master with configuration includes a non-existent model association (#{cw})" unless get_all_associations.include? cw
        yield cw
      end
    end
  end

  def self.create_master_record user, empty: nil, with_embedded_params: nil

    raise "no user specified" unless user
    m = Master.create!(current_user: user, creating_master: true)

    unless empty
      i = 0
      each_create_master_with_item(user) do |cw|
        with_embedded_params = nil  if i > 0

        init_data = { creating_master: true }
        assoc = m.assoc_named(cw)

        if with_embedded_params
          init_data.merge! with_embedded_params.permit(assoc.permitted_params)
        end

        assoc.create! init_data

        i += 1
      end
    end

    m.creating_master = false
    return m
  end

  def self.new_master_record user, empty: nil

    raise "no user specified" unless user
    m = Master.new(current_user: user, creating_master: true)

    unless empty
      each_create_master_with_item(user) do |cw|
        m.assoc_named(cw).build creating_master: true
      end
    end

    m.creating_master = false
    return m
  end

  def embedded_item
    @embedded_item
  end

  def embedded_item= o
    if o.is_a? UserBase
      @embedded_item = o
    elsif o.is_a?(Hash) && @embedded_item
      @embedded_item.master.current_user ||= self.current_user
      @embedded_item.update o
    end
  end

  def self.results_limit
    r = nil
    e = Settings::SearchResultsLimit
    r = e.to_i if e
    r = nil if r == 0
    r
  end

  def trackers_length
    trackers.count
  end

  def tracker_completions
    TrackerHistory.completions self
  end

  def as_json extras={}
    included_tables = {}

    self.current_user ||= extras[:current_user]
    extras.delete(:current_user)

    # If we are told these are filtered search results, they are already safe to
    # show without extra filtering at this level.
    if extras[:filtered_search_results]
      extras.delete(:filtered_search_results)
    else
      unless self.allows_user_access
        return {}
      end
    end


    style = extras[:style]
    extras.delete(:style) if extras[:style]
    extras[:methods] ||= []


    raise FphsException.new "current_user not set for master when getting results" unless self.current_user

    if style == :index
      tname = :player_infos
      if current_user.has_access_to? :access, :table, tname
        included_tables[tname] = {
          order: Master::PlayerInfoRankOrderClause,
          methods: [:user_name, :accuracy_score_name, :rank_name, :source_name]
        }
      end

      tname = :pro_infos
      if current_user.has_access_to? :access, :table, tname
        included_tables[tname] = {
        }
      end


    else

      tname = :player_infos
      if current_user.has_access_to? :access, :table, tname
        included_tables[tname] = {order: Master::PlayerInfoRankOrderClause,
          include: {
            item_flags: {include: [:item_flag_name], methods: [:method_id, :item_type_us]}
          },
          methods: [:user_name, :accuracy_score_name, :rank_name, :source_name, :tracker_history_id, :tracker_histories]
        }
      end

      tname = :pro_infos
      if current_user.has_access_to? :access, :table, tname
        included_tables[tname] = {
          include: {
            item_flags: {include: [:item_flag_name], methods: [:method_id, :item_type_us]}
          }
        }
      end

      tname = :player_contacts
      if current_user.has_access_to? :access, :table, tname
        included_tables[tname] = {
          order: {rank: :desc},
          methods: [:user_name, :rank_name, :source_name, :tracker_history_id, :tracker_histories],
          include: {
            item_flags: {include: [:item_flag_name], methods: [:method_id, :item_type_us]}
          }
        }
      end

      tname = :addresses
      if current_user.has_access_to? :access, :table, tname
        included_tables[tname] = {
          order: {rank: :desc},
          methods: [:user_name, :rank_name, :state_name, :country_name, :source_name, :tracker_history_id, :tracker_histories],
          include: {
            item_flags: {include: [:item_flag_name], methods: [:method_id, :item_type_us]}
          }
        }
      end

      tname = :tracker_histories
      if current_user.has_access_to? :access, :table, tname
        included_tables[:latest_tracker_history] = {
          methods: [:protocol_name, :protocol_position, :sub_process_name, :event_name, :user_name, :record_type_us, :record_type, :record_id, :event_description, :event_milestone]
        }

        extras[:methods] << :tracker_completions
      end
    end
    extras.merge!({ include: included_tables })

    extras[:methods] << :header_prefix
    extras[:methods] << :trackers_length

    res = Admin::AppConfiguration.values_for(:show_ids_in_master_result, current_user) - self.class.crosswalk_attrs

    res.each do |id_attr|
      extras[:methods] << id_attr
    end

    super(extras)
  end

  def header_prefix
    prefix = Admin::AppConfiguration.value_for(:master_header_prefix, current_user)
    return unless prefix.present?
    Admin::MessageTemplate.substitute prefix, data: self, tag_subs: nil, ignore_missing: true
  end

  # Validate that the external identifier restrictions do not prevent access to this item
  def allows_user_access
    # but ignore the test if not persisted yet, since the external identifier may be added during the creation process
    unless self.creating_master
      er = Admin::UserAccessControl.external_identifier_restrictions(current_user)
    end

    if er
      # Restrictions were returned. Go through each and validate an external ID has been assigned to this master by calling its association
      er.map {|e| e.resource_name.to_sym }.each do |assoc|
        return false unless self.send(assoc).first
      end
      return true
    else
      true
    end

  end

  private

    def init_vars_master
      instance_var_init :current_admin
      instance_var_init :current_user
    end

    def assign_msid

      max_msid = Master.maximum(:msid) || 0
      self.msid = max_msid + 1

    end

    def prevent_user_updates
      errors.add :pro_id, "can not be updated by users" if pro_id_changed?
      errors.add :msid, "can not be updated by users" if msid_changed?
      errors.add "pro info association", "can not be updated by users" if pro_info_id_changed?
    end


    def set_user
      cu = @current_user
      # Set the user association when current_user is set
      if cu.is_a?(User) && cu.persisted?
        write_attribute :user_id, cu.id
      else
        raise "Attempting to set user with non user: #{cu}"
      end

    end

end
