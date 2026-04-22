# frozen_string_literal: true

require 'rails_helper'

# Tests for issue #1066:
# - Show resolved definition versioning in activity log admin details
RSpec.describe Admin::ActivityLogsController, type: :controller do
  include AdminActivityLogSupport

  render_views

  def object_class
    ActivityLog
  end

  def item
    @activity_log
  end

  before(:context) do
    @path_prefix = '/admin'
  end

  before :example do
    raise "Bad Seed! #{PlayerContact.valid_rec_types}" if PlayerContact.valid_rec_types.empty?
  end

  before_each_login_admin

  it_behaves_like 'a standard admin controller'

  describe 'GET #edit issue #1066 details display' do
    it 'shows current version when current-definition mode is resolved' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join

      al = create_item(
        {
          name: "test_al_version_mode_#{suffix}",
          item_type: 'player_contact',
          rec_type: 'email',
          action_when_attribute: 'emailed_when',
          current_admin: @admin
        },
        @admin
      )

      allow_any_instance_of(ActivityLog).to receive(:uses_current_definition_version?).and_return(true)

      get :edit, params: { id: al.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector('.def-version-resolution', text: /current version/i)
    end

    it 'shows version at record creation when definition-time versioning is resolved' do
      suffix = Array.new(8) { ('a'..'z').to_a.sample }.join

      al = create_item(
        {
          name: "test_al_version_mode_#{suffix}",
          item_type: 'player_contact',
          rec_type: 'email',
          action_when_attribute: 'emailed_when',
          current_admin: @admin
        },
        @admin
      )

      allow_any_instance_of(ActivityLog).to receive(:uses_current_definition_version?).and_return(false)

      get :edit, params: { id: al.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector('.def-version-resolution', text: /record creation/i)
    end
  end
end
