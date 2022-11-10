# frozen_string_literal: true

module ReportResults
  #
  # A non-helper class to superclass for Report*ResultCell to inherit from,
  # and to support report helpers without polluting the global namespace
  class ReportsCommonResultCell
    attr_accessor :cell_content, :col_tag, :col_show_as, :col_name, :table_name, :selection_options

    def initialize(table_name, cell_content, col_name, col_tag, col_show_as, selection_options)
      self.cell_content = cell_content
      self.col_name = col_name
      self.col_tag = col_tag
      self.col_show_as = col_show_as
      self.table_name = table_name
      self.selection_options = selection_options
    end

    #
    # Alter the cell tag based on configurations
    def html_tag
      if col_show_as.blank?
        new_col_tag = col_tag
        new_col_tag = 'pre' if !new_col_tag && content_lines >= 1
        return new_col_tag
      end

      mapping = {
        'div' => 'div',
        'fixed-pre' => 'pre',
        'checkbox' => 'div',
        'options' => 'div',
        'list' => 'ul',
        'tags' => 'div',
        'choice_label' => 'div',
        'iframe' => 'div'
      }

      return col_show_as unless mapping.key? col_show_as

      mapping[col_show_as]
    end

    #
    # Update the cell content based on the original type
    # Will return an html_safe string, since additional html tags may be included.
    # The original content will be appropriately escaped
    def view_content
      content_method = "cell_content_for_#{col_show_as}"
      if respond_to? content_method
        send(content_method)
      elsif cell_content.is_a?(Hash)
        html_escape cell_content.to_json
      else
        html_escape cell_content
      end
    end

    def html_escape(str)
      ERB::Util.html_escape str
    end

    #
    # For "pre" strings with more than 4 lines, set the class as expandable,
    # unless the configuration states it should be a *fixed-pre*
    def expandable?
      lines = content_lines
      new_col_tag = col_tag || 'pre' if lines >= 1
      res = true if new_col_tag == 'pre' && lines > 4
      res = nil if col_show_as == 'fixed-pre'
      res
    end

    #
    # Count number of lines in the content if it is a String
    def content_lines
      l = cell_content&.scan("\n")&.length if cell_content.is_a?(String)
      l || 0
    end

    def model_object
      @model_object ||= {}
      return @model_object[table_name] if @model_object.key? table_name

      @model_object[table_name] = UserBase.class_from_table_name(table_name)&.new
    end

    #####
    # Cell content rendering for different types of original content
    #####

    def cell_content_for_checkbox
      cb = case cell_content
           when nil
             '<span class="report-val-not-answered"></span>'
           when true
             '<span class="glyphicon glyphicon-check report-val-checked"></span>'
           when 1
             '<span class="glyphicon glyphicon-check report-val-checked"></span>'
           when false
             '<span class="glyphicon glyphicon-unchecked report-val-unchecked"></span>'
           when 0
             '<span class="glyphicon glyphicon-unchecked report-val-unchecked"></span>'
           else
             '<span class="report-val-not-answered"></span>'
           end

      html = <<~END_HTML
        <div class="report-cb-inner">#{cb}</div>
      END_HTML

      html.html_safe
    end

    #
    # We expect options to be a Hash or an Array (of [key, value] arrays)
    # but if it is a String we'll assume it is JSON
    def cell_content_for_options
      return unless cell_content.present?

      opts = cell_content
      opts = JSON.parse(cell_content) if cell_content.is_a? String

      opts = case opts
             when Hash
               opts.to_a
             when Array
               opts
             end

      return cell_content unless opts

      opts.map do |citem|
        <<~END_HTML
          <div class="report-option-items"><div>
            <strong>#{html_escape citem.first}</strong>&nbsp;<span>#{html_escape citem.last}</span>
          </div></div>
        END_HTML
      end.join('').html_safe
    end

    #
    # Display a list (array) of either individual values or hashes
    # We expect options to be an Array, but if it is a String we'll assume it is JSON
    def cell_content_for_list
      return unless cell_content.present?

      list = cell_content
      list = JSON.parse(cell_content) if cell_content.is_a? String

      return cell_content unless list.is_a? Array

      list.map do |citem|
        el = if citem.is_a? Hash
               inner_content_hash citem
             else
               html_escape citem
             end
        <<~END_HTML
          <li class="report-list-items">#{el}</li>
        END_HTML
      end.join('').html_safe
    end

    #
    # Show the result as a link to be opened link to be opened in a new tab.
    # The content should be formatted using Markdown format
    #     [label for link](/url/path)
    def cell_content_for_url
      return cell_content unless cell_content.present?

      col_url_parts = cell_content&.scan(/^\[(.+)\]\((.+)\)$/)
      html = <<~END_HTML
        <a href="#{col_url_parts&.first&.last}" target="_blank">#{html_escape col_url_parts&.first&.first}</a>
      END_HTML

      html.html_safe
    end

    def cell_content_for_embedded_block
      return cell_content unless cell_content.present?

      url = cell_content

      if url.start_with? '['
        # This is a markdown format link
        col_url_parts = url&.scan(/^\[(.+)\]\((.+)\)$/)
        a_text = html_escape col_url_parts&.first&.first
        url = html_escape col_url_parts&.first&.last
      else
        # This is a plain URL
        icon = 'glyphicon glyphicon-tasks'
      end

      split_url = url.split('/')

      split_url = split_url.reject(&:blank?)
      id = split_url.last
      master_id = split_url[1] if split_url.first == 'masters'
      hyph_name = split_url[-2].hyphenate.singularize

      html = <<~END_HTML
        <a class="report-embedded-block-link #{icon}" title="open result" href="#{url}" data-remote="true" data-#{hyph_name}-id="#{id}" data-result-target="#report-result-embedded-block--#{id}" data-template="#{hyph_name}-result-template" data-result-target-force="true">#{a_text}</a>
        <div id="report-result-embedded-block--#{id}" class="report-temp-embedded-block" data-preprocessor="report_embed_dynamic_block" data-model-name="#{hyph_name.underscore}" data-id="#{id}" data-master-id="#{master_id}"></div>
      END_HTML

      html.html_safe
    end

    def cell_content_for_embedded_report
      return cell_content unless cell_content.present?

      col_url_parts = cell_content&.scan(/^\[(.+)\]\((.+)\)$/)
      url = col_url_parts&.first&.last
      url = if url.include? '?'
              "#{url}&embed=true"
            else
              "#{url}?embed=true"
            end
      html = <<~END_HTML
        <a href="#{url}" data-remote="true" data-preprocessor="embedded_report" data-parent="primary-modal" class="" data-result-target="#modal_results_block" data-target="#modal_results_block" data-target-force="true">#{html_escape col_url_parts&.first&.first}</a>
      END_HTML

      html.html_safe
    end

    #
    # Show the result as a the label from a choice, such as a general selection or the alt_options in a dynamic model
    # @todo Refactor this
    def cell_content_for_choice_label
      return cell_content unless cell_content.present?

      result = selection_options.label_for col_name, cell_content
      if result.nil? && model_object.respond_to?("#{col_name}_options")
        result = model_object.send("#{col_name}_options")
      end

      result
    end

    def cell_content_for_tags
      return cell_content unless cell_content.present?

      result = []
      cell_content.each do |cell_content_item|
        result << selection_options.label_for(col_name, cell_content_item)
      end

      lis = result.reject(&:blank?)
                  .map { |c| "<li class=\"report-result-cell-tags\">#{html_escape c}</li>" }
                  .join("\n")

      html = <<~END_HTML
        <ul class="report-result-cell-tags">
          #{lis}
        </ul>
      END_HTML

      html.html_safe
    end

    def cell_content_for_markdown
      return cell_content unless cell_content.present?

      Kramdown::Document.new(cell_content).to_html.html_safe
    end

    def cell_content_for_iframe
      return cell_content unless cell_content.present?

      block_id = SecureRandom.hex(10)

      html = <<~END_HTML
        <iframe id="report-cell-iframe-#{block_id}" src='javascript:void(0)' srcdoc="" class="iframe-report-cell if-report-cell-type" sandbox="allow-popups allow-popups-to-escape-sandbox"></iframe>
        <script id="report-cell-content-#{block_id}" class="hidden" type="x-html">
          #{cell_content.gsub('<head>', '<head><base target="_blank" />').html_safe}
        </script>
        <script>
          window.setTimeout(function() {
            var c = $('#report-cell-content-#{block_id}');
            var html = c.html();

            $('#report-cell-iframe-#{block_id}').attr('srcdoc', html);
          }, 100);
        </script>
      END_HTML

      html.html_safe
    end

    private

    def inner_content_hash(content)
      return unless content

      html = content.map do |k, v|
        <<~END_HTML
          <li class="report-inner-hash-item">
            <strong>#{html_escape k}</strong>&nbsp;<span>#{html_escape v}</span>
          </li>
        END_HTML
      end

      html = html.join('').html_safe

      html = <<~END_HTML
        <ul class="report-inner-hash">
          #{html}
        </ul>
      END_HTML

      html.html_safe
    end
  end
end
