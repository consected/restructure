module CollegeSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    
    (1..5).each do |l|
      res << {
        name: "College #{l}",        
        disabled: false
      }
    end
    (1..5).each do |l|
      res << {
        name: "Dis College #{l}",        
        disabled: true
      }
    end
    res
  end
  
  def list_invalid_attribs
    
    dup_college = College.create! name: "dup college"
    
    [
      {
        name: nil
      },
      {
        name: "Good with bad synonym",
        synonym_for_id: 9999999
      },
      {
        name: "dup college"
      }
    ]
  end
  
  def list_invalid_update_attribs
    [      
      {
        name: nil
      }
    ]
  end  
  
  def new_attribs
    prev_college = College.create! name: "ref college"
    @new_attribs = {  
      
      synonym_for_id: prev_college.id
    }
    
    
  end
  
  
  
  def create_item att=nil, admin=nil
    att ||= valid_attribs    
    att[:admin] = admin||@admin if admin.is_a? Admin
    
    @college = College.create! att
  end
  
end
