# frozen_string_literal: true

# The *_common_search_results_template_item partials (activity logs, dynamic models, external
# identifiers) render the template state script for one definition option. Whether the shared
# Handlebars templates are also emitted is an explicit decision by the caller, through the optional
# `state_only` local (default false):
#   - the admin sample forms render the partials directly and need the full templates
#   - the shared template_config set partial passes `state_only: true`, so the lazy response
#     carries state alone
# Previously the partials inferred state-only for every live definition, which silently stripped
# the templates from the admin sample forms.

require 'rails_helper'

RSpec.describe 'common_search_results_template_item partials', type: :view do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include PlayerContactSupport
  include ActivityLogSupport

  before_all do
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_histories
  end

  before do
    allow(view).to receive(:current_user).and_return(@user)
  end

  shared_examples 'a template item partial' do
    let(:state_id_prefix) { "fpa_state_config--#{state_name}--v#{definition.current_def_version}" }

    # Templates are queued on the view for the Handlebars bundle rather than written inline
    let(:requested_template_ids) do
      view.instance_variable_get(:@requested_handlebars_templates).to_a.pluck(:id)
    end

    it 'emits the state and the full Handlebars templates by default, as the admin sample forms need' do
      render partial: partial_path, locals: { def_record: definition, option_type_config: option_config }

      expect(rendered).to include(state_id_prefix)
      expect(rendered).not_to include("#{state_id_prefix}--form")
      expect(requested_template_ids).to include("#{state_name.hyphenate}-result-template")
    end

    it 'emits only the form state when the caller requests state_only' do
      render partial: partial_path,
             locals: { def_record: definition, option_type_config: option_config, state_only: true }

      expect(rendered).to include("#{state_id_prefix}--form")
      expect(requested_template_ids).to be_empty
    end
  end

  describe 'dynamic_models' do
    let(:partial_path) { 'dynamic_models/common_search_results_template_item' }
    let(:definition) do
      generate_test_dynamic_model table_name: 'test_item_state_only_recs'
    end
    let(:option_config) { definition.option_configs.first }
    let(:state_name) { "#{definition.item_type_name}_#{option_config.name}".underscore }

    it_behaves_like 'a template item partial'
  end

  describe 'activity_logs' do
    let(:partial_path) { 'activity_logs/common_search_results_template_item' }
    let(:definition) do
      generate_test_activity_log
      ActivityLog.active.find_by(name: 'activity_log_player_contact_emails')
    end
    let(:option_config) { definition.option_configs.find { |c| c.name == :primary } }
    let(:state_name) { "#{definition.full_item_type_name}_#{option_config.name}".underscore }

    it_behaves_like 'a template item partial'
  end
end
