require 'rails_helper'

describe "tracker block", js: true do
  
  include ModelSupport
  include MasterDataSupport
  
  before(:all) do
    
    create_admin
    
    sp = SubProcess.first
    
    ProtocolEvent.enabled.each do |d|
      d.update! disabled:true, current_admin: @admin, sub_process: sp
    end
    
    seed_database
    create_data_set no_trackers: true
    
    
    @user, @good_password  = create_user
    @good_email  = @user.email
    
  end

  before :each do
    user = User.where(email: @good_email).first
    expect(user).to be_a User
    expect(user.id).to equal @user.id
    
    #login_as @user, scope: :user
    
    login @good_email, @good_password
      
  end
  
  def login email, pw
    visit "/users/sign_in"
    within '#new_user' do
      fill_in "Email", with: email
      fill_in "Password", with: pw
      click_button "Log in"
    end
    expect(page).to have_css ".flash .alert", text: "× Signed in successfully"
    
  end

  def logout 
    find('.navbar-right li:nth-child(2) .dropdown-toggle').click
    click_link 'logout'

  end
  
  it "should create a new tracker item" do
    
    visit "/masters/search"
    
    within '#simple_search_master' do       
      find('#master_general_infos_attributes_0_first_name').click
    
      click_link "advanced search"
    end
    
    # Wait for the advance form collapse animation to complete
    expect(page).to have_css '#master-search-advanced.in'    
    
    within '#advanced_search_master' do
      click_link 'clear fields'
      fill_in "master_player_infos_attributes_0_first_name", with: @full_player_info.first_name
      fill_in "master_player_infos_attributes_0_last_name", with: "#{@full_player_info.last_name}\t"
      #fill_in "master_player_infos_attributes_0_birth_date", with: @full_player_info.birth_date.strftime("%m/%d/%Y")      
      #find('.tracker-event_date input').set '01/02/2010'
    end
    
    expect(page).to have_css '#advanced_search_master.ajax-running'
    # wait a while!
    expect(page).to have_css "#master_results_block", text: ''    
    expect(page).to have_css "#search_count", text: /[0-9]+/, wait: 10
    
    page.all(:css, '.master-expander .player-info-header .player-names').each do |el|
      expect(el.text).to match /#{@full_player_info.first_name.capitalize}.*/    
    end
    
    
    expect(page).not_to have_css '#advanced_search_master.ajax-running'
        
    items = page.all(:css, '.master-expander')

    expect(items.length).to be > 0
    
    done = 0
    
    protocol = Protocol.selectable.first
    sps = protocol.sub_processes.enabled
    sp = pick_one_from sps
    
    el = items.first 
          
    el.click      if items.length > 1
        
    b = all('button[data-dismiss="modal"]')
    b.first.click if b && b.length > 0 
        
    h = el[:href].split('#').last      
    
    find "##{h}.collapse.in", wait: 5

    t = all('[data-template="tracker-badge-template"]')
    if t.first.text == '0'
      t.click
    end
    
    find '.tracker-block.collapse.in', wait: 5

    
    expect(page).not_to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-protocol_name", text: protocol.name
    expect(page).not_to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-sub_process_name", text: sp.name.titleize

    
    
    
    pes = sp.protocol_events.enabled.reload
    
    puts "PES: #{pes.map {|p| "#{p.id} #{p.name}" } }"    
    pe = pes[0]
    
    pe_orig = pe

    within ".tracker-tree-results" do
      click_link "add tracker record"
    end
    
    find '.tracker-tree-results #new_tracker', wait: 5
    
    within ".tracker-tree-results #new_tracker" do
      select protocol.name, from: 'tracker_protocol_id'

      find("#tracker_sub_process_id[data-parent-filter-id='#{protocol.id}'] option[value='#{sp.id}']").select_option
        
      find("#tracker_protocol_event_id[data-parent-filter-id='#{sp.id}'] option[value='#{pe.id}']").select_option
      
      click_button "Create Tracker"
    end
      
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] span.record-meta', text: "by #{@user.email}"
    
    pe = pes[1]
    within ".tracker-tree-results" do
      click_link "add tracker record"
    end
    
    find '.tracker-tree-results #new_tracker', wait: 5
    
    within ".tracker-tree-results #new_tracker" do
      select protocol.name, from: 'tracker_protocol_id'
      find("#tracker_sub_process_id[data-parent-filter-id='#{protocol.id}'] option[value='#{sp.id}']").select_option
        
      find("#tracker_protocol_event_id[data-parent-filter-id='#{sp.id}'] option[value='#{pe.id}']").select_option      
      # We have to set this explicitly rather than use fill_in, since the shim for date fields in Firefox creates a separate input
      find('.tracker-event_date input').set '01/02/2010'
      click_button "Create Tracker"
    end
      
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] span.record-meta', text: "by #{@user.email}"
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] .tracker-event_date', text: "1/2/2010"
    
    within 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"]' do
      click_link 'show history'
    end
    
    find 'tbody.tracker-history.collapse.in', wait: 5
        
    expect(page).to have_css 'tbody.tracker-history .tracker-history-event_name', text: pe_orig.name.titleize
    expect(page).to have_css 'tbody.tracker-history .tracker-history span.record-meta', text: "by #{@user.email}"    
    
    
  end
 
  after(:all) do
    
  end
end

