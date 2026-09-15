# frozen_string_literal: true

require 'rails_helper'

# RED phase test for issue #1445 (problem 1 - Symbol/String mismatch in
# ActivityLog::ActivityLogsController#edit_form_extras fallback branches).
#
# Reproduces the actual user-facing failure: requesting a new activity log
# edit form with an `extra_log_type` param naming a type that is NOT present
# in the definition's `option_configs_names` forces `handle_option_type_config`
# to leave `@option_type_config` nil, which in turn forces `edit_form_extras`
# down one of its `||=` fallback branches. Because those branches subtract
# String arrays from the Symbol arrays returned by `view_attribute_list` /
# `view_blank_log_attribute_list`, `:tracker_history_id` is never actually
# removed from `item_list`. The edit form partial
# (app/views/common_templates/_edit_form.html.erb) then raises `FphsException`
# for `tracker_history_id`, since it is a synthetic field that is never a real
# database column (see `ignore_fields` in
# lib/active_record/migration/app_generator.rb).
#
# This spec asserts the form renders successfully instead of raising - it
# currently fails today with the `FphsException` described above.
RSpec.describe ActivityLog::PlayerContactPhonesController, type: :controller do
  include ActivityLogSupport
  include ModelSupport
  include MasterSupport

  render_views

  before(:each) do
    SetupHelper.setup_al_player_contact_phones

    create_admin
    create_user
    create_master @user

    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type

    @player_contact = @master.player_contacts.create!(
      current_user: @user,
      data: '(516)262-1291',
      source: 'nfl',
      rank: 10,
      rec_type: 'phone'
    )
  end

  describe 'GET #new with an extra_log_type not present in option_configs_names' do
    before_each_login_user

    it 'renders the edit form instead of raising FphsException about tracker_history_id' do
      expect(ActivityLog::PlayerContactPhone.definition.option_configs_names).not_to include(:not_a_real_extra_type)

      get :new, params: {
        master_id: @master.id,
        item_id: @player_contact.id,
        extra_log_type: 'not_a_real_extra_type'
      }

      # FphsException raised by the edit form partial for the "tracker_history_id"
      # field is caught by the global exception handling in
      # app/controllers/concerns/app_exception_handler.rb and rendered as an
      # error page, rather than propagating as a Ruby exception here - so the
      # response status/body is the only reliable evidence of the underlying
      # failure.
      expect(response.body).not_to match(/tracker_history_id/)
      expect(response).to have_http_status(:ok)
    end
  end
end
