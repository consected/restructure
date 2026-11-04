# frozen_string_literal: true

# Purpose: Verify both tracker Handlebars templates generate a preview URL for message notifications and retain their existing linked-item fallback.

require 'rails_helper'

RSpec.describe 'Message notification tracker templates', type: :view do
  let(:template_sources) { {} }

  before do
    allow(view).to receive(:write_handlebars_template) do |template_id, content = nil, **_options, &template|
      template_sources[template_id] = content || view.capture(&template)
      '/compiled-template.js'
    end
  end

  it 'generates the preview link in tracker rows' do
    render partial: 'trackers/search_results_template'

    source = template_sources.fetch('tracker_result-partial')
    expect(source).to include('/masters/{{../master_id}}/message_notifications/{{../record_id}}')
    expect(source).to include('postprocessors_trackers.open_message_notification')
    expect(source).to include('postprocessors_activity_logs.open_{{../record_type_us}}')
  end

  it 'generates the preview link in tracker-history rows' do
    render partial: 'tracker_histories/search_results_template'

    source = template_sources.fetch('tracker_history_result-partial')
    expect(source).to include('/masters/{{../master_id}}/message_notifications/{{../record_id}}')
    expect(source).to include('postprocessors_trackers.open_message_notification')
    expect(source).to include('postprocessors_activity_logs.open_{{../record_type_us}}')
  end
end
