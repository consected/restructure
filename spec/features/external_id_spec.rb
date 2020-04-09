# frozen_string_literal: true

require 'rails_helper'

describe 'external id (bhs_assignments)', js: true, driver: :app_firefox_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include BhsImportConfig # automatically imports the BHS app

  
  before(:all) do
    BhsImportConfig.import_config
    SetupHelper.feature_setup

    create_admin

    create_data_set_outside_tx

    gs = Classification::GeneralSelection.all
    gs.each { |g| g.current_admin = @admin; g.create_with = true; g.edit_always = true; g.save! }

    @user, @good_password = create_user
    @good_email = @user.email
    resource_name = :bhs_assignments
    # Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :create, resource_type: :table, resource_name: , current_admin: @admin, user: @user
    setup_access resource_name, resource_type: :table, access: :create, user: @user

    bhs = ExternalIdentifier.where(name: resource_name).first
    bhs.update! external_id_edit_pattern: '\\d{3} \\d{3} \\d{3}', current_admin: @admin

    @master.current_user = @user
    @master.bhs_assignments.create! bhs_id: rand(100_000_000..999_999_999)
  end

  before :each do
    user = User.where(email: @good_email).first

    expect(user).to be_a User
    expect(user.id).to equal @user.id

    # login_as @user, scope: :user

    login
  end

  it 'creates external IDs' do
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

    expect(page).to have_css('form.new_bhs_assignment')
    new_num = rand(100_000_000..999_999_999)
    within('form.new_bhs_assignment') do
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
