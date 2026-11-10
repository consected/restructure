# frozen_string_literal: true

require 'rails_helper'

# Purpose: proves/disproves the content-addressing safety assumption behind Stage 1 of
# issue #1362, which renames compiled Handlebars template files after a digest of their
# PREPROCESSED SOURCE instead of `handlebars_cache_key` (which used to embed
# current_user.id). That change is only safe if the ERB partials feeding
# `write_handlebars_template` / `handlebars_template_tag` never bake literal
# PER-USER-INSTANCE data (name, email, etc.) into the template source as static text --
# they may only vary STRUCTURALLY (which markup is included), driven by config/role/access,
# which is identical for every user sharing that role/access and is therefore safe to
# content-address.
#
# Research across app/views/{masters,common_templates,dynamic_models,
# activity_logs,external_identifiers,trackers,tracker_histories,external_links,
# item_flags,filestore} found exactly one call site inside the Handlebars
# search-results template set that could embed a literal per-user field value:
#
#   app/views/masters/_search_results_resources_panel.html.erb
#     Formatter::Substitution.substitute(v, data: current_user, ...)
#
# `v` is an admin-configurable string (Admin::AppConfiguration). Because
# Formatter::Substitution supports plain `{{tag}}` substitution (not just structural
# `{{#if}}` / `{{#is}}` blocks), and `data: current_user` used to resolve bare tags
# directly against the CURRENT USER'S OWN attributes (see
# Formatter::Substitution.setup_data / setup_data_for_current_user), an admin COULD have
# configured a literal `{{first_name}}` / `{{email}}` tag there, baking it as literal
# static text into the compiled 'master_main_inner' handlebars partial.
#
# FIXED (issue #1362, option 3): the call site now passes `data: { role_name: ... }`
# instead of `data: current_user` - only `role_name` (the one attribute the feature
# actually needs, per Formatter::Substitution::setup_data_for_current_user's own
# "{{role_name}} for {{#is role_name ...}} patterns" comment) is resolvable; a literal
# {{first_name}}/{{email}} tag now silently resolves blank (ignore_missing: true) instead
# of leaking real user data, since setup_data_for_current_user's broader per-user tag
# population (current_user_email, user_email, etc.) never activates for a plain Hash that
# has no :current_user key resolving to a real User.
#
# RESOLVED (issue #1362 S4): with the source of the risk closed above, the
# `master_main_inner`-only exclusion from content-addressing (which forced it to always
# compile per-user, never shared) has been dropped - it is now content-addressed like
# every other template, in `HandlebarsPrecompilerHelper#handlebars_compiled_filename`.
#
# No live app config in this repo (fphs-app-configs, db/app_configs) uses a
# plain-tag `default_activity_log_perspective` today -- only structural
# `{{#is}}` patterns were found. This spec proves all three: the SAFE structural case,
# the FIXED literal-tag case (no longer leaks, renders identically for all users), and
# that {{#is role_name ...}} still resolves against the real current_user role:
#   1. SAFE (today's real usage pattern): a structural `{{#is}}` config
#      produces byte-identical rendered output for two users with the same
#      role/access but different name/email.
#   2. LATENT RISK (what the code technically permits): a literal `{{first_name}}`
#      config produces DIFFERENT rendered output for those same two users --
#      demonstrating the exception the content-addressing plan must account for
#      (e.g. exclude this panel from content-addressing, or restrict
#      `default_activity_log_perspective` substitution to structural tags only).

