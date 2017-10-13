class Master < ActiveRecord::Base


  after_initialize :init_vars_master

  belongs_to :user

  # inverse_of required to ensure the current_user propagates between associated models correctly
  has_many :player_infos, -> { order(PlayerInfoRankOrderClause)  } , inverse_of: :master
  has_many :pro_infos , inverse_of: :master
  has_many :player_contacts, -> { order(RankNotNullClause)}, inverse_of: :master
  has_many :addresses, -> { order(RankNotNullClause)}  , inverse_of: :master
  has_many :trackers, -> { includes(:protocol).order(TrackerEventOrderClause)}, inverse_of: :master
  has_many :tracker_histories, -> { order(TrackerHistoryEventOrderClause)}, inverse_of: :master


  has_many :latest_tracker_history, -> { order(id: :desc).limit(1)},  class_name: 'TrackerHistory'


  # Note that additional has_many associations are added dynamically by the external_id handlers,
  # such as Scantron, SageAssignment, etc. This is handled through the external_id_yyy_settings.rb call to Class.add_to_app_list
  # In doing so, we enable these models to be self contained and manage the configuration of the two-way associations with masters themselves,
  # without having to update the Master model directly. This is important to allow the command:
  # `rails generate rails g external_id_handler test_thing` to function without having to hack this master.rb file

  before_validation :set_user
  before_validation :prevent_user_updates,  on: :update
  validates :user, presence: true
  before_create :assign_msid

  # DynamicModel associations take the form:
  #     master.player_contact_histories
  # i.e. the pluralized table name
  DynamicModel.enable_active_configurations


  # The main set of has_many associations that represents the primary data objects that can belong to a master record
  PrimaryAssociations = reflect_on_all_associations(:has_many).map{|a| a.name.to_s}

  # ItemFlag associations with master are generated dynamically, following the form:
  #   master.player_infos_item_flags
  ItemFlag.enable_active_configurations

  # Activity log associations with master are generated dynamically, following the form:
  #   master.activity_log__player_contact_phones
  # Notice the double underscore which represents the Module::Class delimiter
  ActivityLog.add_all_to_app_list

  attr_accessor :force_order

  # Move all the simple and advance search form functionality out of the way, so the data functionality of the model can be clearly seen
  include MasterSearchHandler



  def accuracy_rank
    pi = player_infos.first
    return -1000 unless pi
    pi.accuracy_rank
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
    logger.debug "Getting current user: #{@current_user} from #{self}"
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

  def self.create_master_records user, options={}

    raise "no user specified" unless user

    m = Master.create!(current_user: user)
    m.player_infos.create! unless options[:empty]
    return m

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
