# Be sure to restart your server when you modify this file.
#
# This file documents Rails 8.1 new framework defaults that are NOT currently
# enabled in this app, reviewed during the Rails 8.1 upgrade (issue #1325, refs
# #1015), by reading the actual `new_framework_defaults_8_1.rb.tt` generator
# template shipped in the installed railties-8.1.3.1 gem (the interactive
# `bin/rails app:update --pretend` conflict-resolution prompts could not be
# driven non-interactively in this environment, so the template was read
# directly instead - same authoritative source `app:update` would have used).
#
# None of these are adopted here - each has been reviewed and a decision
# recorded below. Revisit this file if adopting any of them later.
#
# Read the Rails 8.1 upgrade guide for more info:
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#upgrading-from-rails-8-0-to-rails-8-1
#
# NOTE: the official upgrade guide's "Upgrading from Rails 8.0 to Rails 8.1"
# section lists exactly one change beyond these opt-in defaults: table columns
# in `schema.rb` are now sorted alphabetically. This app uses
# `config.active_record.schema_format = :sql` (structure.sql), so that change
# does not apply here at all.

###
# Skips escaping HTML entities (<, >, &) and Unicode line/paragraph separators
# (U+2028/U+2029) in JSON responses, for a performance improvement.
#
# NOT ADOPTED: this is a SECURITY-relevant change, not just a performance one.
# If any client-side code takes a JSON API response and embeds it unsafely into
# HTML (e.g. inline `<script>var data = ...</script>` without JSON.parse, or
# server-side ERB embedding a JSON string directly into a `<script>` tag),
# disabling this escaping could reintroduce an XSS vector for `<script>`/`</script>`
# breakout via `<`/`>` in string values. This app's Handlebars-based SPA
# consumes JSON via AJAX + JSON.parse (see docs/dev_reference on the
# UI template architecture), which is unaffected, but every JSON-embedding
# call site (search for `.to_json` used directly inside ERB `<script>` blocks,
# as opposed to a `data-*` attribute or AJAX response body) should be audited
# before adopting. Track as a follow-up if pursued.
#
# Rails.configuration.action_controller.escape_json_responses = false

###
# Skips escaping LINE SEPARATOR (U+2028) and PARAGRAPH SEPARATOR (U+2029) in
# JSON specifically (a narrower variant of the above). Historically unsafe
# inside JavaScript string literals, but valid since ECMAScript 2019 in all
# modern browsers: https://caniuse.com/mdn-javascript_builtins_json_json_superset
#
# NOT ADOPTED: same audit dependency as escape_json_responses above; revisit
# together.
#
# Rails.configuration.active_support.escape_js_separators_in_json = false

###
# Raises an error when order-dependent finder methods (`#first`, `#second`,
# etc.) are called without an explicit `order` on the relation, and the model
# has no `implicit_order_column`/`query_constraints`/primary key fallback to
# rely on for a deterministic order.
#
# NOT ADOPTED: this is a genuinely useful correctness safety net (prevents
# non-deterministic pagination/ordering bugs from unordered `.first`/`.last`
# calls), but adopting it requires auditing every `.first`/`.second`/etc. call
# across the codebase that currently relies on implicit DB ordering without an
# explicit `order` clause - a large, unknown blast radius. Track as a follow-up
# audit task, similar in spirit to the #1295/#1302 sub-issue audits.
#
# Rails.configuration.active_record.raise_on_missing_required_finder_order_columns = true

###
# SECURITY: controls how Rails handles relative-path redirects that don't
# start with a leading slash (open-redirect protection - OWASP "Unvalidated
# Redirects and Forwards"). `:raise` rejects them outright with
# ActionController::Redirecting::UnsafeRedirectError; the current implicit
# default only logs a warning.
#
# NOT ADOPTED YET, but recommended as a genuine security hardening worth
# pursuing as a follow-up: audit all `redirect_to` call sites for any relative
# path without a leading slash (uncommon, but possible), first trialling
# `:notify` (sends an ActiveSupport notification without raising, useful for a
# staging-environment audit pass) before escalating to `:raise` in production.
#
# Rails.configuration.action_controller.action_on_path_relative_redirect = :raise

###
# Switches Action View's template-dependency tracker (used for Russian-doll
# fragment cache key invalidation, i.e. `cache do ... end` blocks) from the
# legacy comment/regex-based scanner to a Ruby-parser-based one, which can
# detect dependencies the old scanner misses.
#
# NOT ADOPTED: this app has had prior whole-cache-clear/cache-invalidation
# bugs (see memory notes on caching pitfalls) and a more accurate dependency
# tracker could genuinely help, but it's a newer, less battle-tested mechanism
# and changing cache-key computation warrants its own dedicated testing pass
# rather than a blanket flip here. Track as a low-priority follow-up.
#
# Rails.configuration.action_view.render_tracker = :ruby

###
# Omits the `autocomplete="off"` attribute from hidden fields generated by
# `form_tag`, `token_tag`, `method_tag`, and `button_to`'s hidden parameter
# fields.
#
# NOT ADOPTED: purely cosmetic/markup-level, no compelling reason either way;
# trivial, no urgency.
#
# Rails.configuration.action_view.remove_hidden_field_autocomplete = true
