# frozen_string_literal: true

module CommonTemplatesHelper
  def handle_set_related_field(object_instance, field_name)
    object_instance.set_related_fields[field_name] if object_instance.respond_to?(:set_related_fields)
  end

  def zip_field_props(init = {})
    init.merge({ pattern: '\\d{5,5}(-\\d{4,4})?' })
  end

  #
  # Field options for the field, from the dynamic configuration.
  # Use reset: true to clear the memo, which speeds up some large forms
  # @return [Hash]
  def field_options_for(form_object_instance, field_name_sym, reset: nil)
    @field_options_for = nil if reset
    return @field_options_for if @field_options_for

    if form_object_instance.respond_to?(:option_type_config) && form_object_instance.option_type_config
      fopt = form_object_instance.option_type_config.field_options[field_name_sym].dup
    end

    fopt ||= {}

    if fopt[:value] || fopt[:blank_value]
      fres = form_object_instance.attributes[field_name_sym.to_s]
      if fres.blank?
        fres = if form_object_instance.persisted?
                 fopt[:blank_value]
               else
                 fopt[:value]
               end
        fres = FieldDefaults.calculate_default form_object_instance, fres
      end

      fopt[:selected] = fres
      fopt[:value] = fres
    end

    @field_options_for = fopt
  end

  def general_selection_prefix_name(form_object_instance)
    Classification::GeneralSelection.prefix_name form_object_instance
  end

  def general_selection_source_name(form_object_instance)
    "#{general_selection_prefix_name(form_object_instance)}_source"
  end

  def class_for_open_panels(resource, default_panels_length)
    "{{# is (split_lines open_panels) 'includes' '#{resource}'}}on-open-click initial_show_value-true-{{else}}initial_show_value-false-{{/is}}#{default_panels_length}".html_safe
  end

  def def_uac_summary_data(object_instance:, current_user:, current_app_type_id:, resource_name: nil, resource_type: 'table')
    resource_name = resource_name || object_instance.resource_name&.pluralize
    return { resource_name:, resource_type:, uacs: [], no_non_template_uacs: true, current_user_has_access: false, current_app_uacs: [] } if resource_name.blank?

    uacs = Admin::UserAccessControl.active_for(resource_name:).not_template_role
    no_non_template_uacs = uacs.empty?

    current_user_has_access = false
    if current_user && current_app_type_id
      current_user_has_access = Admin::UserAccessControl.access_for?(
        current_user,
        :access,
        resource_type.to_sym,
        resource_name,
        alt_app_type_id: current_app_type_id
      ).present?
    end

    current_app_uacs = uacs.select { |uac| uac.app_type_id == current_app_type_id }

    {
      resource_name:,
      resource_type:,
      uacs:,
      no_non_template_uacs:,
      current_user_has_access:,
      current_app_uacs:
    }
  end

  def def_uac_needs_attention?(object_instance:, current_user:, current_app_type_id:, resource_name: nil, resource_type: 'table')
    uac_data = def_uac_summary_data(
      object_instance:,
      current_user:,
      current_app_type_id:,
      resource_name:,
      resource_type:
    )

    uac_data[:no_non_template_uacs] ||
      (current_app_type_id.present? && !uac_data[:current_user_has_access]) ||
      (current_app_type_id.present? && uac_data[:current_app_uacs].empty?)
  end

  #
  # Format a version history row's created_at/updated_at value for display in
  # the "Version Change" heading. Values from Dynamic::VersionHandler's raw SQL
  # history rows come back as real Time objects (not Strings), so calling
  # `Time.parse` directly on them always raised TypeError - silently shown as
  # "Unknown" for every version. Accepts either a Time-like object or a String.
  # @param value [Time, ActiveSupport::TimeWithZone, String, nil]
  # @return [String]
  def format_version_timestamp(value)
    return 'Unknown' if value.blank?

    time = value.respond_to?(:strftime) ? value : Time.parse(value.to_s)
    time.strftime('%Y-%m-%d %H:%M:%S')
  rescue StandardError
    'Unknown'
  end

  # Above this many separate del/ins chunk-pairs in a SINGLE field's diff, skip
  # Diffy's word-level highlighting for that field. Diffy forks a small extra
  # `diff` process PER changed chunk-pair to compute character-level
  # highlighting - a field with many scattered small edits (e.g. a
  # heavily-reordered options YAML) can have hundreds of these. Note this is
  # NOT the same as the number of `@@` hunk headers - `diff -U` context merges
  # nearby scattered changes into one hunk while still containing many
  # separate del/ins runs internally, so hunk count alone would under-count
  # this risk. Falls back to whole-line (still correct, just not
  # word-highlighted) diffing for such fields.
  MAX_WORD_HIGHLIGHT_CHUNKS_PER_FIELD = 40

  # Total del/ins chunk-pairs that may be word-highlighted across an entire
  # rendered versions panel (summed across every changed field, in every
  # displayed version-pair). The per-field cap above bounds a single field, but
  # a panel with many changed fields (or many displayed version-pairs) each
  # just under that cap could still multiply subprocess forks across the whole
  # request - this bounds the total. See issue #1343.
  MAX_WORD_HIGHLIGHT_CHUNKS_PER_PANEL = 400

  #
  # Render a previous/current value pair as split (left/right) diff HTML for the
  # admin definition versions panel, with word-level highlighting of changes
  # within a line. Uses a single top-level Diffy::Diff instance (the underlying
  # `diff` binary call is memoized on that instance, and reused for both the
  # chunk-header text and the HTML rendering) instead of the previous separate
  # raw-diff call plus Diffy::SplitDiff, which forked the `diff` binary for the
  # whole field TWICE. Diffy's own word-level highlighting still forks a small
  # diff per changed line internally - that cost is proportional to the actual
  # number of changed lines, not to field size, and is required to highlight
  # only the changed words. See issue #1343 - the admin versions panel was slow
  # even with a modest number of versions because of the duplicate whole-field
  # subprocess forks.
  # @param previous_val [String]
  # @param current_val [String]
  # @param show_line_numbers [Boolean] annotate each line with its source line number
  # @return [Hash] { left: String, right: String }
  def version_diff_field_html(previous_val, current_val, show_line_numbers: false)
    diff = Diffy::Diff.new(previous_val, current_val, context: 2, include_diff_info: true)

    chunk_info = parse_diff_chunk_info(diff.to_s(:text))
    format = word_highlight_allowed?(word_highlight_chunk_pairs(diff)) ? :html : :html_simple

    html = strip_diff_info_lines(diff.to_s(format))
    left_html = html.gsub(%r{\s*<li class="ins"><ins>.*?</ins></li>}, '')
    right_html = html.gsub(%r{\s*<li class="del"><del>.*?</del></li>}, '')

    if show_line_numbers && chunk_info.present?
      left_html = add_diff_line_numbers(left_html, chunk_info, :left)
      right_html = add_diff_line_numbers(right_html, chunk_info, :right)
    end

    { left: left_html, right: right_html }
  end

  private

  # True if word-highlighting `pairs` more chunk-pairs stays within both the
  # per-field cap and the remaining per-panel budget. Consumes from the budget
  # (an instance variable, so it accumulates across every field rendered
  # within the same view/partial-rendering pass, i.e. one versions panel load).
  def word_highlight_allowed?(pairs)
    return false if pairs > MAX_WORD_HIGHLIGHT_CHUNKS_PER_FIELD

    @word_highlight_fork_budget ||= MAX_WORD_HIGHLIGHT_CHUNKS_PER_PANEL
    return false if pairs > @word_highlight_fork_budget

    @word_highlight_fork_budget -= pairs
    true
  end

  # Count adjacent (removed-run, added-run) chunk pairs the same way
  # Diffy::HtmlFormatter#highlighted_words groups them internally, since that's
  # what drives one extra Diffy::Diff fork each:
  # - reject the synthetic "\ No newline at end of file" chunk first, exactly
  #   as Diffy does, so it can't split apart a real adjacent del/ins pair
  # - skip the leading `---`/`+++` file-header pair (with include_diff_info:
  #   true, both chunks start with '-'/'+' respectively but Diffy never forks
  #   for it)
  # Cheap: just iterates the already computed/memoized diff lines, no extra
  # subprocess forks.
  def word_highlight_chunk_pairs(diff)
    chunks = diff.each_chunk.reject { |c| c == "\\ No newline at end of file\n" }
    pairs = 0
    chunks.each_cons(2) do |c1, c2|
      next unless c1.start_with?('-') && c2.start_with?('+')
      next if diff_header_chunk?(c1) && diff_header_chunk?(c2)

      pairs += 1
    end
    pairs
  end

  # True if a chunk is the `---`/`+++` file-header line Diffy itself skips
  # when deciding whether to word-highlight a del/ins pair.
  def diff_header_chunk?(chunk)
    chunk[0, 3].match?(/^(---|\+\+\+)/)
  end

  # Remove the diff header/context (---, +++) and chunk (@@) list items that
  # `include_diff_info: true` adds - these are only needed to parse line numbers,
  # not for the rendered output.
  def strip_diff_info_lines(html)
    html.gsub(%r{\s*<li class="diff-comment">.*?</li>}, '')
        .gsub(%r{\s*<li class="diff-block-info">.*?</li>}, '')
  end

  # Parse `@@ -left_start,left_count +right_start,right_count @@` chunk headers
  # from a raw (text format) Diffy diff into a list of line-number ranges.
  def parse_diff_chunk_info(raw_diff_text)
    chunk_info = []
    raw_diff_text.scan(/@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/) do |match|
      chunk_info << {
        left_start: match[0].to_i,
        left_count: (match[1] || '1').to_i,
        right_start: match[2].to_i,
        right_count: (match[3] || '1').to_i
      }
    end
    chunk_info
  end

  # Annotate each del/ins/unchanged list item with a `.line-number` span,
  # tracking position across chunk boundaries.
  def add_diff_line_numbers(html, chunk_info, side)
    return html if chunk_info.blank?

    chunk_idx = 0
    current_chunk = chunk_info[chunk_idx]
    line_num = side == :left ? current_chunk[:left_start] : current_chunk[:right_start]
    lines_in_chunk = 0
    max_lines = side == :left ? current_chunk[:left_count] : current_chunk[:right_count]

    html.gsub(/<li class="(del|ins|unchanged)">(<del>|<ins>|<span>)/) do
      line_class = Regexp.last_match(1)
      tag_start = Regexp.last_match(2)

      if lines_in_chunk >= max_lines && chunk_idx + 1 < chunk_info.length
        chunk_idx += 1
        current_chunk = chunk_info[chunk_idx]
        line_num = side == :left ? current_chunk[:left_start] : current_chunk[:right_start]
        lines_in_chunk = 0
        max_lines = side == :left ? current_chunk[:left_count] : current_chunk[:right_count]
      end

      result = "<li class=\"#{line_class}\"><span class=\"line-number\">#{line_num}</span>#{tag_start}"

      should_increment = side == :left ? (line_class != 'ins') : (line_class != 'del')
      if should_increment
        line_num += 1
        lines_in_chunk += 1
      end

      result
    end
  end
end
