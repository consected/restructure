require 'rails_helper'

describe "external id (bhs_assignments)", js: true, driver: :app_firefox_driver do

  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    @admin, _ = create_admin

    seed_database
    gs = Classification::GeneralSelection.all
    gs.each {|g| g.current_admin = @admin; g.create_with = true; g.edit_always = true; g.save!}

    create_data_set

    @user, @good_password  = create_user
    @good_email  = @user.email
    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :create, resource_type: :table, resource_name: :bhs_assignments, current_admin: @admin, user: @user

    @master.current_user = @user
    @master.bhs_assignments.create! bhs_id: rand(100000000..999999999)

  end

  before :each do
    user = User.where(email: @good_email).first

    expect(user).to be_a User
    expect(user.id).to equal @user.id

    #login_as @user, scope: :user

    login

  end



  it "creates external IDs" do

    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"

    expect(page).to have_css("#master-#{@master.id}")
    expect(page).not_to have_css('.alert')

    # Find the external ID tab
    l = all('a[data-panel-tab="external_ids"]').first

    expect(l).not_to be nil

    l.click

    expect(page).to have_css("#external-ids-#{@master_id}")
    c = "#bhs-assignments-#{@master_id}- .new-button-container a.btn"
    expect(page).to have_css(c)
    b = all(c).first
    expect(b).not_to be nil

    b.click

    expect(page).to have_css("form.new_bhs_assignment")
    new_num = rand(100000000..999999999)
    within("form.new_bhs_assignment") do
      fill_in 'Bhs', with: new_num
      sleep 0.5
      click_on 'Save'
    end

    expect(page).to have_css('[data-model-data-type="external_identifier"][data-sub-item="bhs_assignment"]')

    h = all('h4.external-id-heading').first
    new_num = new_num.to_s
    expect(h.text).to eq "BHS ID #{new_num[0..2]} #{new_num[3..5]} #{new_num[6..8]}"


  end

  after(:all) do

  end
end
