# frozen_string_literal: true

module Utilities
  class ReCaptcha
    SiteVerifyUrl = 'https://www.google.com/recaptcha/api/siteverify'
    NoSettingMinScore = 0.5

    attr_accessor :response

    def initialize(response: nil)
      @response = response
    end

    def success?
      res = api_verify
      return unless res.is_a? Hash

      res['success'] && passing_score?(res['score'])
    end

    #
    # Verify the recaptcha response sent from the user challenge form submission
    # https://developers.google.com/recaptcha/docs/verify
    # Returns
    # {
    #   "success": true|false,
    #   "challenge_ts": timestamp,  // timestamp of the challenge load (ISO format yyyy-MM-dd'T'HH:mm:ssZZ)
    #   "hostname": string,         // the hostname of the site where the reCAPTCHA was solved
    #   "error-codes": [...]        // optional
    # }
    # @return [Hash] <description>
    def api_verify
      data = {
        secret: Settings::ReCaptchaSecret,
        response:
      }
      data = URI.encode_www_form(data)
      httpres = Net::HTTP.post(site_verify_parsed_url, data)
      res = httpres.body if httpres
      res = JSON.parse(res) if res
      Rails.logger.info "reCAPTCHA result: #{res}"
      res
    end

    private

    def site_verify_parsed_url
      return @site_verify_parsed_url if @site_verify_parsed_url

      @recaptcha_parssite_verify_parsed_urled_url = URI.parse(SiteVerifyUrl)
    end

    def passing_score?(score)
      res = score >= passing_score
      return true if res

      Rails.logger.warn "reCAPTCHA didn't get a passing score: #{score} < #{passing_score}"
      false
    end

    def passing_score
      @passing_score ||= Settings::ReCaptchaMinScore.presence || NoSettingMinScore
    end
  end
end
