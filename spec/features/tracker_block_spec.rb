require 'rails_helper'

describe "tracker block", js: true, driver: :app_firefox_driver do
  
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  
  before(:all) do
    
    create_admin
    
    #sp = SubProcess.first
    
    ProtocolEvent.enabled.each do |d|
      d.update! disabled:true, current_admin: @admin#, sub_process: sp
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
    
    login 
      
  end



  def expect_tracker_date_to_be_today
    sleep 0.01
    f = find('#tracker_event_date')
    d = DateTime.now
    expect(f.value).to match(/0?#{d.month}\/0?#{d.day}\/#{d.year}/)
  end
  
  
  it "should create a new tracker item" do
    
    visit "/masters/search"

    # Switch to advanced search form
    within '#simple_search_master' do       
      find('#master_general_infos_attributes_0_first_name').click
    end
     within '.advanced-form-selections' do           
      click_button "Advanced Search"
    end
    
    # Wait for the advance form collapse animation to complete
    expect(page).to have_css '#master-search-advanced-form.in'    
    
    
    # Search for the player
    within '#advanced_search_master' do
      click_link 'clear fields'
      fill_in "master_player_infos_attributes_0_first_name", with: @full_player_info.first_name
      fill_in "master_player_infos_attributes_0_last_name", with: "#{@full_player_info.last_name}"
      find("\#master_player_infos_attributes_0_last_name").send_keys :tab
    end
    
    have_css '#advanced_search_master.ajax-running'
    have_css "#master_results_block"
    expect(page).to have_css "#master_results_block", text: ''
    have_css "#search_count"
    expect(page).to have_css "#search_count", text: /[0-9]+/, wait: 10
    expect(page).not_to have_css '#advanced_search_master.ajax-running'
    
    # Check we got some results
    items = page.all(:css, '.master-expander')
    expect(items.length).to be > 0
    
    # Ensure all the results match what we searched for
    page.all(:css, '.master-expander .player-info-header .player-names').each do |el|
      expect(el.text).to match(/#{@full_player_info.first_name.capitalize}.*/)
    end
    
    # Now jump into the record result    
    h = open_player_element items.first, items
    
    # Open the tracker panel if there are no items in it and it is collapsed
#    t = all('[data-template="tracker-badge-template"]')
#    if t.first.text == '0'
#      t.click
#    end    
    have_css ".tracker-block.collapse.in"
    

    # Validate that we don't already have a protocol / sub process tracked for this player
    protocol = Protocol.selectable.first
    sps = protocol.sub_processes.enabled
    
    sp = nil
    pe = nil
    pe_orig = nil
    pes = nil
    sp_orig = nil
    while pe.nil? do
      sp = pick_one_from sps
      sp_orig = sp
      pes = sp.protocol_events.enabled.reload    
      pe = pes[0]    
      pe_orig = pe
    end
    
    have_css "##{h}.tracker-block.collapse.in"
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
      expect_tracker_date_to_be_today
      click_button "Create Tracker"
    end
    
    # After a moment the tracker will show the newly created item
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] span.record-meta', text: "by #{@user.email}"
    
    
    have_css '.tracker-tree-results tbody.new-block'
    dismiss_modal
    sleep 1
    dismiss_modal
    sleep 1
    # Now add a new item to be merged within the current protocol
    pe = pes[1]    
    within ".tracker-tree-results" do
      click_link "add tracker record"
    end
    
    have_css ".tracker-tree-results #new_tracker"    
    have_css ".tracker-tree-results #new_tracker"    

    within ".tracker-tree-results #new_tracker" do
      select protocol.name, from: 'tracker_protocol_id'
      find("#tracker_sub_process_id[data-parent-filter-id='#{protocol.id}'] option[value='#{sp.id}']").select_option
        
      find("#tracker_protocol_event_id[data-parent-filter-id='#{sp.id}'] option[value='#{pe.id}']").select_option      
      # We have to set this explicitly rather than use fill_in, since the shim for date fields in Firefox creates a separate input

      find('.tracker-event_date input').set '02/02/2030'
      click_button "Create Tracker"
    end
    
    # Validate the new item was created as the current record of the same protocol
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] span.record-meta', text: "by #{@user.email}"
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] .tracker-event_date', text: /0?2\/0?2\/2030/
    # Now try an earlier item
    within ".tracker-tree-results" do
      click_link "add tracker record"
    end
    
    have_css ".tracker-tree-results #new_tracker"    
    have_css ".tracker-tree-results #new_tracker"    

    within ".tracker-tree-results #new_tracker" do
      select protocol.name, from: 'tracker_protocol_id'
      find("#tracker_sub_process_id[data-parent-filter-id='#{protocol.id}'] option[value='#{sp.id}']").select_option
        
      find("#tracker_protocol_event_id[data-parent-filter-id='#{sp.id}'] option[value='#{pe.id}']").select_option      
      # We have to set this explicitly rather than use fill_in, since the shim for date fields in Firefox creates a separate input

      find('.tracker-event_date input').set '01/02/2010'
      click_button "Create Tracker"
    end
    
    # Validate the new item was NOT created as the current record of the same protocol
    expect(page).to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] span.record-meta', text: "by #{@user.email}"
    expect(page).not_to have_css 'tbody.index-created[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] .tracker-event_date', text: "1/2/2010"
    
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
      fill_in "master_player_infos_attributes_0_last_name", with: "#{@full_player_info.last_name}"
      find("\#master_player_infos_attributes_0_last_name").send_keys :tab
    
      select protocol.name, from: 'master_trackers_attributes_0_protocol_id'
      find("#master_trackers_attributes_0_sub_process_id option[value='#{sp.id}']").select_option      
      find("#master_trackers_attributes_0_protocol_event_id option[value='#{pe.id}']").select_option      
    end
    
    have_css '.master-expander'
    items = page.all(:css, '.master-expander')
    
    ### Occasionally we fail here, perhaps due to bad test data?????
    expect(items.length).to be > 0
    
    # Open the first person
    h = open_player_element items.first, items
    
    # We know the tracker has records, so open it 
    have_css ".tracker-block.collapse.in"

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

    
    have_css('.master-expander')
    # The results should show at least this one player
    items = page.all(:css, '.master-expander')
    expect(items.length).to be > 0
        
    h = open_player_element items.first, items
    
    within "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}']" do
      click_link 'edit tracker record'
    end
    

    pe_new = nil
    sp_new = nil
    pes_new = nil
    while pe_new.nil? || sp_new.nil?
      sp_new = pick_one_from sps    
      pes_new = sp_new.protocol_events.enabled.reload    

      
      pe_new = pick_one_from pes_new
    end
    
    dismiss_modal
      
    within "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] form" do
      find("#tracker_sub_process_id[data-parent-filter-id='#{protocol.id}'] option[value='#{sp_new.id}']").select_option
        
      find("#tracker_protocol_event_id[data-parent-filter-id='#{sp_new.id}'] option[value='#{pe_new.id}']").select_option

      expect_tracker_date_to_be_today

      # We have to set this explicitly rather than use fill_in, since the shim for date fields in Firefox creates a separate input
      find('.tracker-event_date input').set '10/01/2125'
      click_button "Update Tracker"
    end
    
    have_css '.master-expander'
    expect(page).to have_css "##{h} " + 'tbody[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] span.record-meta', text: "by #{@user.email}"
    expect(page).to have_css "##{h} " + 'tbody[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"] .tracker-event_date', text: /10\/0?1\/2125/

    
    
    within "##{h} " + 'tbody[data-template="tracker-result-template"][data-tracker-protocol="'+protocol.name.downcase+'"]' do
      click_link 'show history'
    end    
    
    have_css "##{h} " + 'tbody.tracker-history.collapse.in'
        
    # The previous item is there still
    expect(page).to have_css "##{h} " + 'tbody.tracker-history .tracker-history-sub_process_name', text: /#{sp_orig.name}/i
    expect(page).to have_css "##{h} " + 'tbody.tracker-history .tracker-history-event_name', text: /#{pe_orig.name}/i
    expect(page).to have_css "##{h} " + 'tbody.tracker-history .tracker-history-sub_process_name', text: /#{sp.name}/i
    expect(page).to have_css "##{h} " + 'tbody.tracker-history .tracker-history-event_name', text: /#{pe.name}/i
    
  end
 
  after(:all) do
    
  end
end

