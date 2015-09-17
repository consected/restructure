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
  
  def dismiss_modal
    b = all('button[data-dismiss="modal"]')
    b.first.click if b && b.length > 0 
  end
  
  def open_player_element el, items
    el.click      if items.length > 1 # it opens automatically if there is only one result    
    dismiss_modal        
    h = el[:href].split('#').last          
    find "##{h}.collapse.in", wait: 5
    h
  end
  
  it "should create a new tracker item" do
    
    visit "/masters/search"

    # Switch to advanced search form
    within '#simple_search_master' do       
      find('#master_general_infos_attributes_0_first_name').click
    
      click_link "advanced search"
    end
    
    # Wait for the advance form collapse animation to complete
    expect(page).to have_css '#master-search-advanced.in'    
    
    
    # Search for the player
    within '#advanced_search_master' do
      click_link 'clear fields'
      fill_in "master_player_infos_attributes_0_first_name", with: @full_player_info.first_name
      fill_in "master_player_infos_attributes_0_last_name", with: "#{@full_player_info.last_name}\t"      
    end
    
    expect(page).to have_css '#advanced_search_master.ajax-running'
    expect(page).to have_css "#master_results_block", text: ''    
    expect(page).to have_css "#search_count", text: /[0-9]+/, wait: 10
    expect(page).not_to have_css '#advanced_search_master.ajax-running'
    
    # Check we got some results
    items = page.all(:css, '.master-expander')
    expect(items.length).to be > 0
    
    # Ensure all the results match what we searched for
    page.all(:css, '.master-expander .player-info-header .player-names').each do |el|
      expect(el.text).to match /#{@full_player_info.first_name.capitalize}.*/    
    end
    
    # Now jump into the record result    
    h = open_player_element items.first, items
    
    # Open the tracker panel if there are no items in it and it is collapsed
    t = all('[data-template="tracker-badge-template"]')
    if t.first.text == '0'
      t.click
    end    
    find '.tracker-block.collapse.in', wait: 5

    # Validate that we don't already have a protocol / sub process tracked for this player
    protocol = Protocol.selectable.first
    sps = protocol.sub_processes.enabled
    sp = pick_one_from sps
    sp_orig = sp
    pes = sp.protocol_events.enabled.reload    
    pe = pes[0]    
    pe_orig = pe
    
    expect(page).not_to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-protocol_name", text: protocol.name
    expect(page).not_to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-sub_process_name", text: sp.name.titleize


    # Now add a new tracker item
    within ".tracker-tree-results" do
      click_link "add tracker record"
    end
    
    # Wait for the new tracker form to show
    find '.tracker-tree-results #new_tracker', wait: 5
    
    # Enter new tracker details
    within ".tracker-tree-results #new_tracker" do
      select protocol.name, from: 'tracker_protocol_id'
      find("#tracker_sub_process_id[data-parent-filter-id='#{protocol.id}'] option[value='#{sp.id}']").select_option        
      find("#tracker_protocol_event_id[data-parent-filter-id='#{sp.id}'] option[value='#{pe.id}']").select_option      
      click_button "Create Tracker"
    end
    
    # After a moment the tracker will show the newly created item
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] span.record-meta', text: "by #{@user.email}"
    
    # Now add a new item to be merged within the current protocol
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
    
    # Validate the new item was created as the current record of the same protocol
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] span.record-meta', text: "by #{@user.email}"
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] .tracker-event_date', text: "1/2/2010"
    
    # Click into the history to check the previous record is now visible there
    within 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"]' do
      click_link 'show history'
    end
    
    find 'tbody.tracker-history.collapse.in', wait: 5
        
    expect(page).to have_css 'tbody.tracker-history .tracker-history-event_name', text: pe_orig.name.titleize
    expect(page).to have_css 'tbody.tracker-history .tracker-history span.record-meta', text: "by #{@user.email}"    
    
    
    # Search for the player by current Protocol, subprocess and event
    dismiss_modal
    click_link 'clear fields'    
    within '#advanced_search_master' do

      fill_in "master_player_infos_attributes_0_first_name", with: @full_player_info.first_name
      fill_in "master_player_infos_attributes_0_last_name", with: "#{@full_player_info.last_name}\t"
    
      select protocol.name, from: 'master_trackers_attributes_0_protocol_id'
      find("#master_trackers_attributes_0_sub_process_id option[value='#{sp.id}']").select_option      
      find("#master_trackers_attributes_0_protocol_event_id option[value='#{pe.id}']").select_option      
    end
    
    items = page.all(:css, '.master-expander')
    expect(items.length).to be > 0
    
    # Open the first person
    h = open_player_element items.first, items
    
    # We know the tracker has records, so open it 
    find '.tracker-block.collapse.in', wait: 5

    # Validate the current protocol item appears as expected
    expect(page).to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-protocol_name", text: protocol.name
    expect(page).to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-sub_process_name", text: sp.name.capitalize
    expect(page).to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-event_name", text: /#{pe.name}/i

    # Show the history
    within 'tbody[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"]' do
      click_link 'show history'
    end    
    find 'tbody.tracker-history.collapse.in', wait: 5
        
    # The previous item is there still
    expect(page).to have_css 'tbody.tracker-history .tracker-history-event_name', text: /#{pe_orig.name}/i
    expect(page).to have_css 'tbody.tracker-history .tracker-history span.record-meta', text: "by #{@user.email}"    

    # Search for the player by current Protocol, subprocess and event, but not the historical event    
    within '#advanced_search_master' do
      
      find("#master_not_tracker_histories_attributes_0_sub_process_id option[value='#{sp.id}']").select_option      
      find("#master_not_tracker_histories_attributes_0_protocol_event_id option[value='#{pe_orig.id}']").select_option      
    end
    
    # We expect no results, as we know this player has that historical record
    expect(page).to have_css '.search_count', text: '0'
    
    
    # Now remove the Not condition, and instead require the historical item
    within '#advanced_search_master' do
      
      find("#master_not_tracker_histories_attributes_0_sub_process_id option[value='']").select_option      
      find("#master_not_tracker_histories_attributes_0_protocol_event_id option[value='']").select_option      
      find("#master_tracker_histories_attributes_0_sub_process_id option[value='#{sp.id}']").select_option      
      find("#master_tracker_histories_attributes_0_protocol_event_id option[value='#{pe_orig.id}']").select_option      
    end

    # The results should show at least this one player
    items = page.all(:css, '.master-expander')
    expect(items.length).to be > 0
        
    h = open_player_element items.first, items
    
    within "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}']" do
      click_link 'edit tracker record'
    end
    

    
    sp_new = pick_one_from sps    
    pes_new = sp_new.protocol_events.enabled.reload    
    
    pe_new = pick_one_from pes_new
    
    dismiss_modal
      
    within "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] form" do
      find("#tracker_sub_process_id[data-parent-filter-id='#{protocol.id}'] option[value='#{sp_new.id}']").select_option
        
      find("#tracker_protocol_event_id[data-parent-filter-id='#{sp_new.id}'] option[value='#{pe_new.id}']").select_option      
      # We have to set this explicitly rather than use fill_in, since the shim for date fields in Firefox creates a separate input
      find('.tracker-event_date input').set '11/15/2012'
      click_button "Update Tracker"
    end
    
    
    expect(page).to have_css 'tbody[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] span.record-meta', text: "by #{@user.email}"
    expect(page).to have_css 'tbody[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] .tracker-event_date', text: "11/15/2012"

    
    
    within 'tbody[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"]' do
      click_link 'show history'
    end    
    find 'tbody.tracker-history.collapse.in', wait: 5
        
    # The previous item is there still
    expect(page).to have_css 'tbody.tracker-history .tracker-history-sub_process_name', text: /#{sp_orig.name}/i
    expect(page).to have_css 'tbody.tracker-history .tracker-history-event_name', text: /#{pe_orig.name}/i
    expect(page).to have_css 'tbody.tracker-history .tracker-history-sub_process_name', text: /#{sp.name}/i
    expect(page).to have_css 'tbody.tracker-history .tracker-history-event_name', text: /#{pe.name}/i
    
  end
 
  after(:all) do
    
  end
end

