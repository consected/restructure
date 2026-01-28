# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_eval, :strict_dynamic
    policy.style_src   :self, :https, :unsafe_inline
    # Explicit CSP Level 3 directives for inline styles on elements
    policy.style_src_attr  :unsafe_inline
    policy.style_src_elem  :self, :https, :unsafe_inline
    # Script elements require nonces with strict-dynamic to allow AJAX-loaded scripts
    policy.script_src_elem :self, :https, :strict_dynamic
    # Specify URI for violation reports
    policy.report_uri '/csp-violation-report-endpoint'
  end

  # Generate session nonces for permitted importmap and inline scripts
  config.content_security_policy_nonce_generator = lambda { |_request|
    SecureRandom.base64(16)
  }
  config.content_security_policy_nonce_directives = %w[script-src script-src-elem]

  # Report violations without enforcing the policy.
  # Set to false to enforce CSP and block violations
  config.content_security_policy_report_only = false
end
