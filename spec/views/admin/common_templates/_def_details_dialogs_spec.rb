# frozen_string_literal: true

require 'rails_helper'

# Regression spec for issue #1394: the "dialogs" section of the dynamic model
# (and external identifier) admin "def details" page failed to list any entries
# from a `dialog_before` configuration, regardless of whether the config used
# the simple string pattern or the hash pattern (with `name:`/`label:` keys).
#
# Root cause: `d.dialog_before` returns an
# `OptionConfigs::ExtraOptionConfigs::DialogBefore` instance (a field-keyed
# configuration object), not a plain Ruby `Hash` or `String`. The partial's
# `case dialog_before; when Hash; when String; else []` dispatch always fell
# through to the `else` branch, silently discarding every configured dialog.
RSpec.describe 'admin/common_templates/_def_details_dialogs', type: :view do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  before do
    Admin::MessageTemplate.create!(
      name: 'string_pattern_dialog',
      message_type: :dialog,
      template_type: :content,
      template: '<p>string pattern</p>',
      current_admin: @admin
    )
    Admin::MessageTemplate.create!(
      name: 'hash_pattern_dialog',
      message_type: :dialog,
      template_type: :content,
      template: '<p>hash pattern</p>',
      current_admin: @admin
    )

    # In production, `object_instance` is a controller helper_method (see
    # ModelNaming) that DialogHelper#link_to_dialog relies on for its "add a new
    # dialog" fallback link; stub it here since view specs have no controller.
    dm = @dm
    view.define_singleton_method(:object_instance) { dm }
  end

  it 'lists a dialog link for both the string-pattern and hash-pattern dialog_before entries' do
    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
          - test2
        dialog_before:
          test1: string_pattern_dialog
          test2:
            name: hash_pattern_dialog
            label: Show confirmation
    YAML

    render partial: 'admin/common_templates/def_details_dialogs', locals: { object_instance: @dm }

    assert_select 'ul.al-reference-list li', count: 2
    assert_select 'ul.al-reference-list li a[href*="filter%5Bid%5D"]', text: /string_pattern_dialog/
    assert_select 'ul.al-reference-list li a[href*="filter%5Bid%5D"]', text: /hash_pattern_dialog/
  end

  it 'shows only the fallback "add a new dialog" message when dialog_before is absent' do
    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
    YAML

    render partial: 'admin/common_templates/def_details_dialogs', locals: { object_instance: @dm }

    assert_select 'ul.al-reference-list li', count: 0
    expect(rendered).to include('new dialog template')
  end

  it 'shows an "add a new dialog" fallback link when the named template does not exist' do
    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
        dialog_before:
          test1: missing_template
    YAML

    render partial: 'admin/common_templates/def_details_dialogs', locals: { object_instance: @dm }

    assert_select 'ul.al-reference-list li', count: 1
    expect(rendered).to include("new dialog for 'missing_template'")
  end

  it 'aggregates dialogs across multiple option_configs on the same definition' do
    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
        dialog_before:
          test1: string_pattern_dialog

      alt_option_type:
        fields:
          - test2
        dialog_before:
          test2:
            name: hash_pattern_dialog
    YAML

    render partial: 'admin/common_templates/def_details_dialogs', locals: { object_instance: @dm }

    assert_select 'ul.al-reference-list li', count: 2
    expect(rendered).to include('string_pattern_dialog')
    expect(rendered).to include('hash_pattern_dialog')
  end
end
