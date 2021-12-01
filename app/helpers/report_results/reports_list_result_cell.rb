# frozen_string_literal: true

module ReportResults
  #
  # A non-helper class to support ReportsListHelper, without
  # polluting the global namespace
  class ReportsListResultCell < ReportsCommonResultCell
    #
    # Alter the cell tag based on configurations
    def html_tag
      new_col_tag = col_tag || 'pre' if content_lines >= 1
      return new_col_tag if col_show_as.blank?

      mapping = {
        'div' => 'div',
        'fixed-pre' => 'pre',
        'checkbox' => 'div',
        'options' => 'div',
        'list' => 'ul',
        'url' => nil,
        'tags' => nil,
        'choice_label' => nil
      }

      return col_show_as unless mapping.key? col_show_as

      mapping[col_show_as]
    end
  end
end