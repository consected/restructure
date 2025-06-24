require 'mime/types'

module NfsStore
  module Utils
    class MimeType
      def self.full_mime_type(full_file_path)
        ext = File.extname(full_file_path)
        mt = MIME::Types.type_for(ext)&.first
        mime = mt || ext
        # brakeman --> command injection ignored here
        # mitigated by preventing the command running if the full_file_path contains a single quote (') character
        mime = `file --mime-type -b '#{full_file_path}'`.strip if mime.blank? && !full_file_path.include?("'")
        if mime.is_a? String
          MIME::Types[mime]&.first
        else
          mime
        end
      end

      #
      # Compare the #mime_type against the specified String content_type.
      # Handles the Columnar subtype that MIME::Type introduced at some point, breaking comparisons    
      # @param [String|MIME::Type|MIME::Type::Columnar] content_type
      # @return [true|false]
      def self.is?(mime_type, content_type)
        content_type = content_type.content_type if content_type.respond_to?(:content_type)

        case mime_type
        when MIME::Type::Columnar
          mime_type == MIME::Types[content_type].first
        when MIME::Type
          mime_type == MIME::Type.new(content_type)
        end
      end
    end
  end
end
