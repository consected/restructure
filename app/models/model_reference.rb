class ModelReference < ActiveRecord::Base

  belongs_to :user

  validates :from_record_id, presence: true
  validates :from_record_type, presence: true
  validates :to_record_id, presence: true
  validates :to_record_type, presence: true
  validates :user_id, presence: true

  attr_accessor :current_user

  def self.create_with from_item, to_item
    ModelReference.create! from_record_type: from_item.class.name, from_record_id: from_item.id, to_record_type: to_item.class.name, to_record_id: to_item.id, user: to_item.master_user
  end

  def self.find_referenced_items from_item
    mrs = self.find_references from_item
    res = []
    mrs.each do |m|
      rec = m.to_record
      rec.master.current_user = from_item.master_user
      res << rec
    end
    res
  end

  def self.find_references from_item
    res = ModelReference.where from_record_type: from_item.class.name, from_record_id: from_item.id

    # Set the current user, so that access controls can be correctly applied
    res.each do |r|
      r.current_user = from_item.master_user
    end
    res
  end

  def to_record_label
    to_record.human_name
  end

  def to_record_type_us
    to_record_type.ns_underscore
  end

  def to_record_short_type_us
    to_record_type.split('::').last.ns_underscore
  end

  def to_record_master_id
    to_record.master_id
  end

  def to_record_viewable
    self.current_user.has_access_to? :access, :table, to_record_type_us.pluralize
  end

  def to_record_data
    to_record.data if to_record_viewable
  end

  def to_record
    return @to_record if @to_record
    rec_class = self.to_record_type.constantize
    @to_record = rec_class.find(self.to_record_id)
  end

  def as_json extras={}
    extras[:methods] ||= []
    extras[:methods] << :to_record_id
    extras[:methods] << :to_record_master_id
    extras[:methods] << :to_record_type
    extras[:methods] << :to_record_type_us
    extras[:methods] << :to_record_short_type_us
    extras[:methods] << :to_record_label
    extras[:methods] << :to_record_viewable

    extras[:methods] << :to_record_data

    # Don't return the full referenced object
    super(extras)
  end
end
