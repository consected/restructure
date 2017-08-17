module CollegeSupport
  include MasterSupport
  
  def create_admin  r=nil
    a = Admin.order(id: :desc).first
    unless r
      r = 1
      r = a.id + 1 if a
    end
    good_admin_email = "dd-testadmin-tester#{r}@testing.com"

    admin = Admin.create! email: good_admin_email
    good_admin_password = admin.password
    @admin = admin
    [admin, good_admin_password]
  end    
  
  def list_valid_attribs
    res = []
    admin = create_admin.first
    
    (1..5).each do |l|
      res << {
        name: "College #{l}",        
        disabled: false,
        current_admin: admin
      }
    end
    (1..5).each do |l|
      res << {
        name: "Dis College #{l}",        
        disabled: true,
        current_admin: admin
      }
    end            
    res
  end
  
  def list_invalid_attribs
    admin1 = create_admin.first
    College.create! name: "dup college", current_admin: admin1
    admin = create_admin.first
    [
      {
        name: nil,
        current_admin: admin
      },
      {
        name: "Good with bad synonym",
        synonym_for_id: 9999999,
        current_admin: admin
      },
      {
        name: "dup college",
        current_admin: admin
      }
    ]
  end
  
  def list_invalid_update_attribs
    [      
      {
        name: nil,
        current_admin: create_admin.first
      }
    ]
  end  
  
  def new_attribs
    prev_college = College.create! name: "ref college", current_admin: create_admin.first
    @new_attribs = {  
      
      synonym_for_id: prev_college.id      
    }
    
    
  end
  
  
  
  def create_item att=nil, admin=nil
    att ||= valid_attribs    
    att[:current_admin] ||= admin  if admin.is_a? Admin
    
    @college = College.create! att
  end
  
end
