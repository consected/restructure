# frozen_string_literal: true

# Devise failure app for the :user scope. Adds a distinguishing response header when the failed
# request carried API user_email/user_token credentials (as params or X-User-* headers), so API
# clients can tell "reached the API authenticator, but the credentials were wrong" apart from an
# ordinary unauthenticated browser request.
class ApiAwareFailureApp < Devise::FailureApp
  def respond
    headers['X-ReStructure-Error'] = 'api-token-authentication-failed' if api_token_authentication_attempted?
    super
  end

  private

  def api_token_authentication_attempted?
    ApiTokenHeaderAuth.api_token_authentication_present?(request)
  end
end
