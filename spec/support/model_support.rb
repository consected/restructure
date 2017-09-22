require "#{::Rails.root}/spec/support/seed_support"
module ModelSupport
  
  UserPrefix = 'g-ttuser-'
  UserDomain = 'testing.com'
  
  def seed_database
    Rails.logger.info "Starting seed setup"
    SeedSupport.setup
  end
  
  def gen_username r
    
    "#{UserPrefix}#{r}@#{UserDomain}"
  end
  
  def pick_one_from objs
    objs[rand objs.length]
  end
  
  def create_user r=nil, extra='', opt={}
    
    unless r      
      r = Time.new.to_f.to_s 
    end
    good_email = gen_username("#{r}-#{extra}-")
    
    
    admin, _ = create_admin
    user = User.create! email: good_email, current_admin: admin
    good_password = user.password
    @user = user
    
    if opt[:create_msid]
      UserAuthorization.create! current_admin: @admin, user: user, has_authorization: :create_msid
    end
    
    [user, good_password]    
  end

  def create_admin  r=nil
    a = Admin.order(id: :desc).first
    unless r
      r = 1
      r = a.id + 1 if a
    end
    good_admin_email = "d-testadmin-tester#{r}@testing.com"

    admin = Admin.create! email: good_admin_email
    good_admin_password = admin.password
    @admin = admin
    [admin, good_admin_password]
  end    
end
