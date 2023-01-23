# frozen_string_literal: true

require 'rails_helper'

describe 'advanced search', js: true, driver: :app_firefox_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup

    seed_database
    create_data_set_outside_tx
    @admin, = create_admin

    gs = Classification::GeneralSelection.all
    gs.each do |g|
      g.current_admin = @admin
      g.create_with = true
      g.edit_always = true
      g.save!
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

    ac = Admin::AppConfiguration.where(app_type: @user.app_type, name: 'create master with').first

    if ac
      ac.value = 'player_info'
      ac.current_admin = @admin
      ac.save!
    else
      Admin::AppConfiguration.create! app_type: @user.app_type, name: 'create master with', value: 'player_info',
                                      current_admin: @admin
    end

    setup_access :addresses
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
  end

  def add_contact(ctype, entry, expected)
    expect(page).to have_css('[data-sub-list="player_contacts"]')
    find('[data-sub-list="player_contacts"] a.add-item-button').click
    expect(page).to have_css('form#new_player_contact')

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
        sleep 0.5
        p = Capybara.find(:xpath, '//body').find('.datepicker')

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

    within 'form.edit_player_info' do
      fill_in 'First name', with: fname
      fill_in 'Last name', with: lname
      fill_in 'Start year', with: startyear
      fill_in 'End year', with: endyear
      # select source, from: 'Source'
      click_button 'Save'
    end

    if startyear != ''
      expect(page).to have_css('.player-info-item .list-group')
      t = find('.player-info-start_year strong').text
      expect(t).to eq startyear
    else
      expect(all('.player-info-start_year strong').length).to eq 0
    end

    if endyear != ''
      expect(page).to have_css('.player-info-item .list-group')
      t = find('.player-info-end_year strong').text
      expect(t).to eq endyear
    else
      expect(all('.player-info-end_year strong').length).to eq 0
    end

    # ensure that we wait for the results to fully show before returning
    expect(page).to have_css(".player-info-item a[title='edit']")
  end

  def edit_college(college, keyed)
    have_css('form.edit_player_info')
    within 'form.edit_player_info' do
      f = find('#player_info_college')
      f.click
      f.send_keys(keyed)
      sleep 1

      h = '.tt-suggestion .tt-highlight'
      expect(page).to have_css(h)
      expect(page.all(h).first.text.downcase).to eq(keyed)
      page.all(h).first.click

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

  def add_player_msid(player)
    # create Master
    expect(page).to have_css("a[href='/masters/new']")

    click_link 'Create Master'

    within '#new_master' do
      click_button 'Create'
    end

    # edit player info data

    expect(page).to have_css('#master_results_block')
    expect(page).to have_css('.player-info-item')
    b = all ".player-info-item a[title='edit']"
    b.first.click

    expect(page).to have_css('form.edit_player_info')

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
    if dd
      b = all ".player-info-item a[title='edit']"
      b.first.click
      edit_date('#player_info_death_date', 'form.edit_player_info', dd.month, dd.day, dd.year)

      expect(page).to have_css('li.list-group-item.player-info-death_date')
      t = find('li.list-group-item.player-info-death_date strong').text
      expect(t).to match(%r{0?#{dd.month}/0?#{dd.day}/#{dd.year}})
    end
  end

  before :each do
    validate_setup

    # login_as @user, scope: :user
    expect(@user.has_access_to?(:create, :table, :player_contacts))
    expect(@user.has_access_to?(:read, :general, :create_master))
    login
  end

  it 'should allow a new MSID and player information to be added' do
    expect(@user.has_access_to?(:create, :table, :player_contacts))
    expect(@user.has_access_to?(:read, :general, :create_master))

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
    expect(page).to have_css('.player-info-item')
    b = all ".player-info-item a[title='edit']"
    b.first.click

    expect(page).to have_css('form.edit_player_info')

    item_type = 'player_infos_source'
    sources = Classification::GeneralSelection.where(item_type: item_type)

    edit_player_info 'Robert', 'Andrew-Yamel', nil, nil, sources.first.name

    # edit college
    b = all ".player-info-item a[title='edit']"
    b.first.click

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

    find('a.add-flags').click

    sleep 1
    # Trigger the chosen drop down
    i = 'ul.chosen-choices .search-field input.default'
    expect(page).to have_css(i)
    sleep 1
    f = find(i)
    f.click

    # An absolutely positioned drop down is now shown. Interact with this instead
    i = 'body > .chosen-container ul.chosen-choices .search-field input'
    expect(page).to have_css(i)
    f = find(i)

    f.send_keys('f')
    f.send_keys('o')

    expect(page).to have_css('body > .chosen-container ul.chosen-results')
    res = page.all('body > .chosen-container ul.chosen-results li.active-result')

    expect(res.length).to be > 0
    res.each do |r|
      expect(r.text).to match(/fo.+/)
    end

    text1 = res.first.text
    res.first.click

    sleep 1
    # tag = 'body > .chosen-container ul.chosen-choices li.search-choice span'
    # expect(page).to have_css(tag)
    # ftag = find(tag)
    # expect(ftag.text).to eq(res.first.text)

    # Handle the absolutely positioned chosen drop down
    page.find('body > .chosen-container ul.chosen-choices').click
    # Clear the chosen box
    page.all('h4.list-group-item-heading').first.click

    within('.item-flags-block form') do
      click_button 'Save Item flag'
    end

    # The absolutely positioned chosen has gone away. Search for the standard one
    tag = '.chosen-container ul.chosen-choices li.search-choice span'
    expect(page).to have_css(tag)
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
