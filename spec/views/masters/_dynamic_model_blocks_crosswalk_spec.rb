# frozen_string_literal: true

require 'rails_helper'

# Regression coverage for issue #1399: a dynamic model associated through a
# masters crosswalk column must be rendered in the master-panel loader.
RSpec.describe 'masters/_dynamic_model_blocks', type: :view do
  let(:model) do
    double('dynamic model',
           resource_name: 'dynamic_model__test_msid_fk_recs',
           full_item_types_name: 'dynamic-model--test-msid-fk-recs',
           implementation_model_name: 'test_msid_fk_rec',
           name: 'Test MSID FK Rec',
           foreign_key_name: 'msid',
           default_options: double(view_options: double(dig: nil)))
  end

  before do
    allow(view).to receive(:format_active_values).and_return('')
    allow(view).to receive(:layout_item_block_sizes).and_return(regular: 'col-md-8')

    render partial: 'masters/dynamic_model_blocks',
           locals: { category_models: [model], viewable: { dynamic_model__test_msid_fk_recs: true }, category: 'details', force_load: true,
                     panel: nil, orientation: 'none' }
  end

  it 'renders the dynamic model loader in the master panel' do
    expect(rendered).to include('dynamic-model--test-msid-fk-recs')
    expect(rendered).to include('/masters/{{id}}/dynamic_model/test_msid_fk_recs')
  end
end
