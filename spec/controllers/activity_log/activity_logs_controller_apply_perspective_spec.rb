# frozen_string_literal: true

require 'rails_helper'

# Issue #1362 - #apply_perspective resolves the `default_activity_log_perspective` admin
# config the same way masters/_search_results_resources_panel.html.erb does, using
# Formatter::Substitution against `current_user`. Mirrors that view's fix: only `role_name`
# is exposed to the substitution, so a literal (non-structural) tag such as {{first_name}}
# can never resolve to real per-user data - it silently resolves blank instead.
RSpec.describe ActivityLog::ActivityLogsController, type: :controller do
  include ModelSupport

  let(:resource_name) { 'activity_log__case_reviews' }
  let(:implementation_class) { double('implementation_class', resource_name: resource_name) }
  let(:user) { create_user.first }

  before do
    allow(controller).to receive_messages(current_user: user, params: ActionController::Parameters.new(panel_name: 'some-panel'))
    controller.instance_variable_set(:@implementation_class, implementation_class)
    controller.instance_variable_set(:@master, double('master'))
  end

  it 'does not leak the real current_user attribute for a literal {{first_name}} config' do
    allow(Admin::AppConfiguration).to receive(:hash_for)
      .with(:default_activity_log_perspective, user)
      .and_return(resource_name => '{{first_name}}')

    # A literal tag resolves blank (ignore_missing: true), so perspective_name stays blank
    # and the method returns early WITHOUT ever looking up a panel/perspective using the
    # user's real name.
    expect(Admin::PageLayout).not_to receive(:active)

    controller.send(:apply_perspective)
  end

  it 'still resolves a structural {{#is role_name ...}} config against the real current_user role' do
    allow(user).to receive(:role_names).and_return(['coordinator'])
    allow(Admin::AppConfiguration).to receive(:hash_for)
      .with(:default_activity_log_perspective, user)
      .and_return(resource_name => "{{#is role_name '===' 'coordinator'}}coordinator_view{{else}}other{{/is}}")

    # Confirms perspective_name resolved to a non-blank value ('coordinator_view') and
    # processing proceeded into the panel lookup, rather than stopping early.
    expect(Admin::PageLayout).to receive(:active).and_call_original

    expect { controller.send(:apply_perspective) }.to raise_error(FphsException, /no active panel found/)
  end
end
