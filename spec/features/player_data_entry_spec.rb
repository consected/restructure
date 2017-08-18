require 'rails_helper'

describe "advanced search", js: true, driver: :app_firefox_driver do
  
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  
  before(:all) do
    @admin, _ = create_admin

    seed_database
    gs = GeneralSelection.all
    gs.each {|g| g.current_admin = @admin; g.create_with = true; g.edit_always = true; g.save!}

    create_data_set
    
    @user, @good_password  = create_user
    @good_email  = @user.email

    ua = UserAuthorization.create! has_authorization: 'create_msid', user_id: @user.id, current_admin: @admin, disabled: false
    ua.save!

    expect(@user.can?(:create_msid)).to be_truthy


  end

  def add_contact ctype, entry, expected

    expect(page).to have_css('[data-sub-list="player_contacts"]')
    find('[data-sub-list="player_contacts"] a.add-item-button').click
    expect(page).to have_css("form#new_player_contact")

    within "form#new_player_contact" do
      select ctype, from: "Rec type"
      f = find('#player_contact_data')
      entry.chars.each do |e|
        # break up the sending of keys to make the mask work, since the cursor resetting now breaks it when
        # sending it all in one chunk
        f.send_keys(e)
        sleep 0.01
      end
      click_button 'Create Player contact'
    end
    p = ".#{ctype.downcase}-type li.player-contact-data strong"
    expect(page).to have_css(p)

    t = page.all(p).first.text

    expect(t).to eq(expected)

  end

  def edit_date field, in_block, m, d, y

    months = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

    expect(page).to have_css(in_block)
    within in_block do
      f = find("input#{field}")
      f.click

      p = Capybara.find(:xpath, '//body').find('.datepicker')
      
      
      expect(p).to have_css('.datepicker-years')

      oldyear = p.find(".datepicker-years span.year.old")

      while oldyear.text.to_i > y do
        p.find(".datepicker-years th.prev").click        
        oldyear = p.find(".datepicker-years span.year.old")
      end

      newyear = p.find(".datepicker-years span.year.new")

      while newyear.text.to_i < y do
        p.find(".datepicker-years th.next").click
        oldyear = p.find(".datepicker-years span.year.new")
      end


      year = p.all(".datepicker-years span.year").select {|s| s.text == y.to_s}.first
      puts "Year: #{y} and old #{oldyear.text} and new #{newyear.text}" unless year
      year.click
      sleep 0.1
      expect(p).to have_css('.datepicker-months')
      month = p.all(".datepicker-months span.month").select {|s| s.text == months[m-1]}.first
      month.click

      t = p.find('.datepicker-switch').text
      expect(t[0..2]).to eq(months[m-1])
      
      sleep 0.1

      expect(p).to have_css('.datepicker-days')
      expect(p).to have_css('.datepicker-days td.day[data-date]')
      day = p.all(".datepicker-days td.day:not(.old)").select {|s| s.text == d.to_s}.first
      day.click

      sleep 0.1
      
      expect(f.value).to match(/0?#{m}\/0?#{d}\/#{y}/)
      find('input[type="submit"]').click
    end



  end


  def edit_player_info fname, lname, startyear, endyear, source

    startyear ||= ''
    startyear = startyear.to_s

    endyear ||= ''
    endyear = endyear.to_s

    within "form.edit_player_info" do
      fill_in "First name", with: fname
      fill_in "Last name", with: lname
      fill_in "Start year", with: startyear
      fill_in "End year", with: endyear
      select source, from: 'Source'
      click_button "Update Player info"
    end

    if startyear!=''
      expect(page).to have_css('.player-info-item .list-group')
      t = find('.player-info-start_year strong').text
      expect(t).to eq startyear
    else
      expect(all('.player-info-start_year strong').length).to eq 0
    end
    
    if endyear!=''
      expect(page).to have_css('.player-info-item .list-group')
      t = find('.player-info-end_year strong').text
      expect(t).to eq endyear
    else
      expect(all('.player-info-end_year strong').length).to eq 0
    end

    

  end

  def edit_college college, keyed

    within "form.edit_player_info" do
      f = find('#player_info_college')
      f.click
      f.send_keys(keyed)

      h = '.tt-suggestion .tt-highlight'
      expect(page).to have_css(h)
      expect(page.all(h).first.text.downcase).to eq(keyed)
      page.all(h).first.click

      click_button "Update Player info"
    end

    expect(page).to have_css("li.list-group-item.player-info-college")
    t = find("li.list-group-item.player-info-college strong").text
    expect(t).to eq college.titleize

  end

  def add_player_msid player
        # create MSID

    expect(page).to have_css("a[href='/masters/new']")

    click_link 'Create MSID'

    within "#new_master" do
      click_button 'Create'
    end

    # edit player info data

    expect(page).to have_css("#master_results_block")
    expect(page).to have_css(".player-info-item")
    b = all ".player-info-item a[title='edit']"
    b.first.click

    expect(page).to have_css("form.edit_player_info")


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

      expect(page).to have_css("li.list-group-item.player-info-birth_date")
      t = find("li.list-group-item.player-info-birth_date strong").text
      expect(t).to match(/0?#{bd.month}\/0?#{bd.day}\/#{bd.year}/)
    end

    dd = player[:death_date]
    if dd
      b = all ".player-info-item a[title='edit']"
      b.first.click      
      edit_date('#player_info_death_date', 'form.edit_player_info', dd.month, dd.day, dd.year)

      expect(page).to have_css("li.list-group-item.player-info-death_date")
      t = find("li.list-group-item.player-info-death_date strong").text
      expect(t).to match(/0?#{dd.month}\/0?#{dd.day}\/#{dd.year}/)
    end
  end

  before :each do
    user = User.where(email: @good_email).first
    
    expect(user).to be_a User
    expect(user.id).to equal @user.id
    
    #login_as @user, scope: :user
    
    login

  end


  
  it "should allow a new MSID and player information to be added" do
    
    visit "/masters/search"

    # create MSID

    expect(page).to have_css("a[href='/masters/new']")

    click_link 'Create MSID'

    within "#new_master" do
      click_button 'Create'
    end

    # edit player info data

    expect(page).to have_css("#master_results_block")
    expect(page).to have_css(".player-info-item")
    b = all ".player-info-item a[title='edit']"
    b.first.click

    expect(page).to have_css("form.edit_player_info")

    item_type = 'player_infos_source'
    sources = GeneralSelection.where(item_type: item_type)
    
    edit_player_info 'Robert', 'Andrew-Yamel', nil, nil, sources.first.name

    # edit college
    b = all ".player-info-item a[title='edit']"
    b.first.click

    edit_college 'Harvard', 'har'

    # edit birth date with one know to cause issues (daylight savings)

    b = all ".player-info-item a[title='edit']"
    b.first.click


    edit_date('#player_info_birth_date', 'form.edit_player_info', 3,26,2012)

    expect(page).to have_css("li.list-group-item.player-info-birth_date")
    t = find("li.list-group-item.player-info-birth_date strong").text
    expect(t).to match(/0?3\/26\/2012/)


    #edit previously entered date 
    b = all ".player-info-item a[title='edit']"
    b.first.click
    expect(find('#player_info_birth_date').value).to match(/0?3\/26\/2012/)
    edit_date('#player_info_birth_date', 'form.edit_player_info', 3, 5, 1976)



    # Add address

    expect(page).to have_css('[data-sub-list="addresses"]')
    find('[data-sub-list="addresses"] a.add-item-button').click 
    expect(page).to have_css("form#new_address")

    within "form#new_address" do
      select "Canada", from: "Country", :match => :first
      fill_in 'Street', with: '123 Private St'
      fill_in 'Region', with: 'Alberta'
      click_button 'Create Address'
    end

    # Add phone number

    add_contact('Email', 'abc@test.com', 'abc@test.com')
    add_contact('Phone', '6171239876', '(617)123-9876')
    add_contact('Phone', '6171239876 ext 132', '(617)123-9876 Ext 132')
    add_contact('Phone', 'abc6171239000', '(617)123-9000')
    

    # add player info tags

    find('a.add-flags').click

    i = 'ul.chosen-choices .search-field input.default'
    expect(page).to have_css(i)
    
    f = find(i)
    f.click
    f.send_keys('f')
    f.send_keys('o')

    expect(page).to have_css('ul.chosen-results')
    res = page.all('ul.chosen-results li.active-result')

    expect(res.length).to be > 0
    res.each do |r|
      expect(r.text).to match(/fo.+/)
    end

    text1 = res.first.text
    res.first.click


    tag = 'ul.chosen-choices li.search-choice span'
    expect(page).to have_css(tag)

    ftag = find(tag)
    expect(ftag.text).to eq(res.first.text)

    within ('.item-flags-block form') do
      click_button 'Save Item flag'
    end

    tag = 'ul.chosen-choices li.search-choice span'
    expect(page).to have_css(tag)
    ftag = find(tag)
    expect(ftag.text).to eq(text1)

    expect(page).to have_css('.item-flags-block .chosen-container.chosen-disabled')


    pl = player_list

    pl.each do |p|
      p[:source] = sources[rand(sources.length-1)].name
      add_player_msid p
    end


    # test search birth date
    edit_date('#master_general_infos_attributes_0_birth_date', '#master-search-simple', 3,26,2012)
#    f = find('#master_general_infos_attributes_0_birth_date')
#    f.send_keys :tab

    expect(page).to have_css('#master_results_block')
    t = all('.player-info-header').first.text
    expect(t).to include 'DOB 3/26/2012'

  end
 
  after(:all) do
    
  end
end

