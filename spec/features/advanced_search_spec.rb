require 'rails_helper'

describe "advanced search", js: true, driver: :app_firefox_driver do

  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

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

    login
  end


  it "should test switching to advanced search and search a player" do

    visit "/masters/search"

    within '#simple_search_master' do
      fill_in "Last name", with: 'bad1'
      click_button "search"
    end

    expect(page).to have_css "#master_results_block", text: "No Results"


    within '#simple_search_master' do
      fill_in "Last name", with: "bad1\t"
    end

    expect(page).to have_css "#master_results_block", text: "No Results"


    within '#simple_search_master' do
      find('#master_general_infos_attributes_0_first_name').click


    end

    within '.advanced-form-selections' do
      click_button "Advanced Search"
    end
    # Wait for the advance form collapse animation to complete
    expect(page).to have_css '#master-search-advanced-form.in'

    within '#advanced_search_master' do
      click_link 'clear fields'
      fill_in "master_player_infos_attributes_0_first_name", with: @full_player_info.first_name
      find("#master_player_infos_attributes_0_last_name").click
    end

    # don't do 'expect' on the ajax running symbol, since it might go away too fast
    have_css '#advanced_search_master.ajax-running'
    # wait a while!
    expect(page).to have_css "#master_results_block", text: ''
    expect(page).to have_css "#search_count", text: /[0-9]+/, wait: 10

    page.all(:css, '.master-expander .player-info-header .player-names').each do |el|
      expect(el.text).to match(/#{@full_player_info.first_name.capitalize}.*/)
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
      expect(el.text).to match(/#{@full_player_info.first_name.capitalize}.+#{@full_player_info.last_name.capitalize}.*/)
    end

    have_css("a.master-expander.attached-me-click")

    have_css("a.master-expander.attached-me-click[href='#master-#{@full_player_info.master_id}-main-container'].collapsed .player-info-header")
    page.all(:css, "a.master-expander.attached-me-click[href='#master-#{@full_player_info.master_id}-main-container'].collapsed .player-info-header").first.click

    # expect the player section to expand
    expect(page).to have_css "#master-#{@full_player_info.master_id}-main-container.collapse.in"

    expect(page).to have_css "#player-info-#{@full_player_info.master_id}-#{@full_player_info.id} .player-info-first_name", text: "first name #{@full_player_info.first_name.capitalize}"

    dismiss_modal

    protocol = Classification::Protocol.selectable.first

    within '#advanced_search_master' do

      select protocol.name, from: "master_trackers_attributes_0_protocol_id"
    end

    # wait a while, maybe
    have_css '#advanced_search_master.ajax-running'


    find "#master_results_block.search-status-done", wait: 5

    have_css ".master-expander"

    expect(page).to have_css "#search_count", text: /[0-9]+/, wait: 10


    me = page.all(:css, '.master-expander')

    me.each do |el|
      expect(el.text).to match(/#{@full_player_info.first_name.capitalize}.+#{@full_player_info.last_name.capitalize}.*/)


      h = open_player_element el, me

      #el.find('.player_info_header').click unless me.length == 1
      #dismiss_modal

      have_css "#master-#{@full_player_info.master_id}-main-container.collapse.in"

      have_css "#trackers-#{@full_player_info.master_id}.collapse.in"

      #h = el[:href].split('#').last

      expect(page).to have_css("##{h} .tracker-block .tracker-protocol_name .cell-holder", text: protocol.name), "Expected: #{@full_master_record.trackers.map {|m| m.protocol_name} }"
      dismiss_modal
    end

    #page.all(:css, '.master-expander').first.click

    logout

  end

  it "searches tracker for items not in the tracker" do

    visit "/masters/search"
    within '#simple_search_master' do
      find('#master_general_infos_attributes_0_first_name').click

    end

     within '.advanced-form-selections' do
      click_button "Advanced Search"
    end

     # Wait for the advance form collapse animation to complete
    expect(page).to have_css '#master-search-advanced-form.in'

    sprot = Classification::Protocol.selectable

    expect(sprot.length).to be > 0

    protocol = pick_one_from(sprot)
    sp = pick_one_from(protocol.sub_processes.active)
    has_css? "#master_trackers_attributes_0_sub_process_id"

    within '#advanced_search_master' do

      select protocol.name, from: "master_trackers_attributes_0_protocol_id"
      select sp.name, from: "master_trackers_attributes_0_sub_process_id"
    end

    # wait a while, maybe
    expect(page).to have_css "#search_count", text: ''
    have_css '#advanced_search_master.ajax-running'


    have_css "#master_results_block.search-status-done"
    find ".master-expander", match: :first, wait: 20

    #give slow systems time to catch up with the large result set
    sleep 2
    #expect(page).to have_css "#search_count", text: /[0-9]+.*/

    items = page.all(:css, '.master-expander.collapsed')

    expect(items.length).to be > 0

    done = 0

    items.each do |el|

      have_css '.player-info-header'
      dismiss_modal


      h = open_player_element el, items


      b = all('button[data-dismiss="modal"]')
      b.first.click if b && b.length > 0

      h = el[:href].split('#').last
      have_css("##{h}.collapse.in")
      find "##{h}.collapse.in", wait: 5
      have_css "##{h}.tracker-block.collapse.in"
      expect(page).to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-protocol_name", text: /#{protocol.name}/i
      expect(page).to have_css "##{h} div.tracker-block table.tracker-tree-results tbody[data-tracker-protocol='#{protocol.name.downcase}'] .tracker-sub_process_name", text: /#{sp.name}/i

      done += 1
      dismiss_modal
      break if done > 5
    end



  end

  after(:all) do

  end
end
