# frozen_string_literal: true

# CommonTemplatesHelper#version_diff_field_html spec (issue #1343)
#
# Root cause investigation for issue #1343 found that the admin "Versions" panel was
# slow even with a modest number of versions (as few as 50), independent of the
# thousands-of-versions scenario described in the issue. The template
# app/views/admin/common_templates/_def_version_diff_changes.html.erb previously
# created TWO separate Diffy::Diff instances per changed field per version-pair
# (one for line-number/chunk info, one via Diffy::SplitDiff for HTML rendering) -
# each one forks the system `diff` binary via tempfiles over the WHOLE field value.
#
# These specs verify the new #version_diff_field_html helper:
# - produces word-level highlighted left/right (previous/current) rendered HTML,
#   the same as before
# - only diffs the full field value ONCE per call (regression guard against
#   reintroducing the duplicate whole-field subprocess fork). Diffy's own
#   word-level highlighting still forks a small diff per changed line
#   internally - that cost is proportional to the actual number of changed
#   lines, not to field size, and is unaffected by this fix.
# - falls back to whole-line highlighting (no per-chunk forks) when a field has
#   many scattered separately-changed chunks, so a heavily-edited options field
#   can't multiply subprocess forks and reintroduce the #1343 timeout risk
# - counts real word-highlight chunk-pairs the same way Diffy does internally
#   (rejecting the "\ No newline at end of file" pseudo-chunk first, and never
#   counting the leading ---/+++ header line pair) - an inexact count could
#   either defeat the safety cap or fall back earlier than necessary
# - bounds total word-highlight forks across a whole rendered panel (many
#   fields each just under the per-field cap), not just a single field
# - supports optional line-number annotation for multiline fields

require 'rails_helper'

