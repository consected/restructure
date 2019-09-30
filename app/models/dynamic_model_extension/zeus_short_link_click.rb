module DynamicModelExtension
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

        define_method :current_user= do |user|
          self.user
        end

        define_method :no_track do
          true
        end
      end

      def latest_log
        Rails.cache.fetch("ZeusShortLinkClick.latest_log") do
          DynamicModel::ZeusShortLinkClick.last&.logfile
        end
      end

      def latest_log= k
        Rails.cache.write("ZeusShortLinkClick.latest_log", k)
      end

    end

    # A valid log entry looks like this:
    # 8e134f3964d1864709f668f9d3e8db57ca701a10a74bb930fb6f6c31d0ebf450 test-shortlink.fphs.link [25/Sep/2019:16:28:46 +0000] 2.101.87.48 - AFA99DF2F2A45D3F WEBSITE.GET.OBJECT 3TWTNGJW "GET /3TWTNGJW HTTP/1.1" 200 - 512 512 33 32 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36" - +ryACrzswwMga0Y9AAtj6hYEzzuctfJ0PZtCRKcDrDBwbIw09YncHBeVoGnDszx86ZmGPERsX7U= - - - test-shortlink.fphs.link -

    def get_logs

      batch_user = User.use_batch_user(Settings.bulk_msg_app) if Settings.bulk_msg_app
      m = Settings.bulk_msg_master
      m.current_user = batch_user

      bucket = Settings::DefaultShortLinkLogS3Bucket
      domain = Settings::DefaultShortLinkS3Bucket
      ll = self.class.latest_log

      logger.info "Latest log recorded: #{ll}"

      list = s3_list bucket: bucket, prefix: Settings::LogBucketPrefix, start_after: ll

      ks = list.map(&:key)

      # Set an arbitraty date in the past used to ensure timestamps we get are sensible
      limittime = DateTime.now - 5.years
      limittimefuture = DateTime.now + 30.minutes

      logger.info "Keys to retrieve: #{ks.length}"
      results = []

      # Handle each log file in turn
      ks.each do |k|
        logger.info "Getting key #{k} from bucket #{bucket}"
        d = s3_file_get_all(k, bucket: bucket)
        hits = d.scan(/[^|\n]+\s([^\s]+)\s\[([^\]]+)\]\s.+\sWEBSITE.GET.OBJECT\s([a-zA-Z0-9\-_\.]+)\s"[^"]+"\s[^"]+"[^"]"\s"(.+)"\s.+[\n|$]/)
        logger.info "Got #{hits.length} hits"

        hits.each do |hit|
          res = false
          ds = DateTime.strptime(hit[1], "%d/%b/%Y:%H:%M:%S %z")
          shortcode= hit[2]
          Rails.logger.info "Got hit, but the domain did not match: #{hit[0]}" if hit[0] != domain
          Rails.logger.info "Got hit, but the browser was empty: #{hit[3]}" if hit[3].blank?

          raise FphsException.new "Failed to get valid short link click: #{hit}" unless hit[0].present? && ds > limittime && ds < limittimefuture && shortcode.present?

          c = self.class.new(
            domain: hit[0],
            action_timestamp: ds,
            shortcode: shortcode,
            browser: hit[3],
            logfile: k,
            master: m
          )

          begin
            c.force_save!
            c.save!

            DynamicModel::ZeusShortLink.update_click_count shortcode, 1, m
            res = true
          rescue => e
            logger.warn "Failed to update clicks for shortcode: #{c}. #{e}"
          end

          if res
            results << c
          else
            logger.warn "Failed to save the click log: #{c.errors}"
          end
        end

      end

      if ks.length > 0
        self.class.latest_log = ks.last
      end

      results
    end


  end
end
