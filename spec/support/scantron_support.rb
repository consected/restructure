module ScantronSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    
    (1..5).each do |l|
      res << {
        scantron_id: rand(100000000)
      }
    end
    res<< {scantron_id: 100000000 }
    res
  end
  
  def list_invalid_attribs
    [
      {
        scantron_id: 1000000000
      },
      {
        scantron_id: 'asjfjgsf'
      },
      {
        scantron_id: nil
      },
      {
        scantron_id: ''
      }
    ]
  end
  
  def new_attribs
    @new_attribs = {
      scantron_id: rand(100000000)
    }
  end
  
  
  
  def create_item att=nil
    att ||= valid_attribs
    
    create_sources
    @scantron = create_master.scantrons.create! att
  end
  
end