RSpec.describe CommonTemplatesHelper, type: :helper do
  describe '#version_diff_field_html' do
    it 'renders removed content on the left and added content on the right, with the changed word highlighted' do
      result = helper.version_diff_field_html("line1\nline2\nline3", "line1\nCHANGED\nline3")

      expect(result[:left]).to include('<li class="del"><del><strong>line2</strong></del></li>')
      expect(result[:right]).to include('<li class="ins"><ins><strong>CHANGED</strong></ins></li>')
    end

    it 'only highlights the changed portion of a partially-changed line' do
      result = helper.version_diff_field_html("field_1:\n  label: First Field\n", "field_1:\n  label: First Field Updated\n")

      expect(result[:left]).to include('<li class="del"><del>  label: First Field</del></li>')
      expect(result[:right]).to include('<li class="ins"><ins>  label: First Field<strong> Updated</strong></ins></li>')
    end

    it 'returns html with no del/ins markup when there is no change' do
      result = helper.version_diff_field_html('same content', 'same content')

      expect(result[:left]).not_to include('<del>')
      expect(result[:right]).not_to include('<ins>')
    end

    it 'does not leak diff header/context lines (---, +++, @@) into the rendered output' do
      result = helper.version_diff_field_html("line1\nline2\nline3", "line1\nCHANGED\nline3")

      expect(result[:left]).not_to match(/@@|---|\+\+\+/)
      expect(result[:right]).not_to match(/@@|---|\+\+\+/)
    end

    it 'adds line-number annotations when show_line_numbers is true' do
      previous = (1..5).map { |i| "line#{i}" }.join("\n")
      current = (1..5).map { |i| i == 3 ? 'CHANGED' : "line#{i}" }.join("\n")

      result = helper.version_diff_field_html(previous, current, show_line_numbers: true)

      expect(result[:left]).to have_content_tag_with('span', 'class="line-number"')
      expect(result[:right]).to have_content_tag_with('span', 'class="line-number"')
    end

    it 'does not add line-number annotations when show_line_numbers is false (default)' do
      previous = (1..5).map { |i| "line#{i}" }.join("\n")
      current = (1..5).map { |i| i == 3 ? 'CHANGED' : "line#{i}" }.join("\n")

      result = helper.version_diff_field_html(previous, current)

      expect(result[:left]).not_to include('line-number')
      expect(result[:right]).not_to include('line-number')
    end

    it 'only diffs the full field value once per call, avoiding the old duplicate whole-field subprocess fork' do
      previous_val = "a\nb\nc\nd\ne"
      current_val = "a\nx\nc\ny\ne"
      full_value_diff_calls = 0
      original_new = Diffy::Diff.method(:new)
      allow(Diffy::Diff).to receive(:new) do |left, right, *rest, **kwargs|
        full_value_diff_calls += 1 if left == previous_val && right == current_val
        original_new.call(left, right, *rest, **kwargs)
      end

      helper.version_diff_field_html(previous_val, current_val, show_line_numbers: true)

      expect(full_value_diff_calls).to eq(1)
    end

    it 'falls back to whole-line highlighting (a single fork) when there are many scattered changed chunks' do
      chunk_count = CommonTemplatesHelper::MAX_WORD_HIGHLIGHT_CHUNKS_PER_FIELD + 10
      previous_val = (1..(chunk_count * 2)).map { |i| i.even? ? "line#{i}_a" : "same#{i}" }.join("\n")
      current_val = (1..(chunk_count * 2)).map { |i| i.even? ? "line#{i}_b" : "same#{i}" }.join("\n")

      call_count = 0
      original_new = Diffy::Diff.method(:new)
      allow(Diffy::Diff).to receive(:new) do |*args, **kwargs|
        call_count += 1
        original_new.call(*args, **kwargs)
      end

      result = helper.version_diff_field_html(previous_val, current_val)

      expect(call_count).to eq(1) # no per-chunk word-highlight forks
      expect(result[:left]).not_to include('<strong>')
      expect(result[:right]).not_to include('<strong>')
      expect(result[:left]).to include('<li class="del"><del>line2_a</del></li>')
      expect(result[:right]).to include('<li class="ins"><ins>line2_b</ins></li>')
    end

    it 'still word-highlights when the number of changed chunks is at the threshold' do
      chunk_count = CommonTemplatesHelper::MAX_WORD_HIGHLIGHT_CHUNKS_PER_FIELD
      previous_val = (1..(chunk_count * 2)).map { |i| i.even? ? "line#{i}_a" : "same#{i}" }.join("\n")
      current_val = (1..(chunk_count * 2)).map { |i| i.even? ? "line#{i}_b" : "same#{i}" }.join("\n")

      result = helper.version_diff_field_html(previous_val, current_val)

      expect(result[:left]).to include('<strong>')
      expect(result[:right]).to include('<strong>')
    end

    it 'does not miscount the leading ---/+++ header pair as a real changed chunk' do
      # A single one-line change has exactly ONE real del/ins chunk-pair. With
      # include_diff_info: true, the leading `--- .. / +++ ..` header lines also
      # look like a (removed, added) pair, but Diffy itself never word-diffs
      # them - our counter must not either, or it would fall back one field
      # earlier than necessary.
      result = helper.version_diff_field_html("line1\nline2\nline3", "line1\nCHANGED\nline3")

      expect(result[:left]).to include('<strong>line2</strong>')
      expect(result[:right]).to include('<strong>CHANGED</strong>')
    end

    it 'still counts a real change split by the "no newline at end of file" marker' do
      # When the previous value has no trailing newline, Diffy inserts a
      # "\ No newline at end of file" pseudo-chunk that can sit BETWEEN a real
      # removed/added pair. Diffy itself rejects that pseudo-chunk before
      # grouping, so it still word-diffs this pair - our counter must too, or
      # it could under-count and let more forks through than budgeted.
      previous_val = "same1\nline2_a" # no trailing newline
      current_val = "same1\nline2_b\n"

      result = helper.version_diff_field_html(previous_val, current_val)

      expect(result[:left]).to include('<strong>a</strong>')
      expect(result[:right]).to include('<strong>b</strong>')
    end

    it 'bounds total word-highlight forks across a whole rendered panel, not just per field' do
      # Several fields, each just under the per-field cap, would otherwise each
      # independently qualify for word-highlighting - multiplying subprocess
      # forks across the whole versions panel. Once the cumulative per-panel
      # budget is spent, later fields must fall back even though each is
      # individually within the per-field cap.
      pairs_per_field = CommonTemplatesHelper::MAX_WORD_HIGHLIGHT_CHUNKS_PER_FIELD - 5
      fields = (CommonTemplatesHelper::MAX_WORD_HIGHLIGHT_CHUNKS_PER_PANEL / pairs_per_field) + 2

      build_val = lambda do |suffix|
        (1..(pairs_per_field * 2)).map { |i| i.even? ? "line#{i}_#{suffix}" : "same#{i}" }.join("\n")
      end

      results = Array.new(fields) { helper.version_diff_field_html(build_val.call('a'), build_val.call('b')) }

      expect(results.first[:left]).to include('<strong>')
      expect(results.last[:left]).not_to include('<strong>')
    end
  end

  describe '#format_version_timestamp' do
    # The "Version Change" heading always showed "Unknown → Unknown": the raw
    # history rows returned by Dynamic::VersionHandler#all_versions_query come
    # from ActiveRecord::Base.connection.execute, which type-casts timestamp
    # columns to real Time objects - but the view called `Time.parse(value)`,
    # which requires a String and always raised TypeError (silently rescued to
    # 'Unknown'). This helper accepts either a Time-like object or a String.
    it 'formats a real Time object directly, without calling Time.parse on it' do
      time = Time.new(2024, 3, 5, 14, 30, 0)

      expect(helper.format_version_timestamp(time)).to eq('2024-03-05 14:30:00')
    end

    it 'formats a timestamp string' do
      expect(helper.format_version_timestamp('2024-03-05 14:30:00 UTC')).to eq('2024-03-05 14:30:00')
    end

    it 'returns "Unknown" for a nil value' do
      expect(helper.format_version_timestamp(nil)).to eq('Unknown')
    end

    it 'returns "Unknown" for an unparseable string' do
      expect(helper.format_version_timestamp('not a timestamp')).to eq('Unknown')
    end
  end
end
