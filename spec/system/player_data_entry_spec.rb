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

    ac = Admin::AppConfiguration.active.find_by(app_type: @user.app_type, name: 'create master with')

    if ac
      ac.value = 'player_info'
      ac.current_admin = @admin
      ac.updated_at = DateTime.now
      ac.save!
    else
      Admin::AppConfiguration.create! app_type: @user.app_type, name: 'create master with', value: 'player_info',
                                      current_admin: @admin
    end

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
    scroll_into_view(btn)
    btn.click
    sleep 0.5 # Allow time for AJAX form to load
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

    expect(page).to have_css(in_block)
    within in_block do
      f = find("input#{field}")
      if f[:type] == 'date'
        k = "#{y}-#{'%02i' % m}-#{'%02i' % d}"
        f.send_keys k
        expect(page).to have_css("input#{field}")
        expect(f.value).to match(k)
        sleep 1

      else
        f.click
        finish_form_formatting
        sleep 0.5
        # Wait for the datepicker to appear, retry click if needed
        unless page.has_css?('.datepicker', wait: 3)
          f.click
          sleep 1
        end
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
          oldyear = p.find('.datepicker-years span.year.new')
        end

        year = p.all('.datepicker-years span.year').select { |s| s.text == y.to_s }.first
        # puts "Year: #{y} and old #{oldyear.text} and new #{newyear.text}" unless year
        year.click
        sleep 0.1
        expect(p).to have_css('.datepicker-months')
        month = p.all('.datepicker-months span.month').select { |s| s.text == months[m - 1] }.first
        month.click

        t = p.find('.datepicker-switch').text
        expect(t[0..2]).to eq(months[m - 1])

        sleep 0.1

        expect(p).to have_css('.datepicker-days')
        expect(p).to have_css('.datepicker-days td.day[data-date]')
        day = p.all('.datepicker-days td.day:not(.old)').select { |s| s.text == d.to_s }.first
        day.click

        sleep 1
        # check that the result is viewing correctly as a local date before attempting to match
        # search forms seem to get back to this a little slower than edit forms
        expect(page).to have_css("input#{field}")
        sleep 1
        f = find("input#{field}")
        if f[:class].include?('date-is-local')
          expect(f.value).to match(%r{0?#{m}/0?#{d}/#{y}})
        else
          expect(f.value).to match(/#{y}-0?#{m}-0?#{d}/)
        end
      end

      find('input[type="submit"]').click unless no_submit
      sleep 1
    end
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

      # Give more time for AJAX typeahead to load
      sleep 1

      unless allow_missing || has_css?('.tt-suggestion', wait: 10)
        debug_state('college_typeahead', "Typing college '#{keyed}' to get typeahead suggestions")
        # Try clicking and typing again
        f.click
        f.send_keys([:control, 'a'])
        f.send_keys(keyed)
        sleep 2
      end
      # Wait for typeahead suggestions to appear
      unless allow_missing || has_css?('.tt-suggestion', wait: 5)
        debug_state('college_typeahead_missing', "No typeahead suggestions for college '#{keyed}'\n#{page.html}")
        take_screenshot 'college_suggestions', force: true
      end

      h = '.tt-suggestion .tt-highlight'
      if has_css?('.tt-suggestion', wait: 5)
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
  end

  def search_dob(m, d, y)
    # test search birth date
    edit_date('#master_general_infos_attributes_0_birth_date', '#master-search-simple', m, d, y, true)

    have_css('#master_results_block')
    sleep 1
    expect(page).to have_css('#master_results_block .player-info-header')

    expect(page).to have_css('.player-info-header')
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

  def open_player_info_form
    ensure_player_info_item_visible

    if page.has_css?(".player-info-item a[title='edit']", wait: 3)
      all(".player-info-item a[title='edit']").first.click
    else
      add_button = find('.add-item-button', text: /player info/i, match: :first, wait: 10)
      scroll_into_view(add_button)
      add_button.click
    end

    expect(page).to have_css('form.edit_player_info, form#new_player_info', wait: 10)
  end

  def add_player_msid(player)
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

    edit_player_info player[:first_name], player[:last_name], player[:start_year], player[:end_year], player[:source]

    # edit college
    b = all ".player-info-item a[title='edit']"
    b.first.click

    edit_college player[:college], player[:college]

    # edit birth date

    bd = player[:birth_date]
    if bd
      b = all ".player-info-item a[title='edit']"
      b.first.click
      edit_date('#player_info_birth_date', 'form.edit_player_info', bd.month, bd.day, bd.year)

      expect(page).to have_css('li.list-group-item.player-info-birth_date')
      t = find('li.list-group-item.player-info-birth_date strong').text
      expect(t).to match(%r{0?#{bd.month}/0?#{bd.day}/#{bd.year}})
    end

    dd = player[:death_date]
    return unless dd

    b = all ".player-info-item a[title='edit']"
    b.first.click
    edit_date('#player_info_death_date', 'form.edit_player_info', dd.month, dd.day, dd.year)

    expect(page).to have_css('li.list-group-item.player-info-death_date')
    t = find('li.list-group-item.player-info-death_date strong').text
    expect(t).to match(%r{0?#{dd.month}/0?#{dd.day}/#{dd.year}})
  end

  before :each do
    validate_setup

    # login_as @user, scope: :user
    expect(@user.has_access_to?(:create, :table, :player_infos))
    expect(@user.has_access_to?(:create, :table, :player_contacts))
    expect(@user.has_access_to?(:read, :general, :create_master))
    login
  end

  it 'should allow a new MSID and player information to be added' do
    expect(@user.has_access_to?(:create, :table, :player_infos))
    expect(@user.has_access_to?(:create, :table, :player_contacts))
    expect(@user.has_access_to?(:read, :general, :create_master))

    ac = Admin::AppConfiguration.active.find_by(app_type: @user.app_type, name: 'create master with')
    expect(ac.value).to eq('player_info')

    visit '/masters/search'
    finish_page_loading

    # create Master

    expect(page).to have_css("a[href='/masters/new']")

    click_link 'Create Master'

    within '#new_master' do
      click_button 'Create'
    end
    finish_page_loading

    # edit player info data

    expect(page).to have_css('#master_results_block')
    open_player_info_form
    sleep 1
    sleep 0.5 # Allow edit form to load via AJAX

    expect(page).to have_css('form.edit_player_info, form#new_player_info', wait: 10)

    item_type = 'player_infos_source'
    sources = Classification::GeneralSelection.where(item_type: item_type)

    edit_player_info 'Robert', 'Andrew-Yamel', nil, nil, sources.first.name

    # edit college
    b = all ".player-info-item a[title='edit']"
    b.first.click
    sleep 0.5 # Allow edit form to load via AJAX

    edit_college 'Harvard', 'har'

    # edit birth date with one known to cause issues (daylight savings)

    b = all ".player-info-item a[title='edit']"
    b.first.click

    edit_date('#player_info_birth_date', 'form.edit_player_info', 3, 26, 2012)

    expect(page).to have_css('li.list-group-item.player-info-birth_date')
    expect(page).to have_css('li.list-group-item.player-info-birth_date strong')
    t = find('li.list-group-item.player-info-birth_date strong').text
    expect(t).to match(%r{0?3/26/2012})

    # Now necessary to expand the search form when just loading a master record directly
    sf = find '#expand-simple-form'
    sf.click

    search_dob 3, 26, 2012

    # edit previously entered date
    b = all ".player-info-item a[title='edit']"
    b.first.click
    dd = find('#player_info_birth_date')
    if dd[:type] == 'date'
      expect(find('#player_info_birth_date').value).to match('2012-03-26')
    else
      expect(dd.value).to match(%r{0?3/26/2012})
    end
    edit_date('#player_info_birth_date', 'form.edit_player_info', 3, 5, 1976)

    sleep 1
    search_dob 3, 5, 1976
    sleep 1
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

    # Add phone number

    add_contact('Email', 'abc@test.com', 'abc@test.com')
    add_contact('Phone', '6171239876', '(617)123-9876')
    add_contact('Phone', '6171239876 ext 132', '(617)123-9876 Ext 132')
    add_contact('Phone', 'abc6171239000', '(617)123-9000')

    # add player info tags

    af = find('a.add-flags')
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

    expect(page).to have_css('.item-flags-block .chosen-container.chosen-disabled')

    pl = player_list

    pl.each do |p|
      p[:source] = sources[rand(sources.length - 1)].name
      add_player_msid p
    end
  end

  after(:all) do
  end
end
