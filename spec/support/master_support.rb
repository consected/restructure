require 'support/seeds'
module MasterSupport
  
  def create_sources
    
    if GeneralSelection.where(item_type: 'addresses_source').length == 0
      GeneralSelection.create! item_type: 'addresses_source', name: 'NFL', value: 'nfl', admin: auto_admin
      GeneralSelection.create! item_type: 'addresses_source', name: 'NFLPA', value: 'nflpa', admin: auto_admin
      
    end
  end
  
  
  def create_master user=nil
    user ||= @user
    master = Master.create
    master.current_user = user
    master.save!
    
    create_sources
    
    @master_id = master.id
    @master = master
  end

  def create_items 
    if respond_to? :list_valid_attribs
      list_valid_attribs.each do |l|
        create_item l
      end
    else
      create_item valid_attribs
    end
    
  end
  
  def opt(bd)
    (rand(1000) > 500 ? bd : nil)
  end
  
  
  def invalid_attribs
    pick_from list_invalid_attribs      
  end

  def valid_attribs
    pick_from list_valid_attribs      
  end
  
  
  def new_attribs_downcase
    
    @new_attribs.each {|k,att| @new_attribs[k] = (att.is_a?(String) ? att.downcase : att) }
  end
  
   def resp 
     JSON.parse(response.body)
   end
     
   def pick_one
     res = (rand(1000) > 500)
     Rails.logger.info "Pick one returned #{res}"
     return res
   end
   
   def pick_from list
     r = rand(list.length)
     list[r]
   end
   
end