RSpec.describe 'masters/_search_results_resources_panel content-addressing safety (issue #1362)', type: :view do
  include UserSupport

  let(:dynamic_model_item) do
    Resources::Models::Item.new.merge(
      type: :dynamic_model,
      resource_name: 'dynamic_model__contact_infos',
      hyphenated_name: 'dynamic-model--contact-infos',
      base_route_segments: 'dynamic_model/contact_infos'
    )
  end

  let(:render_info_for_contact_infos) do
    {
      resource_name: 'dynamic_model__contact_infos',
      route_path: 'dynamic_model/contact_infos',
      template_name: 'dynamic-model--contact-infos-list-template',
      wrapper_class: 'dynamic-model-generic-block',
      viewable_key: :dynamic_model__contact_infos
    }
  end

  def make_panel(perspectives:)
    contains_double = double('contains', resources: ['dynamic_model__contact_infos'])
    view_options_double = double('view_options',
                                 default_expander: nil,
                                 hide_sublist_controls: false,
                                 hide_activity_logs_header: false,
                                 limit: 20,
                                 perspectives: perspectives,
                                 default_perspective: nil)
    double('panel',
           panel_name: 'contacts-panel',
           panel_label: 'Contacts',
           contains: contains_double,
           view_options: view_options_double,
           view_css: nil)
  end

  # Two real Users (content-addressing's `data: current_user` substitution only
  # triggers for an actual `User` instance -- see setup_data_for_current_user),
  # sharing the same app_type/role/access so any DIFFERENCE in rendered output
  # can only come from their own distinct name data, never from access control.
  let!(:user_one) { create_user('one').first }
  let!(:user_two) { create_user('two', '', app_type: user_one.app_type).first }

  before do
    allow(Resources::Models).to receive(:find_by) do |args|
      dynamic_model_item if args[:resource_name].to_s == 'dynamic_model__contact_infos'
    end
    allow(view).to receive(:master_viewables).and_return(dynamic_model__contact_infos: true)
    allow(view).to receive(:resource_render_info).and_return(render_info_for_contact_infos)
    allow(view).to receive(:hide_player_tabs?).and_return(false)
    stub_template 'reports/_insert_options_css.html.erb' => ''
  end

  # NOTE: the view-spec `rendered` helper ACCUMULATES output across every
  # `render` call in the same example, so calling it after a second render
  # would return renderA + renderB concatenated and mask real differences.
  # Capture the return value of `render` itself instead, which is just the
  # single partial's output.
  def render_for(user, config_value)
    allow(Admin::AppConfiguration).to receive(:hash_for)
      .with(:default_activity_log_perspective, user)
      .and_return('dynamic_model__contact_infos' => config_value)
    allow(view).to receive(:current_user).and_return(user)

    perspectives = { 'dynamic_model__contact_infos' => [{ name: 'recent', label: 'Recent' }] }
    render partial: 'masters/search_results_resources_panel', locals: { panel: make_panel(perspectives:) }
  end

  # Sanity check: the two users differ only in name/email, sharing app_type.
  it 'the two users have different first names but identical app_type' do
    expect(user_one.first_name).not_to eq(user_two.first_name)
    expect(user_one.app_type).to eq(user_two.app_type)
  end

  context 'SAFE: structural {{#is}} config (matches every live app config found in this repo)' do
    let(:structural_config) { "{{#is role_name '===' 'no_such_role'}}recent{{/is}}" }

    it 'renders byte-identical output for two users with different name/email' do
      html_one = render_for(user_one, structural_config)
      html_two = render_for(user_two, structural_config)

      expect(html_one).to eq(html_two)
    end
  end

  context 'FIXED (issue #1362, option 3): a literal {{first_name}} config no longer leaks per-user data' do
    let(:literal_config) { '{{first_name}}' }

    it 'resolves the literal tag to blank rather than the real user attribute' do
      html_one = render_for(user_one, literal_config)

      expect(html_one).not_to include(user_one.first_name.titleize)
    end

    it 'renders IDENTICAL output for two users with different name/email' do
      html_one = render_for(user_one, literal_config)
      html_two = render_for(user_two, literal_config)

      expect(html_one).to eq(html_two)
    end
  end

  context 'structural {{#is role_name ...}} still resolves against the real current_user role after the fix' do
    it 'branches correctly using the current_user role_name, matching pre-fix behaviour' do
      allow(user_one).to receive(:role_names).and_return(['principal_investigator'])
      config = "{{#is role_name '===' 'principal_investigator'}}matched{{else}}no-match{{/is}}"

      html = render_for(user_one, config)

      expect(html).to include('perspective=matched')
    end
  end
end
