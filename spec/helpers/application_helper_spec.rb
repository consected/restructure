# frozen_string_literal: true

# ApplicationHelper Spec
#
# Tests helper methods used across the application for view rendering and error handling.
#
# Test Coverage:
# - #remove_empty_error: Removes DoNotDisplayErrorMessage markers from validation errors
#   - Filters out DoNotDisplayErrorMessage markers while preserving valid error messages
#   - Removes entire error fields that contain only DoNotDisplayErrorMessage markers
#   - Ensures clean error display to users by eliminating internal marker constants
# - #partial_cache_key (issue #1270): the cache key/template version token stays stable
#   across user saves that don't change relevant attributes, and still changes when the
#   user's app type genuinely changes

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#remove_empty_error' do
    let(:user) { User.new }
    let(:errors) { user.errors }

    it 'removes errors with DoNotDisplayErrorMessage marker' do
      errors.add(:field1, 'Valid error')
      errors.add(:field2, ApplicationHelper::DoNotDisplayErrorMessage)
      errors.add(:field3, 'Another error')
      errors.add(:field3, ApplicationHelper::DoNotDisplayErrorMessage)

      helper.remove_empty_error(errors)

      expect(errors[:field1]).to include('Valid error')
      expect(errors[:field2]).to be_empty
      # Field3 should have "Another error" but not the empty DoNotDisplayErrorMessage
      expect(errors[:field3]).to include('Another error')
      # The empty string should have been removed
      expect(errors.messages[:field3]).not_to include('')
    end

    it 'removes only the field if it contains only DoNotDisplayErrorMessage' do
      errors.add(:terms_of_use_accepted, ApplicationHelper::DoNotDisplayErrorMessage)

      helper.remove_empty_error(errors)

      # The entire key should be removed
      expect(errors.messages.key?(:terms_of_use_accepted)).to be false
    end
  end
end

describe '#handlebars_template_tag' do
  # Batched precompilation: templates are queued and retrieved together via retrieve_requested_handlebars_templates
  # Individual calls return empty string; templates are loaded as a single batch via AJAX

  before do
    # Stub write_handlebars_template to avoid actual file writes
    allow(helper).to receive(:write_handlebars_template).and_return("#{HandlebarsPrecompiler::URL_RELATIVE_PATH}my-template-abc123def4567.js")
  end

  context 'with batched precompilation' do
    it 'returns empty string since templates are batched for later retrieval' do
      result = helper.handlebars_template_tag('search-results-template') do
        '<div>{{name}}</div>'.html_safe
      end

      # Templates are now batched and retrieved via retrieve_requested_handlebars_templates
      expect(result).to eq('')
    end

    it 'does not include inline template content in the output' do
      result = helper.handlebars_template_tag('my-template') do
        '<div>{{content}}</div>'.html_safe
      end

      expect(result).not_to include('{{content}}')
    end

    it 'queues template for batched retrieval' do
      helper.handlebars_template_tag('my-template') do
        '<div>test</div>'.html_safe
      end

      queued = helper.instance_variable_get(:@requested_handlebars_templates)
      expect(queued).to be_an(Array)
      expect(queued.first[:id]).to eq('my-template')
    end

    it 'identifies templates by css_class containing handlebars-template' do
      helper.handlebars_template_tag('my-template', css_class: 'hidden handlebars-template') do
        '<div>test</div>'.html_safe
      end

      queued = helper.instance_variable_get(:@requested_handlebars_templates)
      expect(queued.first[:is_partial]).to be false
    end

    it 'identifies partials by css_class containing handlebars-partial' do
      helper.handlebars_template_tag('my-partial', css_class: 'hidden handlebars-partial') do
        '<div>test</div>'.html_safe
      end

      queued = helper.instance_variable_get(:@requested_handlebars_templates)
      expect(queued.first[:is_partial]).to be true
    end

    it 'calls write_handlebars_template with template id and is_partial' do
      expect(helper).to receive(:write_handlebars_template)
        .with('my-template', is_partial: false)
        .and_yield
        .and_return("#{HandlebarsPrecompiler::URL_RELATIVE_PATH}my-template-abc123.js")

      helper.handlebars_template_tag('my-template') do
        '<div>test</div>'.html_safe
      end
    end

    it 'passes is_partial: true when css_class includes handlebars-partial' do
      expect(helper).to receive(:write_handlebars_template)
        .with('my-partial', is_partial: true)
        .and_yield
        .and_return("#{HandlebarsPrecompiler::URL_RELATIVE_PATH}my-partial-abc123.js")

      helper.handlebars_template_tag('my-partial', css_class: 'hidden handlebars-partial') do
        '<span>partial</span>'.html_safe
      end
    end
  end
end

# Purpose (issue #1270): partial_cache_key previously embedded the user's
# `updated_at` timestamp. Since User is saved on almost every request (Devise
# trackable sign-in tracking, app type switching), this made the cache key -
# and therefore the /pages/<token>/template URL - change far more often than
# necessary, defeating the long-lived browser cache. These specs confirm the
# key stays stable across saves that don't affect its relevant inputs, and
# still changes when the app type genuinely changes.
describe '#partial_cache_key' do
  include ModelSupport

  before :all do
    create_admin
  end

  before do
    helper.define_singleton_method(:current_admin) { nil }
    helper.define_singleton_method(:current_user) { @current_user }
  end

  it 'is unchanged when the user is saved without a relevant attribute change' do
    user, = create_user
    helper.instance_variable_set(:@current_user, user)

    before_key = helper.partial_cache_key(:loaded, force_user_or_admin: user)
    user.update!(first_name: 'Changed Name')
    after_key = helper.partial_cache_key(:loaded, force_user_or_admin: user)

    expect(after_key).to eq(before_key)
  end

  it 'changes when the user app type changes' do
    user, = create_user
    other_app_type = Admin::AppType.active.where.not(id: user.app_type_id).first
    skip 'No second active app type available for this test' unless other_app_type

    before_key = helper.partial_cache_key(:loaded, force_user_or_admin: user)
    user.current_admin = @admin
    user.update!(app_type: other_app_type)
    after_key = helper.partial_cache_key(:loaded, force_user_or_admin: user)

    expect(after_key).not_to eq(before_key)
  end
end
