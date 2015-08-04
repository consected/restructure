module ManageUserSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    i = User.order(id: :desc).first.id
    
    
    (1..5).each do |l|
      res << {
        email: "tst-euser-#{i+l}@testmanage.com",        
        disabled: false
      }
    end
    (1..5).each do |l|
      res << {
        email: "dis-tst-euser-#{i+l}@testmanage.com",
        disabled: true
      }
    end
    res
  end
  
  def list_invalid_attribs
    [
      {
        email: nil
      }
    ]
  end
  
  def list_invalid_update_attribs
    [      
      {
        email: nil
      }
    ]
  end  
  
  def new_attribs
    @new_attribs = {
      disabled: true
    }
  end
  
  
  def create_item att=nil, admin=nil
    att ||= valid_attribs    
    att[:admin] = admin||@admin    
    @manage_user = User.create! att
  end
  
end
