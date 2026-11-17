# frozen_string_literal: true

require 'rails_helper'

describe 'advanced search', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    puts "start #{Time.now} advanced search setup"
    SetupHelper.feature_setup

    create_data_set_outside_tx no_seed: true
    @admin, = create_admin

    gs = Classification::GeneralSelection.all
    gs.each do |g|
      g.current_admin = @admin
      g.create_with = true
      g.edit_always = true
      g.save
    end

    # Clean up the general selection list to only allow one phone, email etc
    gslist = []
    Classification::GeneralSelection.enabled.where(item_type: 'player_contacts_type').each do |gs|
      gs.current_admin = @admin
      gs.disable! if gslist.include? gs.value
      gslist << gs.value
    end

    @user, @good_password = create_user
    @good_email = @user.email

    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general,
                                     resource_name: :create_master, current_admin: @admin, user: @user

    # Use the app-wide config - user-specific configs from other specs persist between runs
    add_app_config(@user.app_type, 'create master with', 'player_info')

    bp = player_list.find { |p| p[:college].blank? }
    raise "Player List college is blank: #{bp}" if bp

    setup_access :addresses
    setup_access :player_infos
    setup_access :player_infos, user: @user
    setup_access :addresses, user: @user
    setup_access :player_contacts
    setup_access :player_contacts, user: @user
    # setup_access :player_infos, access: :edit
    setup_access :item_flags
    setup_access :player_infos_item_flags
    # setup_access :not_tracker_histories
    # setup_access :not_trackers
    # setup_access :trackers
    # setup_access :tracker_histories
    # setup_access :latest_tracker_history
    setup_access :create_master, resource_type: :general, access: :read
    setup_access :create_master, resource_type: :general, access: :read, user: @user
    expect(@user.can?(:create_master)).to be_truthy
    puts "end #{Time.now} advanced search setup"
  end

  def add_contact(ctype, entry, expected)
    expect(page).to have_css('[data-sub-list="player_contacts"]')
    btn = find('[data-sub-list="player_contacts"] a.add-item-button')
    finish_page_loading
    finish_form_formatting
    wait_for_ui_to_settle
    scroll_into_view(btn)
    btn.click
    expect(page).to have_css('form#new_player_contact', wait: 10)

    within 'form#new_player_contact' do
      select ctype, from: 'Record type'
      f = find('#player_contact_data')
      entry.chars.each do |e|
        # break up the sending of keys to make the mask work, since the cursor resetting now breaks it when
        # sending it all in one chunk
        f.send_keys(e)
        sleep 0.01
      end
      click_button 'Save'
    end

    expect(page).not_to have_css('form#new_player_contact')

    # the list may reorganize and this can cause a race. Check the marker

    has_no_css? '.formatting-block'

    p = ".common-template-item[data-rec-type=\"#{ctype.downcase}\"] .list-group-item-heading"
    expect(page).to have_css(p)

    t = page.all(p).first.text

    puts 'failed to sort correctly' if t.downcase != expected.downcase

    expect(t.downcase).to eq(expected.downcase)
  end

  def edit_date(field, in_block, m, d, y, no_submit = false)
    months = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    field_name = field.delete_prefix('#')

    expect(page).to have_css(in_block, wait: 10)
    within in_block do
      f = find("input#{field}")
      if f[:type] == 'date'
        k = "#{y}-#{'%02i' % m}-#{'%02i' % d}"
        f.send_keys k
        expect(page).to have_field(field_name, with: k, wait: 10)

      else
        f.click
        finish_form_formatting
        # Wait for the datepicker to appear, retry click if needed
        f.click unless page.has_css?('.datepicker', wait: 3)
        p = Capybara.find(:xpath, '//body').find('.datepicker', wait: 5)

        expect(p).to have_css('.datepicker-years')

        oldyear = p.find('.datepicker-years span.year.old')

        while oldyear.text.to_i > y
          p.find('.datepicker-years th.prev').click
          oldyear = p.find('.datepicker-years span.year.old')
        end

        newyear = p.find('.datepicker-years span.year.new')

        while newyear.text.to_i < y
          p.find('.datepicker-years th.next').click
          newyear = p.find('.datepicker-years span.year.new')
        end

        year = p.all('.datepicker-years span.year').select { |s| s.text == y.to_s }.first
        # puts "Year: #{y} and old #{oldyear.text} and new #{newyear.text}" unless year
        year.click
        expect(p).to have_css('.datepicker-months')
        month = p.all('.datepicker-months span.month').select { |s| s.text == months[m - 1] }.first
        month.click

        t = p.find('.datepicker-switch').text
        expect(t[0..2]).to eq(months[m - 1])

        expect(p).to have_css('.datepicker-days')
        expect(p).to have_css('.datepicker-days td.day[data-date]')
        day = p.all('.datepicker-days td.day:not(.old)').select { |s| s.text == d.to_s }.first
        day.click

        expected_value =
          if f[:class].include?('date-is-local')
            %r{0?#{m}/0?#{d}/#{y}}
          else
            /#{y}-0?#{m}-0?#{d}/
          end
        expect(page).to have_field(field_name, with: expected_value, wait: 10)
      end

      find('input[type="submit"]').click unless no_submit
    end

    return if no_submit

    expect(page).not_to have_css(in_block, wait: 10)
    finish_form_formatting
  end

  def edit_player_info(fname, lname, startyear, endyear, _source)
    startyear ||= ''
    startyear = startyear.to_s

    endyear ||= ''
    endyear = endyear.to_s

    within player_info_form_selector do
      fill_in 'First name', with: fname
      fill_in 'Last name', with: lname
      fill_in 'Start year', with: startyear
      fill_in 'End year', with: endyear
      # select source, from: 'Source'
      click_button 'Save'
    end

    if startyear == ''
      expect(all('.player-info-start_year strong').length).to eq 0
    else
      expect(page).to have_css('.player-info-item .list-group')
      t = find('.player-info-start_year strong').text
      expect(t).to eq startyear
    end

    if endyear == ''
      expect(all('.player-info-end_year strong').length).to eq 0
    else
      expect(page).to have_css('.player-info-item .list-group')
      t = find('.player-info-end_year strong').text
      expect(t).to eq endyear
    end

    # ensure that we wait for the results to fully show before returning
    expect(page).to have_css(".player-info-item a[title='edit']")
    expect(page).not_to have_css('form.edit_player_info, form#new_player_info', wait: 10)
    finish_form_formatting
  end

  def player_info_form_selector
    return 'form.edit_player_info' if page.has_css?('form.edit_player_info', wait: 3)
    return 'form#new_player_info' if page.has_css?('form#new_player_info', wait: 3)

    raise 'Could not find player info form'
  end

  #
  # A college field provides both typeahead and free text entry.
  # This method tests both for the allow_missing option is true. The free text entry
  # will be saved as an option in the colleges list for future typeahead use.
  # If allow_missing is false, the typeahead is expected to find at least one suggestion matching the keyed text.
  # @param [String] college - full college name
  # @param [String] keyed - partial college name to type to test typeahead
  # @param [Boolean] allow_missing - whether to allow no typeahead suggestions to be found (default: true)
  def edit_college(college, keyed, allow_missing: true)
    expect(college).not_to be_empty
    expect(keyed).not_to be_empty
    expect(keyed.length).to be >= 3
    unless has_css?('form.edit_player_info', wait: 3)
      debug_state('edit_player_info_missing', "Expected to be in edit_player_info form to edit college '#{college}'")
    end
    within 'form.edit_player_info' do
      f = find('#player_info_college')
      scroll_into_view(f)
      f.click
      # Clear the field first
      f.send_keys([:control, 'a'])
      f.send_keys(:delete)
      f.send_keys(keyed)

      suggestions_loaded = has_css?('.tt-suggestion', wait: 5)

      unless allow_missing || suggestions_loaded
        debug_state('college_typeahead', "Typing college '#{keyed}' to get typeahead suggestions")
        # Try clicking and typing again
        f.click
        f.send_keys([:control, 'a'])
        f.send_keys(keyed)
        suggestions_loaded = has_css?('.tt-suggestion', wait: 5)
      end
      unless allow_missing || suggestions_loaded
        debug_state('college_typeahead_missing', "No typeahead suggestions for college '#{keyed}'\n#{page.html}")
        take_screenshot 'college_suggestions', force: true
      end

      h = '.tt-suggestion .tt-highlight'
      if suggestions_loaded
        expect(page).to have_css('.tt-suggestion'), "Failed typing college '#{keyed}' to get typeahead suggestions"

        # Wait for highlighted suggestion
        expect(page).to have_css(h, wait: 5), "No college suggestion highlighted for '#{keyed}'.\n#{page.all('.tt-suggestion').first&.text}"
        expect(page.all(h).first.text.downcase).to eq(keyed)
        page.all(h).first.click
      elsif allow_missing
        f.send_keys([:control, 'a'])
        f.send_keys(college)
      else
        debug_state('college_highlight_missing', "No highlighted suggestion for college '#{keyed}'\n#{page.html}")
        take_screenshot 'college_highlight', force: true
        expect(page).to have_css('.tt-suggestion'), "No typeahead suggestions for college '#{keyed}' after typing"
      end

      click_button 'Save'
    end

    expect(page).to have_css('li.list-group-item.player-info-college')
    t = find('li.list-group-item.player-info-college strong').text
    expect(t).to eq college.captionize
    expect(page).not_to have_css('form.edit_player_info', wait: 10)
    finish_form_formatting
  end

  def search_dob(m, d, y)
    finish_player_data_ajax
    expect(page).not_to have_css('#master-search-accordion .collapsing', wait: 10)
    wait_for_ui_to_settle
    simple_search_panel = find('#master-search-simple-form', visible: :all)
    find('#expand-simple-form').click unless simple_search_panel[:class].split.include?('in')
    expect(page).to have_css('#master-search-simple-form.collapse.in', wait: 10)
    expect(page).to have_css('#master-search-simple', wait: 10)
    finish_form_formatting

    # test search birth date
    edit_date('#master_general_infos_attributes_0_birth_date', '#master-search-simple', m, d, y, true)

    expect(page).to have_css('#master_results_block .player-info-header', wait: 10)
    res = all('.player-info-header')
    t = res.first
    expect(t.text).to include "DOB #{m.to_s.rjust(2, '0')}/#{d.to_s.rjust(2, '0')}/#{y}"

    me = all('a.master-expander')
    el = me.first
    open_player_element el, me
    have_css(".player-info-item a[title='edit']")
  end

  def ensure_player_info_item_visible
    return if page.has_css?('.player-info-item', wait: 3)

    expanders = all('a.master-expander', wait: 10)
    expect(expanders).not_to be_empty
    open_player_element(expanders.first, expanders)
    expand_master_record_tab('details') unless page.has_css?('.player-info-item', wait: 3)
    return if page.has_css?('.player-info-item', wait: 10)
    return if page.has_css?('.add-item-button', text: /player info/i, wait: 5)

    expect(page).to have_css('.player-info-item', wait: 10)
  end

  def click_player_info_edit
    finish_player_data_ajax
    wait_for_ui_to_settle
    item = find('.player-info-item', wait: 10)
    edit_link = item.find("a[title='edit']", wait: 10)
    scroll_into_view(edit_link)
    edit_link.click
    expect(page).to have_css('form.edit_player_info', wait: 10)
    finish_form_formatting
  end

  def finish_player_data_ajax
    expect(page).not_to have_css('.ajax-running', wait: 10)
    finish_form_formatting
  end

  def open_player_info_form
    ensure_player_info_item_visible

    if page.has_css?(".player-info-item a[title='edit']", wait: 3)
      click_player_info_edit
    else
      add_button = find('.add-item-button', text: /player info/i, match: :first, wait: 10)
      scroll_into_view(add_button)
      add_button.click
    end

    expect(page).to have_css('form.edit_player_info, form#new_player_info', wait: 10)
  end

  def add_player_msid(player)
    finish_page_loading
    finish_player_data_ajax
    expect(page).not_to have_css('form.edit_player_info, form#new_player_info', wait: 10)

    expect(page).to have_css("a[href='/masters/new']")

    create_master_link = find("a[href='/masters/new']", text: 'Create Master')
    wait_for_ui_to_settle
    scroll_into_view(create_master_link)
    create_master_link.click
    expect(page).to have_current_path('/masters/new', wait: 10)
    expect(page).to have_css('#new_master', wait: 10)

    within '#new_master' do
      click_button 'Create'
    end
    expect(page).to have_current_path(%r{\A/masters/\d+\z}, wait: 10)

    # edit player info data

    expect(page).to have_css('#master_results_block')
    open_player_info_form

    edit_player_info player[:first_name], player[:last_name], player[:start_year], player[:end_year], player[:source]

    # edit college
    click_player_info_edit

    edit_college player[:college], player[:college]

    # edit birth date

    bd = player[:birth_date]
    if bd
      click_player_info_edit
      edit_date('#player_info_birth_date', 'form.edit_player_info', bd.month, bd.day, bd.year)

      expect(page).to have_css('li.list-group-item.player-info-birth_date')
      t = find('li.list-group-item.player-info-birth_date strong').text
      expect(t).to match(%r{0?#{bd.month}/0?#{bd.day}/#{bd.year}})
    end

    dd = player[:death_date]
    if dd
      click_player_info_edit
      edit_date('#player_info_death_date', 'form.edit_player_info', dd.month, dd.day, dd.year)

      expect(page).to have_css('li.list-group-item.player-info-death_date')
      t = find('li.list-group-item.player-info-death_date strong').text
      expect(t).to match(%r{0?#{dd.month}/0?#{dd.day}/#{dd.year}})
    end

    expect(page).not_to have_css('form.edit_player_info, form#new_player_info', wait: 10)
    expect(page).to have_css(".player-info-item a[title='edit']", wait: 10)
    finish_player_data_ajax
  end

  before :each do
    validate_setup

    # login_as @user, scope: :user
    expect(@user.has_access_to?(:create, :table, :player_infos)).to be_truthy
    expect(@user.has_access_to?(:create, :table, :player_contacts)).to be_truthy
    expect(@user.has_access_to?(:read, :general, :create_master)).to be_truthy
    login
  end

  it 'should allow a new MSID and player information to be added' do
    expect(@user.has_access_to?(:create, :table, :player_infos)).to be_truthy
    expect(@user.has_access_to?(:create, :table, :player_contacts)).to be_truthy
    expect(@user.has_access_to?(:read, :general, :create_master)).to be_truthy

    ac = Admin::AppConfiguration.active.find_by(app_type: @user.app_type, name: 'create master with', user_id: nil, role_name: nil)
    expect(ac.value).to eq('player_info')

    visit '/masters/search'
    finish_page_loading

    # create Master

    expect(page).to have_css("a[href='/masters/new']")

    click_link 'Create Master'
    expect(page).to have_css('#new_master', wait: 10)

    within '#new_master' do
      click_button 'Create'
    end
    finish_page_loading

    # edit player info data

    expect(page).to have_css('#master_results_block')
    open_player_info_form
    finish_form_formatting

    expect(page).to have_css('form.edit_player_info, form#new_player_info', wait: 10)

    item_type = 'player_infos_source'
    sources = Classification::GeneralSelection.where(item_type: item_type)

    edit_player_info 'Robert', 'Andrew-Yamel', nil, nil, sources.first.name

    # edit college
    click_player_info_edit

    edit_college 'Harvard', 'har'

    # edit birth date with one known to cause issues (daylight savings)

    click_player_info_edit

    edit_date('#player_info_birth_date', 'form.edit_player_info', 3, 26, 2012)

    expect(page).to have_css('li.list-group-item.player-info-birth_date')
    expect(page).to have_css('li.list-group-item.player-info-birth_date strong')
    t = find('li.list-group-item.player-info-birth_date strong').text
    expect(t).to match(%r{0?3/26/2012})

    search_dob 3, 26, 2012

    # edit previously entered date
    click_player_info_edit
    dd = find('#player_info_birth_date')
    if dd[:type] == 'date'
      expect(find('#player_info_birth_date').value).to match('2012-03-26')
    else
      expect(dd.value).to match(%r{0?3/26/2012})
    end
    edit_date('#player_info_birth_date', 'form.edit_player_info', 3, 5, 1976)

    search_dob 3, 5, 1976
    # Add address
    expect(page).to have_css('[data-sub-list="addresses"]')

    find('[data-sub-list="addresses"] a.add-item-button').click
    expect(page).to have_css('form#new_address')

    within 'form#new_address' do
      select 'Canada', from: 'Country', match: :first
      fill_in 'Street', with: '123 Private St'
      fill_in 'Region', with: 'Alberta'
      click_button 'Save'
    end
    expect(page).not_to have_css('form#new_address', wait: 10)
    finish_page_loading
    finish_form_formatting

    # Add phone number

    add_contact('Email', 'abc@test.com', 'abc@test.com')
    add_contact('Phone', '6171239876', '(617)123-9876')
    add_contact('Phone', '6171239876 ext 132', '(617)123-9876 Ext 132')
    add_contact('Phone', 'abc6171239000', '(617)123-9000')

    # add player info tags

    af = find('a.add-flags')
    wait_for_ui_to_settle
    scroll_into_view af
    af.click

    expect(page).to have_css('.item-flags-block form', wait: 10)

    flag_name = Classification::ItemFlagName.enabled.where(item_type: 'player_info').pluck(:name).find { |name| name.match?(/\Afo/i) }
    expect(flag_name).not_to be_nil

    page.execute_script(<<~JS, flag_name)
      var select = document.getElementById('item_flag_item_flag_name_id');
      if (!select) return;
      var wanted = arguments[0].toLowerCase();

      Array.from(select.options).forEach(function(option) {
        option.selected = option.text.trim().toLowerCase() === wanted;
      });

      $(select).trigger('chosen:updated');
      $(select).trigger('change');
    JS

    text1 = flag_name

    within('.item-flags-block form') do
      click_button 'Save Item flag'
    end

    # The absolutely positioned chosen has gone away. Search for the standard one
    tag = '.chosen-container ul.chosen-choices li.search-choice span'
    expect(page).to have_css(tag, text: text1, wait: 10)
    ftag = find(tag)
    expect(ftag.text).to eq(text1)

    expect(page).to have_css('.item-flags-block .chosen-container.chosen-disabled', wait: 10)

    player_list.each do |player|
      player[:source] = sources[rand(sources.length - 1)].name
      add_player_msid player
    end
  end
end
