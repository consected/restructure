require 'rails_helper'

describe "advanced search", js: true do
  
  include ModelSupport
  include MasterDataSupport
  
  before(:all) do
    seed_database
    create_data_set
    
    
    @user, @good_password  = create_user
    @good_email  = @user.email
    
  end

  before :each do
    user = User.where(email: @good_email).first
    expect(user).to be_a User
    expect(user.id).to equal @user.id
    
    #login_as @user, scope: :user
    
    visit "/users/sign_in"
    within '#new_user' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password
      click_button "Log in"
    end
    expect(page).to have_css ".flash .alert", text: "× Signed in successfully"
    
  end

  def logout 
    find('.navbar-right li:nth-child(2) .dropdown-toggle').click
    click_link 'logout'

  end
  
  it "should test switching to advanced search and search a player" do
    
    visit "/masters/search"
    
    within '#simple_search_master' do 
      fill_in "Last name", with: 'bad1'
      click_button "submit"
    end
    
    expect(page).to have_css "#master_results_block", text: "No Results"

    
    within '#simple_search_master' do 
      fill_in "Last name", with: "bad1\t"
    end
    
    expect(page).to have_css "#master_results_block", text: "No Results"

   
    within '#simple_search_master' do       
      find('#master_general_infos_attributes_0_first_name').click
    
      click_link "advanced search"
    end
    
    # Wait for the advance form collapse animation to complete
    expect(page).to have_css '#master-search-advanced.in'    
    
    within '#advanced_search_master' do
      click_link 'clear fields'
      fill_in "master_player_infos_attributes_0_first_name", with: @full_player_info.first_name
      find("#master_player_infos_attributes_0_last_name").click
    end
    
    expect(page).to have_css '#advanced_search_master.ajax-running'
    # wait a while!
    expect(page).to have_css "#master_results_block", text: ''    
    expect(page).to have_css "#search_count", text: /[0-9]+/, wait: 10
    
    page.all(:css, '.master-expander .player-info-header .player-names').each do |el|
      expect(el.text).to match /#{@full_player_info.first_name.capitalize}.*/    
    end
    
    
    expect(page).not_to have_css '#advanced_search_master.ajax-running'
    
    within '#advanced_search_master' do
      fill_in "master_player_infos_attributes_0_last_name", with: "#{@full_player_info.last_name}"      
      find("#master_player_infos_attributes_0_middle_name").click
    end
    
    # wait a while, maybe
    have_css '#advanced_search_master.ajax-running'
    
    
    expect(page).to have_css "#search_count", text: /[0-9]+/
    
    page.all(:css, '.master-expander .player-info-header .player-names').each do |el|
      expect(el.text).to match /#{@full_player_info.first_name.capitalize}.+#{@full_player_info.last_name.capitalize}.*/
    end
    
    page.all(:css, '.master-expander').first.click
    
    # expect the player section to expand
    expect(page).to have_css "#master-#{@full_player_info.master_id}-player-infos.collapse.in"
    
    expect(page).to have_css "#player-info-#{@full_player_info.master_id}-#{@full_player_info.id} .player-info-first_name", text: "first name #{@full_player_info.first_name.capitalize}"
    
    protocol = Protocol.selectable.first
    
    within '#advanced_search_master' do
      
      select protocol.name, from: "master_trackers_attributes_0_protocol_id"
    end
    
    # wait a while, maybe
    have_css '#advanced_search_master.ajax-running'
    
    
    find "#master_results_block.search-status-done", wait: 5
    
    find ".master-expander", match: :first, wait: 5    
    
    expect(page).to have_css "#search_count", text: /[0-9]+/, wait: 10
    
    
    me = page.all(:css, '.master-expander')
    
    me.each do |el|
      expect(el.text).to match /#{@full_player_info.first_name.capitalize}.+#{@full_player_info.last_name.capitalize}.*/
      
      
      
      el.click unless me.length == 1 
                  
      find "#master-#{@full_player_info.master_id}-player-infos.collapse.in", wait: 5
      
      h = el[:href].split('#').last
      
      expect(page).to have_css("##{h} .tracker-block .tracker-protocol_name .cell-holder", text: protocol.name), "Expected: #{@full_master_record.trackers.map {|m| m.protocol_name} }"
    end
    
    page.all(:css, '.master-expander').first.click
    
    logout
    
  end

  it "searches tracker for items not in the tracker" do
     
    visit "/masters/search"
    within '#simple_search_master' do       
      find('#master_general_infos_attributes_0_first_name').click
    
      click_link "advanced search"
    end

     # Wait for the advance form collapse animation to complete
    expect(page).to have_css '#master-search-advanced.in'      
        
    sprot = Protocol.selectable
    
    expect(sprot.length).to be > 0
    
    protocol = pick_one_from(sprot)
    sp = pick_one_from(protocol.sub_processes)
    within '#advanced_search_master' do
      
      select protocol.name, from: "master_trackers_attributes_0_protocol_id"
      select sp.name, from: "master_trackers_attributes_0_sub_process_id"      
    end
    
    # wait a while, maybe
    expect(page).to have_css "#search_count", text: ''
    have_css '#advanced_search_master.ajax-running'    
    
    find "#master_results_block.search-status-done", wait: 10
    
    find ".master-expander", match: :first
    
    #expect(page).to have_css "#search_count", text: /[0-9]+.*/
    
    items = page.all(:css, '.master-expander')

    expect(items.length).to be > 0
    
    done = 0
    
    items.each do |el|
          
      el.click      if items.length > 1
      
      
      
      b = all('button[data-dismiss="modal"]')
      b.first.click if b && b.length > 0 
      
      h = el[:href].split('#').last      
      
      find "##{h}.collapse.in", wait: 5
      expect(page).to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-protocol_name", text: protocol.name
      expect(page).to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-sub_process_name", text: sp.name.capitalize

      done += 1
      
      break if done > 5
    end
    

    
  end
 
  after(:all) do
    
  end
end

