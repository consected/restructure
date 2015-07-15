class Protocol < ActiveRecord::Base

  include AdminHandler
  include SelectorCache
  
  has_many :sub_processes

  RecordUpdatesProtocolName = 'Updates'.freeze
  scope :updates, -> { where name: RecordUpdatesProtocolName}
  default_scope -> { order position: :asc }
  

  def self.record_updates_protocol
    Rails.cache.fetch "record_updates_protocol" do
      enabled.updates.take
    end
  end
    
end
