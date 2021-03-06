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
    end
  end
end
