# Using Poppler Utils `sudo apt-get install poppler-utils`
# Also install libreoffice
#    libreoffice --headless --convert-to html '/home/phil/Downloads/mr_scans_full.xlsx'

module SecureView
  class HTMLPreviewer < Previewer

    def self.file_type
      :html
    end

    def initialize options={}
      super
      office_docs_to :html unless html?
    end

    # Return the page preview as a PNG format file
    def preview page
      File.open(self.path) do |output|
          res =  {io: output, type: :html, filename: "#{output.path}.html", disposition: 'inline'}
          yield res
      end
    end

    # Get the page count for the HTML
    # @return [Integer | nil] the page count or nil if the info returns no page count information
    def page_count
      1
    end


    private


  end
end
