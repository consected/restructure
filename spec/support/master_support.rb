require "#{::Rails.root}/spec/support/seeds"
module MasterSupport

  def seed_database
    Rails.logger.info "Starting seed setup"
    SeedSupport.setup
  end

  def setup_access resource_name=nil, resource_type: :table

    return if @path_prefix == "/admin"
    resource_name ||= objects_symbol

    uac = Admin::UserAccessControl.where(app_type: @user.app_type, resource_type: resource_type, resource_name: resource_name).first
    if uac
      uac.access = :create
      uac.disabled = false
      uac.current_admin = auto_admin
      uac.save
    else
      Admin::UserAccessControl.create! app_type: @user.app_type, access: :create, resource_type: resource_type, resource_name: resource_name, current_admin: auto_admin
    end

  rescue => e
    Rails.logger.debug "Failed to create access for #{resource_name}"
  end

  def edit_form_prefix
    @edit_form_prefix = nil
  end
  def edit_form_name
    @edit_form_name = nil
  end

  def objects_symbol
    object_class.to_s.ns_underscore.pluralize.to_sym
  end

  def object_symbol
    object_class.to_s.ns_underscore.to_sym
  end

  def objects_short_name
    object_class.to_s.split('::').underscore.pluralize
  end

  def custom_edit_form_prefix
    "/admin/#{objects_short_name.pluralize}"
  end

  def item_id
    item.to_param
  end

  def edit_form_admin
    unless defined? @edit_form_admin
      @edit_form_admin = nil
    end
    @edit_form_admin || "#{edit_form_prefix || custom_edit_form_prefix}/_form"
  end

  def edit_form_user
    "#{edit_form_prefix || objects_symbol}/#{edit_form_name || '_edit_form'}"
  end

  def create_sources name
    i = "#{name}_source"
    gs = Classification::GeneralSelection.active.where(item_type: i, value: ['nfl', 'nflpa'])
    if (gs.length) == 0
      Classification::GeneralSelection.create item_type: i, name: 'NFL', value: 'nfl', current_admin: auto_admin, create_with: true
      Classification::GeneralSelection.create item_type: i, name: 'NFLPA', value: 'nflpa', current_admin: auto_admin, create_with: true
    else
      gs.update_all create_with: true
      Rails.cache.clear
    end
  end

  def put_valid_attribs
    valid_attribs
  end


  def create_master user=nil, att=nil
    user ||= @user || create_user

    user.app_type ||= Admin::AppType.active.first

    att ||= { msid: rand(10000000), pro_id: rand(1000000) }

    master = Master.new att
    master.current_user = user
    master.save!

    setup_access
    setup_access :trackers



    @master_id = master.id
    @master = master
  end

  def create_items from_list=:list_valid_attribs, master_or_admin=nil, expect_failures=false

    @created_count = 0
    @exceptions = []
    @list = send(from_list)
    @created_items = []

    @list.each do |l|
      begin
        res = create_item l, master_or_admin
        if res
          @created_count+=1
          @created_items << res
        end
      rescue => e
        @exceptions << e
        unless expect_failures
          puts "Exceptions in create_items for #{l.inspect}: #{e.inspect} #{e.backtrace.join("\n")}"
          raise e
        end
      end
    end

  end

  def check_all_records_failed

    expect(@exceptions.length).to eq(@list.length), "Not every test caused the record creation to fail"

    @exceptions.each do |e|

      expect(e).to be_a(ActiveRecord::StatementInvalid) | be_a(ActiveRecord::RecordInvalid)
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
