# frozen_string_literal: true

require 'rails_helper'

# Spec for OptionConfigs::PageLayoutOptions.raise_bad_configs (issue #1205).
#
# Validates that the raise_bad_configs class method correctly enforces the
# panel resource composition rules:
#
#   - A panel with a single resource of any type is always valid.
#   - A panel with 2+ resources that are all non-activity-log types is valid.
#   - A panel that mixes activity-log resources with other resource types raises FphsException.
#   - A panel with 2+ activity-log resources raises FphsException.
#   - Panels with no contains.resources key are skipped (no exception).
#   - An unresolvable resource name is treated as a non-AL type (no crash).
#
# These are RED-phase tests: the invalid cases currently do NOT raise because
# raise_bad_configs is a stub. They will pass once the implementation is added.

RSpec.describe OptionConfigs::PageLayoutOptions, type: :model do
  let(:al_item) { { type: :activity_log, resource_name: 'activity_log__case_reviews' } }
  let(:al2_item) { { type: :activity_log, resource_name: 'activity_log__contact_logs' } }
  let(:dm_item) { { type: :dynamic_model, resource_name: 'dynamic_model__contact_infos' } }
  let(:eid_item) { { type: :external_identifier, resource_name: 'scantron_ids' } }

  before do
    allow(Resources::Models).to receive(:find_by) do |args|
      case args[:resource_name].to_s
      when 'activity_log__case_reviews' then al_item
      when 'activity_log__contact_logs' then al2_item
      when 'dynamic_model__contact_infos' then dm_item
      when 'scantron_ids' then eid_item
      end
    end
  end

  # Build a duck-type option_configs double with contains.resources returning the given array.
  def make_option_configs(resources)
    contains = double('contains', resources: resources)
    double('option_configs', contains: contains)
  end

  def make_option_configs_nil_resources
    contains = double('contains', resources: nil)
    double('option_configs', contains: contains)
  end

  def make_option_configs_nil_contains
    double('option_configs', contains: nil)
  end

  describe '.raise_bad_configs' do
    context 'with a single activity log resource' do
      it 'does not raise an exception' do
        expect do
          described_class.raise_bad_configs(make_option_configs(['activity_log__case_reviews']))
        end.not_to raise_error
      end
    end

    context 'with a single dynamic model resource' do
      it 'does not raise an exception' do
        expect do
          described_class.raise_bad_configs(make_option_configs(['dynamic_model__contact_infos']))
        end.not_to raise_error
      end
    end

    context 'with a single external identifier resource' do
      it 'does not raise an exception' do
        expect do
          described_class.raise_bad_configs(make_option_configs(['scantron_ids']))
        end.not_to raise_error
      end
    end

    context 'with 2+ non-activity-log resources (DM + EID)' do
      it 'does not raise an exception' do
        expect do
          described_class.raise_bad_configs(
            make_option_configs(['dynamic_model__contact_infos', 'scantron_ids'])
          )
        end.not_to raise_error
      end
    end

    context 'with 1 activity log + 1 dynamic model (mixed types)' do
      it 'raises FphsException (mixing AL with other types is forbidden)' do
        expect do
          described_class.raise_bad_configs(
            make_option_configs(['activity_log__case_reviews', 'dynamic_model__contact_infos'])
          )
        end.to raise_error(FphsException)
      end
    end

    context 'with 1 activity log + 1 external identifier (mixed types)' do
      it 'raises FphsException (mixing AL with other types is forbidden)' do
        expect do
          described_class.raise_bad_configs(
            make_option_configs(['activity_log__case_reviews', 'scantron_ids'])
          )
        end.to raise_error(FphsException)
      end
    end

    context 'with 2 activity log resources' do
      it 'raises FphsException (multiple activity logs in one panel are forbidden)' do
        expect do
          described_class.raise_bad_configs(
            make_option_configs(['activity_log__case_reviews', 'activity_log__contact_logs'])
          )
        end.to raise_error(FphsException)
      end
    end

    context 'when contains has no resources key (nil resources)' do
      it 'does not raise an exception (no-op)' do
        expect do
          described_class.raise_bad_configs(make_option_configs_nil_resources)
        end.not_to raise_error
      end
    end

    context 'when contains is nil' do
      it 'does not raise an exception (no-op)' do
        expect do
          described_class.raise_bad_configs(make_option_configs_nil_contains)
        end.not_to raise_error
      end
    end

    context 'with an unresolvable resource name' do
      it 'does not raise an exception (treated as non-AL type)' do
        expect do
          described_class.raise_bad_configs(make_option_configs(['nonexistent_resource']))
        end.not_to raise_error
      end
    end

    context 'with unresolvable resource mixed with activity log' do
      it 'raises FphsException (unresolvable treated as non-AL, so AL+other mix is forbidden)' do
        expect do
          described_class.raise_bad_configs(
            make_option_configs(['activity_log__case_reviews', 'nonexistent_resource'])
          )
        end.to raise_error(FphsException)
      end
    end
  end
end
