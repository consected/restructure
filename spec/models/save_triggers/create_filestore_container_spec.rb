# frozen_string_literal: true

require 'rails_helper'

# Tests the reference scope selected by the create_filestore_container save trigger.
RSpec.describe SaveTriggers::CreateFilestoreContainer, type: :model do
  let(:master) { double('master') }
  let(:item) do
    double('item', master: master, attributes: {}, save_trigger_results: {}, trigger_variables: {})
  end
  let(:reference_options) do
    {
      to_record_type: 'nfs_store__manage__container',
      filter_by: { name: 'docs' },
      active: true
    }
  end

  before do
    allow(FieldDefaults).to receive(:calculate_default).with(item, 'docs').and_return('docs')
  end

  it 'looks for an existing container in the current master' do
    trigger = described_class.new({ name: 'docs', skip_if_exists: 'master' }, item)
    expect(ModelReference).to receive(:find_references).with(master, **reference_options).and_return([])

    expect(trigger.lookup_existing).to eq([])
  end

  it 'looks for an existing container created by the current user' do
    trigger = described_class.new({ name: 'docs', skip_if_exists: 'user_is_creator' }, item)
    expect(ModelReference).to receive(:find_references).with(
      item,
      to_record_type: reference_options[:to_record_type],
      filter_by: reference_options[:filter_by],
      active: reference_options[:active],
      ref_created_by_user: 'user_is_creator'
    ).and_return([])

    expect(trigger.lookup_existing).to eq([])
  end
end
