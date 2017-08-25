class ActivityLog < ActiveRecord::Base
  
  include WorksWithItem

  belongs_to :item, polymorphic: true, inverse_of: :activity_logs
  
  before_validation :force_write_user



  def as_json options={}
    options[:methods] ||= []
    options[:methods] += [:method_id, :item_type_us]
#    options[:include] ||=[]
#    options[:include] << :item_flag_name
    options[:done] = true
    super(options)
  end

  def force_write_user
    return true if !persisted?

    raise "bad user being pulled from master_user" unless master_user.is_a?(User) && master_user.persisted?

    write_attribute :user_id, master_user.id
  end

  def master_user
    current_user = item.master.current_user
    log.info "Got current user: #{current_user}"
    current_user
  end

  def no_track
    true
  end
  
end
