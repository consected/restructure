module TrackerHistorySupport
  include MasterSupport
  def list_valid_attribs
    res = []
    
    (1..5).each do |l|
      res << {
        tracker_id: rand(999998)+1
      }
    end
    res << {tracker_id: 999999 }
    res << {tracker_id: 1 }
    res
  end
  
  def list_invalid_attribs
    [
      {
        tracker_id: 1000000
      },
      {
        tracker_id: 'asjfjgsf'
      },
      {
        tracker_id: nil
      },
      {
        tracker_id: ''
      },
      {
        tracker_id: 0
      }
    ]
  end
  
  def new_attribs
    @new_attribs = {
      tracker_id: rand(999998) + 1
    }
  end
  
  
  
  def create_item att=nil, master=nil
    att ||= valid_attribs
    master ||= create_master
    @tracker = master.trackers.create! att
  end
  
end
