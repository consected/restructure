# frozen_string_literal: true

# Purpose: verify the cached protocol reference block reflects protocol-tree changes.

require 'rails_helper'

RSpec.describe 'admin report info block cache', type: :view do
  before do
    Rails.cache.delete('info-block-protocol-block')
    @report = instance_double(Report, persisted?: false)
    assign(:report, @report)
    allow(view).to receive(:current_admin).and_return(instance_double(Admin, can_admin?: false))
    allow(view).to receive(:render).and_wrap_original do |original, *args, **kwargs|
      partial = kwargs[:partial] || args.first
      if %w[admin/reports/info_block admin/reference_data/protocol_block].include?(partial)
        original.call(*args, **kwargs)
      else
        ''
      end
    end
  end

  {
    'protocol' => -> { Classification::Protocol.first! },
    'sub-process' => -> { Classification::SubProcess.first! },
    'protocol event' => -> { Classification::ProtocolEvent.first! }
  }.each do |record_type, find_record|
    it "refreshes protocol reference content after a #{record_type} changes without clearing the cache" do
      record = find_record.call
      expect(render_info_block).to include(record.name)

      updated_name = "Cache invalidation #{SecureRandom.hex(4)}"
      record.current_admin = Admin.active.first
      allow(record).to receive(:clear_rails_cache_on_save?).and_return(false)
      allow(record).to receive(:create_activity_tracker_events) if record.is_a?(Classification::Protocol)
      record.update!(name: updated_name)

      expect(render_info_block).to include(updated_name)
    end
  end

  private

  def render_info_block
    view.render(partial: 'admin/reports/info_block', locals: { object_instance: @report })
  end
end
