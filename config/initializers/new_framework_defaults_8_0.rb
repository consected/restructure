# Be sure to restart your server when you modify this file.
#
# This file documents Rails 8.0 template additions/defaults that are NOT
# currently enabled in this app, discovered via `bin/rails app:update --pretend`
# during the Rails 8 upgrade audit (issue #1327, refs #1015).
#
# Unlike `config.load_defaults`, most of these are either (a) net-new opt-in
# features with no compatibility risk, or (b) generator/template conveniences
# that don't affect runtime behaviour. None of them are uncommented here -
# each one has been reviewed and a decision recorded below. Revisit this file
# if adopting any of them later.
#
# Read the Rails 8.0 upgrade guide for more info:
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

###
# Adds `lib` to both the Zeitwerk autoload paths and eager-load paths (with the
# given subdirectories ignored), so classes under `lib/` are autoloaded,
# reloaded in development, and eager-loaded in production like `app/*`.
#
# NOT adopted: this app's `lib/` contains `lib/generators/` (Rails generator
# templates, not Zeitwerk-compatible constants) and `lib/tasks/` (rake tasks),
# neither of which follows Zeitwerk naming conventions. Enabling this without
# also correctly listing every non-constant subdirectory in `ignore:` would
# raise `Zeitwerk::NameError` on boot. `lib/secure_view.rb` is currently loaded
# via a plain `require 'secure_view'` in config/initializers/secure_view.rb,
# which continues to work unchanged in Rails 8 (`lib` remains on `$LOAD_PATH`
# regardless of this setting).
#
# Rails.application.config.autoload_lib(ignore: %w[assets tasks generators])

###
# Disables generation of system test files for `bin/rails generate scaffold`
# etc. Generator-only, no runtime effect either way.
#
# Rails.application.config.generators.system_tests = nil

###
# Assumes all access to the app happens through an SSL-terminating reverse
# proxy (skips Rails' own SSL redirect/detection logic, trusting the proxy).
#
# NOT adopted: this app already sets `config.force_ssl = true` and a custom
# `config.action_dispatch.x_sendfile_header` (via FPHS_X_SENDFILE_HEADER) for
# its Nginx/Apache reverse-proxy deployment. Revisit alongside the deploy-repo
# review (issue #1326) if `assume_ssl` would simplify or improve on the
# current proxy configuration.
#
# Rails.application.config.assume_ssl = true

###
# Silences router/log noise for the default Rails 8 `/up` health-check route.
#
# NOT adopted: this app does not define Rails' default `/up` health-check
# route (it predates that convention and likely uses a different health-check
# path/mechanism at the load-balancer level - confirm during issue #1326's
# deploy-repo review before adopting).
#
# Rails.application.config.silence_healthcheck_path = "/up"

###
# The Rails 8 template's default `filter_parameters` list additionally filters
# `:email` (and `:cvv`, `:cvc`) from logs, on top of this app's existing list.
#
# NOT adopted automatically: this app is a research-participant management
# system where email is core, frequently-searched data - filtering it from
# request-parameter logs may hinder legitimate debugging. Left as a deliberate
# product/security decision for a separate follow-up rather than folding it
# into the Rails 8 upgrade. See config/initializers/filter_parameter_logging.rb.

###
# `config.action_dispatch.show_exceptions` gained a new `:rescuable` value
# (Rails 7.1+), rendering exception templates only for rescuable exceptions
# and raising for everything else, instead of the old boolean on/off toggle.
#
# NOT adopted: this app's config/environments/test.rb explicitly sets
# `config.action_dispatch.show_exceptions = false` for parallel-test
# infrastructure reasons; revisit only with dedicated test-suite validation.
