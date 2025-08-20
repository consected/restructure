# frozen_string_literal: true

require 'rails_helper'

describe 'external id (bhs_assignments)', js: true, driver: :app_firefox_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport
  include TestFieldsDmSupport

  before(:all) do
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', false)

    create_admin

    ms = Master.no_temporary_masters

    if ms.count == 0 || ms.first || ms.first.id < 1
      create_data_set_outside_tx
      @master ||= ms.first
      @master_id ||= @master.id
    else
      @master = ms.first
      @master_id = @master.id
    end

    expect(@master_id).to be > 0

    @user, @good_password = create_user(create_master: true)
    @good_email = @user.email
    app_type = @user.app_type
    expect(app_type).not_to be nil
    expect(@user.two_factor_setup_required?).to be_falsey

    setup_fields_dm

    expect(@user.has_access_to?(:access, :general, :app_type, alt_app_type_id: app_type.id))
    setup_access :dynamic_model__test_all_v2_fields, user: @user, app_type: app_type
    expect(@user.has_access_to?(:create, :table, :dynamic_model__test_all_v2_fields)).to be_truthy
    Rails.application.routes_reloader.reload!
  end

  before :each do
    validate_setup
    login
  end

  # Test creation of a dynamic model and show a form with all available field types
  # Although we don't exercise all the fields for data entry, showing them ensures that
  # there isn't a regression in the UI.
  it 'creates a dynamic model' do
    visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
    dismiss_modal

    expect(page).to have_css("#master-#{@master.id}")
    expect(page).not_to have_css('.alert')

    # Find the external ID tab
    l = all('a[data-panel-tab="details"]').first
    expect(l).not_to be nil
    l.click

    expect(page).to have_css("#details-#{@master_id}")
    c = '.details-item-type-dynamic-model--test-all-v2-fields .new-button-container a.btn'
    expect(page).to have_css(c)
    b = all(c).first
    expect(b).not_to be nil

    b.click
    expect(page).to have_css('form.new_dynamic_model_test_all_v2_field')
    new_num = rand(100_000_000..999_999_999)
    within('form.new_dynamic_model_test_all_v2_field') do
      sleep 2
      # Basic string fields
      fill_in 'A string', with: 'Test string value'
      fill_in 'A string2', with: 'Another string value'
      fill_in 'A mixed string', with: 'Mixed string 123'
      fill_in 'A unknown', with: 'Unknown type value'

      # Numeric fields
      fill_in 'A int', with: '42'
      fill_in 'A float', with: '3.14159'
      fill_in 'A timestamp', with: '1691534400'
      fill_in 'A decimal', with: '123.45'

      # Date and time fields
      fill_in 'A date', with: '2025-08-15'
      fill_in 'A time', with: '2025-08-15 14:30:00'
      fill_in 'Done when', with: '2025-09-01'

      # Boolean field
      check 'A boolean'

      # JSON/JSONB fields
      fill_in 'Json', with: '{"key": "value"}'
      fill_in 'Jsonb', with: '{"name": "Test", "active": true}'

      # Classification fields
      select 'General', from: 'Protocol'
      sleep 0.5
      select 'Communications', from: 'status'
      sleep 0.5
      select 'communication (outgoing)', from: 'method'
      fill_in 'College', with: 'Harvard University'

      # Address fields
      select 'Massachusetts', from: 'State'
      select 'United Kingdom', from: 'Country'
      fill_in 'Zip', with: '02115'

      # select 'Primary', from: 'Rank'
      # select 'Direct contact', from: 'Source'

      # Select fields
      # select 'Admin User', from: 'Select user with role admin' if page.has_select?('Select user with role admin')
      select 'Choice 2', from: 'Select value' if page.has_select?('Select value')

      # Yes/No fields
      select 'Yes', from: 'Done yes no' if page.has_select?('Done yes no')
      select 'No', from: 'Done no yes' if page.has_select?('Done no yes')
      select 'Yes', from: 'Done blank yes no' if page.has_select?('Done blank yes no')
      select "Don't Know", from: 'Done yes no dont know' if page.has_select?('Done yes no dont know')
      select 'Yes', from: 'Done blank yes no dont know' if page.has_select?('Done blank yes no dont know')

      # True/False field
      select 'True', from: 'Done true false' if page.has_select?('Done true false')

      # Text area fields
      fill_in 'Some description', with: 'This is a detailed description with multiple lines.\nSecond line of description.'
      fill_in 'Some details', with: 'These are some details about the record.'
      fill_in 'Some notes', with: 'Important notes about this record.'
      fill_in 'Description', with: 'Another description field value.'
      fill_in 'Notes', with: 'Additional notes.'
      fill_in 'Message', with: 'A message for this record.'

      # URL and link fields
      fill_in 'A link', with: 'https://example.com/link'
      fill_in 'A url', with: 'https://example.org/page'

      # Other string fields
      # fill_in 'Player contact rank', with: 'Primary'
      fill_in 'Some year', with: '2025'
      fill_in 'Email', with: 'test@example.com'
      fill_in 'Phone', with: '555-123-4567'
      # fill_in 'Rec type', with: 'Primary'

      # Fields that reference test_with_id_recs
      if page.has_select?('Select record from table test with id recs')
        select 'test value 1', from: 'Select record from table test with id recs'
      end
      if page.has_select?('Select record from test with id recs')
        select 'Test Name 2', from: 'Select record from test with id recs'
      end
      if page.has_select?('Select record id from test with id recs')
        select '3', from: 'Select record id from test with id recs'
      end

      # fill_in 'Fixed value', with: 'Predefined value'

      # E signature fields
      # fill_in 'E signed document', with: 'consent_form.pdf'
      # fill_in 'E signed how', with: 'Electronic signature'

      # Multi-select array fields
      # We'll use the label selectors, but keep the conditional logic
      # if page.has_select?('Multi editable choices abc', multiple: true)
      #   select 'Choice A', from: 'Multi editable choices abc'
      #   select 'Choice B', from: 'Multi editable choices abc'
      # else
      #   # Fallback for JavaScript-enhanced fields
      #   find('label', text: 'Multi editable choices abc').click
      #   within('.select2-dropdown, .dropdown-menu, .choices__list') do
      #     find('li, option, div', text: 'Choice A').click
      #     find('li, option, div', text: 'Choice B').click
      #   end
      #   # Close dropdown if needed
      #   find('body').send_keys(:escape)
      # end

      # Similar approach for other multi-selects
      # if page.has_select?('Multi editable list def', multiple: true)
      #   select 'Option X', from: 'Multi editable list def'
      #   select 'Option Y', from: 'Multi editable list def'
      # end

      # if page.has_select?('Multi player contact ranks', multiple: true)
      #   select 'Primary', from: 'Multi player contact ranks'
      #   select 'Secondary', from: 'Multi player contact ranks'
      # end

      # Tag select fields
      # if page.has_select?('Tag select users with role admin', multiple: true)
      #   select 'Admin 1', from: 'Tag select users with role admin'
      #   select 'Admin 2', from: 'Tag select users with role admin'
      # end

      # if page.has_select?('Tag select some values', multiple: true)
      #   select 'Value A', from: 'Tag select some values'
      #   select 'Value B', from: 'Tag select some values'
      # end

      # Multi-select references
      # if page.has_select?('Pick multiple records from table test with id recs', multiple: true)
      #   select 'test value 1', from: 'Pick multiple records from table test with id recs'
      #   select 'test value 3', from: 'Pick multiple records from table test with id recs'
      # end

      # Tag select references
      # if page.has_select?('Tag select record from table test with id recs', multiple: true)
      #   select 'test value 2', from: 'Tag select record from table test with id recs'
      # end

      # if page.has_select?('Tag select record from test with id recs', multiple: true)
      #   select 'Test Name 1', from: 'Tag select record from test with id recs'
      # end

      # if page.has_select?('Tag select record id from test with id recs', multiple: true)
      #   select '2', from: 'Tag select record id from test with id recs'
      # end

      sleep 0.5
      click_on 'Save'
    end
  end
end
