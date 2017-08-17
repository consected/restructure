module UserAuthorizationSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    user, _ = ControllerMacros.create_user
    (1..5).each do |l|
      res << {
        user_id: user.id,
        
        has_authorization: UserAuthorization.authorizations[l-1],
        disabled: false
      }
    end
    
    res
  end
  
  def list_invalid_attribs
    [
      {
        has_authorization: nil
      },
      {
        user_id: nil
      },      
      {
        has_authorization: 'unknown'
      }
    ]
  end
  
  def list_invalid_update_attribs
 
    [      
      
      {
        has_authorization: nil
      },
      {
        user_id: nil
      },      
      {
        has_authorization: 'unknown'
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
    att[:current_admin] = admin||@admin 
    @user_authorization = UserAuthorization.create! att
  end
  
end
