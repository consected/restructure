class Protocol < ActiveRecord::Base

  include SelectorCache
  belongs_to :user

  RecordUpdatesProtocolName = 'Updates'.freeze

  def self.record_updates_protocol
    Rails.cache.fetch "record_updates_protocol" do
      find_by_name(RecordUpdatesProtocolName)
    end
  end
    
end
