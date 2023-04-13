# Using Poppler Utils `sudo apt-get install poppler-utils`
# Also install libreoffice
#    libreoffice --headless --convert-to html '~/Downloads/mr_scans_full.xlsx'

module SecureView
  #
  # Handle generation of HTML to preview documents
  class HtmlPreviewer < BasePreviewer
    def self.file_type
      :html
    end

    def initialize(options = {})
      super(**options)
      office_docs_to :html unless html?
    end

    # Return the page preview as HTML format file
    def preview(_page)
      File.open(path) do |output|
        res = { io: output, type: :html, filename: "#{output.path}.html", disposition: 'inline' }
        yield res
      end
    end

    # Get the page count for the HTML
    # @return [Integer | nil] the page count or nil if the info returns no page count information
    def page_count
      1
    end
  end
end
