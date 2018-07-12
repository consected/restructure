class Classification::ProtocolEvent < ActiveRecord::Base

  self.table_name = 'protocol_events'
  include AdminHandler
  include SelectorCache

  belongs_to :sub_process
  validates :name, presence: true
  validates :sub_process, presence: true

  default_scope -> {order :name }

  def value
    id
  end

  def protocol
    sub_process.protocol if sub_process
  end

  def protocol_name
    protocol.name if protocol
  end

  def sub_process_name
    sub_process.name if sub_process
  end

  def parent_name
    "#{protocol_name} #{sub_process_name}"
  end

  def as_json options={}
    options[:methods] ||= []
    options[:methods] << :protocol_name
    options[:methods] << :sub_process_name

    super
  end

end
