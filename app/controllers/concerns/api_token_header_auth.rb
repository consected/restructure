# frozen_string_literal: true

module ApiTokenHeaderAuth
  HEADER_KEYS = {
    user_email: %w[HTTP_X_USER_EMAIL X-User-Email X-USER-EMAIL].freeze,
    user_token: %w[HTTP_X_USER_TOKEN X-User-Token X-USER-TOKEN].freeze
  }.freeze

  module_function

  def user_email_from_request(request)
    request.params['user_email'].presence || find_header_value(request, HEADER_KEYS[:user_email])
  end

  def user_token_from_request(request)
    request.params['user_token'].presence || find_header_value(request, HEADER_KEYS[:user_token])
  end

  def api_token_authentication_present?(request)
    user_email_from_request(request).present? || user_token_from_request(request).present?
  end

  def find_header_value(request, candidate_keys)
    candidate_keys.each do |key|
      if request.respond_to?(:headers)
        value = request.headers[key].presence
        return value if value.present?

        normalized_key = key.to_s.downcase.tr('_', '-')
        value = request.headers[normalized_key].presence
        return value if value.present?
      end

      value = request.get_header(key).presence
      return value if value.present?

      normalized_key = key.to_s.tr('_', '-')
      value = request.get_header(normalized_key).presence
      return value if value.present?
    end

    nil
  end
end
