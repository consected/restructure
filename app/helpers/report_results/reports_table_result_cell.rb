# frozen_string_literal: true

module ReportResults
  #
  # A non-helper class to support ReportsTableHelper, without
  # polluting the global namespace
  class ReportsTableResultCell < ReportsCommonResultCell
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
        'url' => 'div',
        'tags' => 'div',
        'choice_label' => 'div',
        'iframe' => 'div'
      }

      return col_show_as unless mapping.key? col_show_as

      mapping[col_show_as]
    end
  end
end
