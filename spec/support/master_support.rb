require 'support/seeds'
module MasterSupport
  
  
    
  def objects_symbol
    object_class.to_s.underscore.pluralize.to_sym
  end
  
  def object_symbol
    object_class.to_s.underscore.to_sym
  end
  
  def item_id
    item.to_param
  end
  
  def edit_form_admin
    "#{objects_symbol}/edit"
  end
  
  def edit_form_user
    "#{objects_symbol}/_edit_form"
  end
  
  def create_sources
    
    if GeneralSelection.where(item_type: 'addresses_source').length == 0
      GeneralSelection.create! item_type: 'addresses_source', name: 'NFL', value: 'nfl', admin: auto_admin
      GeneralSelection.create! item_type: 'addresses_source', name: 'NFLPA', value: 'nflpa', admin: auto_admin
      
    end
  end
  
  
  def create_master user=nil, att=nil
    user ||= @user
    
    att ||= { msid: rand(10000000), pro_id: rand(1000000) }
    
    master = Master.create! att
    master.current_user = user
    master.save!
    
    create_sources
    
    @master_id = master.id
    @master = master
  end

  def create_items from_list=:list_valid_attribs, master=nil
    
    @created_count = 0
    @exceptions = []
    @list = send(from_list)
    @created_items = []
    @list.each do |l|
      begin
        res = create_item l, master        
        if res
          @created_count+=1 
          @created_items << res
        end
      rescue => e
        @exceptions << e
      end
      
    end

  end
  
  def check_all_records_failed
    
    expect(@exceptions.length).to eq(@list.length), "Not every test caused the record creation to fail"
      
    @exceptions.each do |e|
      expect(e).to be_a ActiveRecord::RecordInvalid
    end

    expect(@created_count).to eq 0

  end
  
  def opt(bd)
    (rand(1000) > 500 ? bd : nil)
  end
  
  
  def invalid_attribs
    pick_from list_invalid_attribs      
  end

  def invalid_update_attribs
    pick_from list_invalid_update_attribs      
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
   
   
   def first_names
     ['Glenn', 'Mose', 'Leandro', 'Damien', 'Claude', 'Kelvin', 'Rudolf', 'Shad', 'Wm', 'Nathanial', 'Dominick', 'Carlton', 'Arthur', 'Jame', 'Doug', 'Tod', 'Nickolas', 'Israel', 'Domingo', 'Donovan', 'Scott', 'Carol', 'Cesar', 'Ismael', 'Michael', 'Reyes', 'Blake', 'Odis', 'Brant', 'Luther', 'Mauricio', 'Olin', 'Victor', 'Milford', 'Tony', 'Aubrey', 'Dana', 'Berry', 'Salvador', 'Parker', 'Marcelo', 'Ray', 'Gerard', 'Miguel', 'Cornelius', 'Coleman', 'Dwayne', 'Wilbert', 'Leonardo', 'Bud']
   end

   def last_names
     ['Basilio', 'Portillo', 'Just', 'Northup', 'Ankrom', 'Seto', 'Dominick', 'Dehn', 'Ramirez', 'Polley', 'Detwiler', 'Mahone', 'Mchenry', 'Fink', 'Keesling', 'Shaikh', 'Mazurek', 'Brashears', 'Arel', 'Perrella', 'Ver', 'Fitzgibbon', 'Tefft', 'Burruel', 'Boulter', 'Klatt', 'Linger', 'Kyser', 'Silversmith', 'Tregre', 'Millett', 'Welk', 'Down', 'Bate', 'Mchaney', 'Pope', 'Wagoner', 'Mcdougal', 'Nolan', 'Melendez', 'Imler', 'Way', 'Crimmins', 'Korando', 'Cohen', 'Keisler', 'Hardman', 'Sallis', 'Pinder', 'Acey']
   end
   
   def other_names
     ['Dingus', 'Vella', 'Bowland', 'Sackett', 'Arias', 'Pannell', 'Swinehart', 'Bezio', 'Goble', 'Greenley', 'Sides', 'Utz', 'Andres', 'Witt', 'Mraz', 'Cheever', 'Muma', 'Diana', 'Weston', 'Lennox', 'Carasco', 'Stavros', 'Platts', 'Bunyard', 'Bahena', 'Marciano', 'Normandeau', 'Small', 'Sellars', 'Bahr', 'Yard', 'Hankerson', 'Abram', 'Bouffard', 'Arruda', 'Faulkenberry', 'Sirmans', 'Mabon', 'Chavarin', 'Uphoff', 'Billingslea', 'Montandon', 'Neilson', 'Repka', 'Delucia', 'Juarbe', 'Govan', 'Mattern', 'Bendel', 'Flatley']
   end
   
   def colleges
     ["harvard", "dartmouth", "yale", "ucla", "boston college", "boston university", "northeastern", "mit"]
   end
   
end
