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

  it "should test switching to advanced search" do
    
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
    expect(page).to have_css "#search_count", text: /[0-9]+/
    
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
    
    
    protocol = @full_trackers[rand @full_trackers.length].protocol
    within '#advanced_search_master' do
      
      select protocol.name, from: "master_trackers_attributes_0_protocol_id"
      find("#master_trackers_attributes_0_sub_process_id").click
    end
    
    # wait a while, maybe
    have_css '#advanced_search_master.ajax-running'
    
    
    expect(page).to have_css "#search_count", text: /[0-9]+/
    
    page.all(:css, '.master-expander').each do |el|
      expect(el.text).to match /#{@full_player_info.first_name.capitalize}.+#{@full_player_info.last_name.capitalize}.*/
      
      el.click
      
      h = el[:href].split('#').last
      
      expect(page).to have_css "##{h} .tracker-block .tracker-protocol_name", text: protocol.name
      
    end
    
    page.all(:css, '.master-expander').first.click
    
    
    
    find('.navbar-right li:nth-child(2) .dropdown-toggle').click
    click_link 'logout'
  end
  
  after(:all) do
    
  end
end

