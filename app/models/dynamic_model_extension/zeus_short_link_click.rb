module DynamicModelExtension
  #
  # Dynamic Model extension to the zeus_short_link_clicks Dynamic Model.
  # This model records each short link click, by retrieving it from S3,
  # in a bucket that the short.link domain writes access logs to.
  # The logfile that a click is retrieved from is recorded in the *logfile* field
  # and is used to indicate to S3 the starting point to retrieve logs from, so that
  # we limit the number of logs to be retrieved.
  # Inside each file we then scan the content for a WEBSITE.GET.OBJECT string
  # and use a RegEx to get the appropriate data to record in the click record.
  module ZeusShortLinkClick
    extend ActiveSupport::Concern

    included do
      validates :domain, presence: true
      validates :shortcode, presence: true
      validates :action_timestamp, presence: true
      validates :logfile, presence: true
    end

    class_methods do
      def extension_setup
        include AwsApi::S3Handler

        define_method :current_user= do |_user|
          user
        end

        define_method :no_track do
          true
        end
      end

      #
      # Get the latest logfile name we have retrieved from S3
      def latest_log
        DynamicModel::ZeusShortLinkClick.reorder('').last&.logfile
      end

      def no_downcase_attributes
        %i[shortcode]
      end
    end

    # A valid log entry looks like this:
    # 8e134f3964d1864709f668f9d3e8db57ca701a10a74bb930fb6f6c31d0ebf450 test-shortlink.link [25/Sep/2019:16:28:46 +0000] 2.101.87.48 - AFA99DF2F2A45D3F WEBSITE.GET.OBJECT 3TWTNGJW "GET /3TWTNGJW HTTP/1.1" 200 - 512 512 33 32 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36" - +ryACrzswwMga0Y9AAtj6hYEzzuctfJ0PZtCRKcDrDBwbIw09YncHBeVoGnDszx86ZmGPERsX7U= - - - test-shortlink.link -

    #
    # Get the click logs from S3
    # Record the latest log retrieved in
    # @param [String] from_prefix_date - force a prefix date (e.g. '2021-02-01') to use, rather than the cached value
    # @return [Array] - an array of click results
    def get_logs(from_prefix_date: nil)
      batch_user = User.use_batch_user(Settings.bulk_msg_app) if Settings.bulk_msg_app
      m = Settings.bulk_msg_master
      m.current_user = batch_user

      bucket = Settings::DefaultShortLinkLogS3Bucket
      domain = Settings::DefaultShortLinkS3Bucket
      ll = from_prefix_date || self.class.latest_log

      logger.info "Latest log recorded: #{ll}"

      list = s3_list bucket: bucket, prefix: Settings::LogBucketPrefix, start_after: ll

      ks = list.map(&:key)

      # Set an arbitrary date in the past used to ensure timestamps we get are sensible
      limittime = DateTime.now - 5.years
      limittimefuture = DateTime.now + 30.minutes

      logger.info "Keys to retrieve: #{ks.length}"
      results = []

      # Handle each log file in turn
      ks.each do |k|
        logger.info "Getting key #{k} from bucket #{bucket}"
        d = s3_file_get_all(k, bucket: bucket)
        hits = d.scan(/[^|\n]+\s([^\s]+)\s\[([^\]]+)\]\s.+\sWEBSITE.GET.OBJECT\s([a-zA-Z0-9\-_.]+)\s"[^"]+"\s[^"]+"[^"]"\s"(.+)"\s.+[\n|$]/)
        logger.info "Got #{hits.length} hits. Some may be junk."

        hits.each do |hit|
          res = false
          ds = DateTime.strptime(hit[1], '%d/%b/%Y:%H:%M:%S %z')
          shortcode = hit[2]

          next if shortcode.include? '.'

          Rails.logger.info "Got hit, but the domain did not match: #{hit[0]}" if hit[0] != domain
          Rails.logger.info "Got hit, but the browser was empty: #{hit[3]}" if hit[3].blank?

          unless hit[0].present? && ds > limittime && ds < limittimefuture && shortcode.present?
            raise FphsException, "Failed to get valid short link click: #{hit}"
          end

          c = self.class.new(
            domain: hit[0],
            action_timestamp: ds,
            shortcode: shortcode,
            browser: hit[3],
            logfile: k,
            master: m
          )

          begin
            transaction do
              c.force_save!
              c.save!

              DynamicModel::ZeusShortLink.update_click_count shortcode, 1, m
            end
            res = true
          rescue StandardError => e
            logger.warn "Failed to update clicks for shortcode: #{c}. #{e}"
          end

          if res
            results << c
          else
            logger.warn "Failed to save the click log: #{c.errors}"
          end
        end
      end

      results
    end
  end
end
