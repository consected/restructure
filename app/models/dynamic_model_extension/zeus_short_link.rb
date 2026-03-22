module DynamicModelExtension
  module ZeusShortLink
    extend ActiveSupport::Concern

    class_methods do
      def extension_setup
        include AwsApi::S3Handler

        define_method :current_user= do |user|
          self.user
        end

        define_method :no_track do
          true
        end
      end

      # Generate HTML document to provide a script redirection to the target URL
      # @param target_url [String]
      # @return [String]
      def generate_html(target_url)
        target_url = target_url.gsub('"', '\\"')

        <<~EOF
          <html>
          <head>
          <link rel="icon" href="data:,">
          <style> body {font-family: sans-serif; font-size: 16px; text-align: center;} h3 { margin-top: 30vh;}</style>
          </head>
          <body>
          <h3>Taking you to the requested page.</h3></p>If not redirected in 10 seconds, click the link to go to</p><p><a href="#{target_url}">#{target_url}</a></p>
          <script>window.location.href="#{target_url}";</script>
          </body>
          </html>
        EOF
      end

      # Generate a shortcode as a Base64 encoded string that is safe for URLs.
      # @param length [Integer] number of bytes for the random generator. The actual returned length is approx. 4/3 this (usually 8 by default)
      # @return [String]
      def generate_shortcode(length = 6)
        re = true
        while re
          res = SecureRandom.urlsafe_base64(length)
          re = false if where(shortcode: res).length == 0
        end

        res
      end

      # Ensure our url and shortcode fields are not downcased
      # @return [Array]
      def no_downcase_attributes
        %i[url shortcode]
      end

      def update_click_count(shortcode, clicks, master)
        sl = where(shortcode:).first
        unless sl
          logger.warn "Failed to find short link for shortcode: #{shortcode}"
          return
        end

        sl.clicks = sl.clicks + clicks
        sl.master.current_user ||= master&.current_user
        sl.force_save!
        sl.save!
      end
    end

    # Create a functional short link
    # @param target_url [String] full URL to redirect to
    # @param user: [User] optional User to apply as the current user, unless master.current_user is set
    # @param master: [Master] optional Master to link the record back to
    # @param link_domain: [String|nil] optional link_domain (requires an existing bucket of the same name in S3).
    # => If excluded, Settings::DefaultShortLinkS3Bucket will be used instead
    # @return [Type] description_of_returned_object
    def create_link(target_url, user: nil, master: nil, link_domain: nil, batch_user: nil, for_item: nil)
      batch_user = User.use_batch_user(Settings.bulk_msg_app) if batch_user && Settings.bulk_msg_app

      unless batch_user || master&.current_user || user
        raise "Either master (with current user) or user must be set to create link (master: #{master} | user: #{user})"
      end

      link_domain ||= Settings::DefaultShortLinkS3Bucket

      h = self.class.generate_html(target_url)
      raise 'Failed to generate redirection document for shortlink' if h.blank?

      sc = self.class.generate_shortcode(Settings::ShortcodeLength)
      raise 'Failed to create a shortcode' unless sc.length >= Settings::ShortcodeLength

      s3m = {
        content_type: 'text/html',
        metadata: {
          'Content-Type' => 'text/html'
        }
      }

      obj = s3_upload_file(sc, h, to_bucket: link_domain, options: s3m)
      raise 'Failed to push the redirection document to S3' unless obj.etag

      if master
        if batch_user
          master.current_user = batch_user
        else
          master.current_user ||= user
        end
      end

      new_attrs = {
        url: target_url,
        shortcode: sc,
        domain: link_domain
      }

      if master
        new_attrs[:master] = master
      else
        new_attrs[:current_user] = batch_user || user
      end

      if for_item
        new_attrs[:for_item_type] = for_item.class.name.ns_underscore
        new_attrs[:for_item_id] = for_item.id
      end

      self.no_track = true
      res = self.class.new(new_attrs)
      res.force_save! if batch_user
      res.save
      raise 'Failed to create a record of the shortcode' unless res

      {
        html: h,
        shortcode: sc,
        short_link_instance: res,
        link_domain:
      }
    end

    # Check if the shortcode redirection file exists on S3 for the specified (or default) link_domain
    # @return [Boolean]
    def redirect_file_exists?(shortcode, link_domain = nil)
      link_domain ||= Settings::DefaultShortLinkS3Bucket
      s3_file_exists? shortcode, bucket: link_domain
    end

    # Format as the short URL
    # @return [String]
    def short_url
      "http://#{domain}/#{shortcode}"
    end
  end
end
