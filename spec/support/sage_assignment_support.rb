module SageAssignmentSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    
    
    
    (1..20).each do |l|
      res << {
        
      }
    end
    
    res
  end
  
  def list_invalid_attribs
    [
      {
        sage_id: 1000000
      },
      {
        sage_id: 'asjfjgsf'
      },
      {
        sage_id: nil
      },
      {
        sage_id: ''
      },
      {
        sage_id: 0
      }
    ]
  end
  
  def new_attribs
    @new_attribs = {
      sage_id: rand(999998) + 1
    }
  end
  
  
  
  def create_item att=nil, master=nil
    att ||= valid_attribs
    master ||= create_master
    @sage_assignment = master.sage_assignments.create! att
  end
  
end
