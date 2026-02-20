# frozen_string_literal: true

# EditFormFieldHelper Spec
#
# Tests the calculate_with JavaScript generation in edit_form_field_helper.rb.
#
# Test Coverage:
# - javascript_tag with heredoc block must produce valid JavaScript (not HTML-encoded)
#   - Verifies that single quotes in the heredoc are NOT html-entity-encoded to &#39;
#   - Verifies that JSON content (containing double quotes) is NOT html-entity-encoded to &quot;
#   - Regression test for bug where Rails 7.2 capture helper HTML-escaped plain String
#     return values from javascript_tag blocks, producing invalid <script> content
#     (e.g. _fpa.calculate_with[&#39;field&#39;] instead of _fpa.calculate_with['field'])

require 'rails_helper'

RSpec.describe EditFields::EditFormFieldHelper, type: :helper do
  describe 'calculate_with script generation' do
    # Simulate what edit_form_field_helper.rb does for the calculate_with option:
    #   javascript_tag(nonce: true) do
    #     <<~END_JS.html_safe
    #       _fpa.calculate_with['#{field_name_sym}'] = #{cw.to_json.html_safe};
    #       _fpa.utils.calc_field('#{field_name_sym}', '#{form_object_type}');
    #     END_JS
    #   end
    #
    # Without .html_safe on the heredoc, Rails 7.2's capture helper HTML-escapes
    # plain Strings, turning ' into &#39; and " into &quot; inside the <script> tag.

    before do
      # Stub content_security_policy_nonce since we're not in a real request context
      allow(helper).to receive(:content_security_policy_nonce).and_return('test-nonce')
    end

    it 'produces valid JavaScript without HTML entities when heredoc is marked html_safe' do
      field_name = 'tmoca_score'
      model_type = 'dynamic_model__play_ipa_phone_screen_tmoca_scores_rec'
      calculate_with = { 'sum' => %w[field_a field_b field_c] }

      result = helper.javascript_tag(nonce: true) do
        <<~END_JS.html_safe
          _fpa.calculate_with = _fpa.calculate_with || {};
          var cwdef = _fpa.calculate_with['#{field_name}'] = #{calculate_with.to_json.html_safe};
          _fpa.utils.calc_field('#{field_name}', '#{model_type}');
        END_JS
      end

      # The script tag content must contain raw JavaScript, not HTML entities
      expect(result).to include("_fpa.calculate_with['tmoca_score']")
      expect(result).to include('"sum":["field_a","field_b","field_c"]')
      expect(result).to include("_fpa.utils.calc_field('tmoca_score'")

      # Must NOT contain HTML entities inside the script tag
      expect(result).not_to include('&#39;')
      expect(result).not_to include('&quot;')
      expect(result).not_to include('&amp;')
    end

    it 'would produce HTML-encoded content without html_safe (demonstrating the bug)' do
      field_name = 'tmoca_score'
      calculate_with = { 'sum' => %w[field_a field_b] }

      # Without .html_safe, Rails 7.2's capture helper HTML-escapes the string
      result = helper.javascript_tag(nonce: true) do
        <<~END_JS
          _fpa.calculate_with['#{field_name}'] = #{calculate_with.to_json};
        END_JS
      end

      # This demonstrates the bug: the content gets HTML-entity-encoded
      expect(result).to include('&#39;'), 'Expected HTML-encoded single quotes (demonstrating the bug)'
      expect(result).to include('&quot;'), 'Expected HTML-encoded double quotes (demonstrating the bug)'
    end
  end
end
