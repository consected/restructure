# frozen_string_literal: true

require 'rails_helper'

# Unit tests for PageLayoutsHelper methods.
#
# format_active_values (issue #584):
#   Verifies correct formatting of sublist filter button defaults.
#
# resource_render_info (issue #1180):
#   Verifies that the new helper correctly resolves per-resource rendering metadata
#   (template_name, route_path, wrapper_class, viewable_key) for all three supported
#   resource types (activity log, dynamic model, external identifier) in both
#   :master_panel and :standalone_page contexts, and that explicit template_prefix
#   overrides are honoured. Also verifies that an unresolvable resource name returns nil.

RSpec.describe PageLayoutsHelper, type: :helper do
  describe '#format_active_values' do
    it 'returns empty string for nil values' do
      expect(helper.format_active_values(nil)).to eq('')
    end

    it "returns 'all' when value is 'all' string" do
      expect(helper.format_active_values('all')).to eq('all')
    end

    it "returns 'none' for empty array" do
      expect(helper.format_active_values([])).to eq('none')
    end

    it 'returns comma-separated string for array of integers' do
      expect(helper.format_active_values([10, 5, -1])).to eq('10,5,-1')
    end

    it 'returns comma-separated string for array of strings' do
      expect(helper.format_active_values(%w[primary secondary])).to eq('primary,secondary')
    end

    it 'returns comma-separated string for mixed array' do
      expect(helper.format_active_values([10, 'active', 5])).to eq('10,active,5')
    end

    it 'returns string representation for single value' do
      expect(helper.format_active_values(10)).to eq('10')
    end

    it 'converts symbols to strings' do
      expect(helper.format_active_values(:active)).to eq('active')
    end
  end

  # ------------------------------------------------------------------ #
  # resource_render_info (issue #1180)
  # ------------------------------------------------------------------ #
  describe '#resource_render_info' do
    let(:activity_log_item) do
      Resources::Models::Item.new.merge(
        type: :activity_log,
        resource_name: 'activity_log__case_reviews',
        hyphenated_name: 'activity-log--case-reviews',
        base_route_segments: 'activity_log/case_reviews'
      )
    end

    let(:dynamic_model_item) do
      Resources::Models::Item.new.merge(
        type: :dynamic_model,
        resource_name: 'dynamic_model__contact_infos',
        hyphenated_name: 'contact-infos',
        base_route_segments: 'dynamic_model/contact_infos'
      )
    end

    let(:external_id_item) do
      Resources::Models::Item.new.merge(
        type: :external_identifier,
        resource_name: 'scantron_ids',
        hyphenated_name: 'scantron-ids',
        base_route_segments: 'scantron_ids'
      )
    end

    before do
      allow(Resources::Models).to receive(:find_by) do |args|
        if args[:resource_name]
          case args[:resource_name].to_s
          when 'activity_log__case_reviews' then activity_log_item
          when 'dynamic_model__contact_infos' then dynamic_model_item
          when 'scantron_ids' then external_id_item
          else nil
          end
        elsif args[:resource_item_name]
          # Simulate the fallback lookup used when a singular resource name is passed
          case args[:resource_item_name].to_s
          when 'activity_log__case_review' then activity_log_item
          when 'dynamic_model__contact_info' then dynamic_model_item
          else nil
          end
        end
      end
    end

    context 'with an activity log resource' do
      context 'when a singular resource name is passed (as sent by _show_row.html.erb before pluralizing)' do
        it 'pluralises the name so the template name matches the registered Handlebars template' do
          info = helper.resource_render_info('activity_log__case_review', context: :standalone_page)
          expect(info[:template_name]).to eq('activity-log--case-reviews-page-result-template')
        end
      end

      context 'in :master_panel context' do
        subject(:info) { helper.resource_render_info('activity_log__case_reviews', context: :master_panel) }

        it 'returns template_name with -main-result-template suffix' do
          expect(info[:template_name]).to eq('activity-log--case-reviews-main-result-template')
        end

        it 'returns the correct route_path' do
          expect(info[:route_path]).to eq('activity_log/case_reviews')
        end

        it 'returns the activity-logs-generic-block wrapper class' do
          expect(info[:wrapper_class]).to eq('activity-logs-generic-block')
        end

        it 'returns the resource_name symbolised as viewable_key' do
          expect(info[:viewable_key]).to eq(:activity_log__case_reviews)
        end
      end

      context 'in :standalone_page context' do
        subject(:info) { helper.resource_render_info('activity_log__case_reviews', context: :standalone_page) }

        it 'returns template_name with -page-result-template suffix' do
          expect(info[:template_name]).to eq('activity-log--case-reviews-page-result-template')
        end
      end
    end

    context 'with a dynamic model resource' do
      context 'in :master_panel context' do
        subject(:info) { helper.resource_render_info('dynamic_model__contact_infos', context: :master_panel) }

        it 'returns template_name using the full namespaced hyphenated resource name with -list-template suffix' do
          expect(info[:template_name]).to eq('dynamic-model--contact-infos-list-template')
        end

        it 'returns the correct route_path including namespace segment' do
          expect(info[:route_path]).to eq('dynamic_model/contact_infos')
        end

        it 'returns the dynamic-model-generic-block wrapper class' do
          expect(info[:wrapper_class]).to eq('dynamic-model-generic-block')
        end

        it 'returns the resource_name symbolised as viewable_key' do
          expect(info[:viewable_key]).to eq(:dynamic_model__contact_infos)
        end
      end

      context 'in :standalone_page context' do
        subject(:info) { helper.resource_render_info('dynamic_model__contact_infos', context: :standalone_page) }

        it 'returns the same -list-template regardless of context' do
          expect(info[:template_name]).to eq('dynamic-model--contact-infos-list-template')
        end
      end
    end

    context 'with an external identifier resource' do
      context 'in :master_panel context' do
        subject(:info) { helper.resource_render_info('scantron_ids', context: :master_panel) }

        it 'returns template_name with -list-template suffix' do
          expect(info[:template_name]).to eq('scantron-ids-list-template')
        end

        it 'returns the bare table name as route_path (no namespace)' do
          expect(info[:route_path]).to eq('scantron_ids')
        end

        it 'returns the external-id-generic-block wrapper class' do
          expect(info[:wrapper_class]).to eq('external-id-generic-block')
        end

        it 'returns the resource_name symbolised as viewable_key' do
          expect(info[:viewable_key]).to eq(:scantron_ids)
        end
      end

      context 'in :standalone_page context' do
        subject(:info) { helper.resource_render_info('scantron_ids', context: :standalone_page) }

        it 'returns the same -list-template regardless of context' do
          expect(info[:template_name]).to eq('scantron-ids-list-template')
        end
      end
    end

    context 'when a singular dynamic model resource name is passed' do
      it 'pluralises the name so the template name matches the registered Handlebars template' do
        info = helper.resource_render_info('dynamic_model__contact_info', context: :standalone_page)
        expect(info[:template_name]).to eq('dynamic-model--contact-infos-list-template')
      end

      it 'does not use the singular form in the template name' do
        info = helper.resource_render_info('dynamic_model__contact_info', context: :master_panel)
        expect(info[:template_name]).not_to include('contact-info-list')
      end
    end

    context 'with an explicit template_prefix override' do
      context 'dynamic model with template_prefix: "page-"' do
        subject(:info) do
          helper.resource_render_info('dynamic_model__contact_infos', context: :standalone_page, template_prefix: 'page-')
        end

        it 'uses the explicit prefix to build the template name' do
          expect(info[:template_name]).to eq('dynamic-model--contact-infos-page-result-template')
        end
      end

      context 'activity log with template_prefix: "custom-"' do
        subject(:info) do
          helper.resource_render_info('activity_log__case_reviews', context: :master_panel, template_prefix: 'custom-')
        end

        it 'uses the explicit prefix to build the template name overriding the context default' do
          expect(info[:template_name]).to eq('activity-log--case-reviews-custom-result-template')
        end
      end
    end

    context 'with an unresolvable resource name' do
      it 'returns nil' do
        expect(helper.resource_render_info('nonexistent_resource', context: :master_panel)).to be_nil
      end
    end
  end
end
