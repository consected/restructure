# frozen_string_literal: true

# Verifies that condition linter warnings are reported, without blocking saves, for dynamic definitions and page
# layouts; that a failing linter yields a single notice; and that warnings appear in the configuration notices
# shown in definition details and on the app type components page (Admin::AppType#check_option_configs).
require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe 'Condition linter integrations', type: :model do
  include ModelSupport
  include DynamicModelSupport

  let(:invalid_options) do
    <<~YAML
      default:
        showable_if:
          all:
            missing_linter_table:
              missing_linter_field: unexpected
    YAML
  end

  let(:valid_options) do
    <<~YAML
      default:
        showable_if:
          always: true
    YAML
  end

  let(:default_showable_snippet) do
    {
      'default' => {
        'showable_if' => {
          'all' => { 'missing_linter_table' => { 'missing_linter_field' => 'unexpected' } }
        }
      }
    }
  end

  let(:perspective_snippet) do
    {
      'view_options' => {
        'perspectives' => {
          'addresses' => [
            { 'conditional_calculation' => { 'missing_linter_table' => { 'missing_linter_field' => 'return_value' } } }
          ]
        }
      }
    }
  end

  let(:bad_operator_snippet) do
    {
      'view_options' => {
        'perspectives' => {
          'addresses' => [
            { 'conditional_calculation' => { 'addresses' => { 'city' => {
              'condition' => 'bogus_operator', 'value' => 'portland'
            } } } }
          ]
        }
      }
    }
  end

  let(:valid_perspectives) do
    <<~YAML
      view_options:
        perspectives:
          addresses:
            - name: zip_match
              conditional_calculation:
                addresses:
                  city: portland
                  return: return_all_results
    YAML
  end

  let(:invalid_perspectives) do
    <<~YAML
      view_options:
        perspectives:
          addresses:
            - name: open
              conditional_calculation:
                missing_linter_table:
                  missing_linter_field: return_value
    YAML
  end

  before do
    @user0, = create_user
    create_admin
    create_user
    @definition = generate_test_dynamic_model
  end

  def condition_warnings(notices)
    Array(notices).select { |notice| notice[:type] == OptionConfigs::ConditionLintNotices::WARNING_TYPE }
  end

  def build_page_layout(options)
    Admin::PageLayout.new(layout_name: 'master', panel_name: 'condition-linter-integration',
                          panel_label: 'Condition Linter Integration', options:).tap do |layout|
      layout.current_admin = @admin
    end
  end

  it 'returns condition warnings after saving a dynamic definition without rejecting the save' do
    expect { @definition.update!(options: invalid_options, current_admin: @admin) }.not_to raise_error
    expect(@definition.reload).to be_persisted

    notices = OptionConfigs::ExtraOptions.all_option_configs_notices(@definition)
    expect(condition_warnings(notices)).to include(a_hash_including(config_def: default_showable_snippet))
    expect(condition_warnings(notices)).to include(a_hash_including(message: a_string_including('missing_linter_table')))
  end

  it 'names the warning type as a condition configuration' do
    expect(OptionConfigs::ConditionLintNotices::WARNING_TYPE).to eq('condition configuration')
  end

  it 'states only the problem in the message, with the location shown as the configuration snippet' do
    @definition.update!(options: invalid_options, current_admin: @admin)

    warnings = condition_warnings(OptionConfigs::ExtraOptions.all_option_configs_notices(@definition.reload))
    expect(warnings).not_to be_empty
    expect(warnings.map { |notice| notice[:message] }).to all(satisfy { |message| !message.include?('default.') })
    expect(warnings.map { |notice| notice[:config_def] }).to all(be_a(Hash).and(satisfy(&:present?)))
  end

  it 'reports no condition warnings for a valid dynamic definition' do
    @definition.update!(options: valid_options, current_admin: @admin)

    expect(condition_warnings(OptionConfigs::ExtraOptions.all_option_configs_notices(@definition.reload))).to be_empty
  end

  it 'keeps condition warnings out of the errors that block saving' do
    @definition.update!(options: invalid_options, current_admin: @admin)

    expect(OptionConfigs::ExtraOptions.all_option_configs_errors(@definition.reload)).to be_nil
  end

  it 'reports a single condition linter failure notice, without breaking the page, if the linter raises' do
    @definition.update!(options: invalid_options, current_admin: @admin)
    allow(CalcActions::ConditionLinter).to receive(:new).and_raise(StandardError, 'linter exploded')

    notices = OptionConfigs::ExtraOptions.all_option_configs_notices(@definition.reload)
    failures = Array(notices).select { |n| n[:type] == OptionConfigs::ConditionLintNotices::FAILURE_TYPE }
    expect(failures.length).to eq(1)
    expect(failures.first[:message]).to include('linter exploded')
  end

  it 'saves a page layout with condition warnings, and reports them in its configuration notices' do
    page_layout = build_page_layout(invalid_perspectives)

    expect { page_layout.save! }.not_to raise_error
    notices = OptionConfigs::ExtraOptions.all_option_configs_notices(page_layout.reload)
    expect(condition_warnings(notices)).to include(a_hash_including(config_def: perspective_snippet))
  end

  it 'shows the offending value of a perspective condition in the configuration snippet' do
    bad_operator = <<~YAML
      view_options:
        perspectives:
          addresses:
            - name: open
              conditional_calculation:
                addresses:
                  city:
                    condition: bogus_operator
                    value: portland
                  return: return_all_results
    YAML
    page_layout = build_page_layout(bad_operator)
    page_layout.save!

    warnings = condition_warnings(OptionConfigs::ExtraOptions.all_option_configs_notices(page_layout.reload))
    expect(warnings).to include(a_hash_including(
                                  message: a_string_including("condition 'bogus_operator' is not supported"),
                                  config_def: bad_operator_snippet
                                ))
  end

  it 'does not mention no_masters for a perspective base that is not a resource, when the perspective implies it' do
    implied_base = <<~YAML
      view_options:
        perspectives:
          activity_log__reviews:
            - conditional_calculation:
                activity_log__somethins:
                  do nothing: true
    YAML
    page_layout = build_page_layout(implied_base)
    page_layout.save!

    warnings = condition_warnings(OptionConfigs::ExtraOptions.all_option_configs_notices(page_layout.reload))
    expect(warnings).to contain_exactly(a_hash_including(
                                          message: "'activity_log__somethins' is not a known resource. A perspective " \
                                                   'conditional_calculation must start from an activity log, ' \
                                                   'dynamic model or other resource',
                                          config_def: {
                                            'view_options' => { 'perspectives' => { 'activity_log__reviews' => [
                                              { 'conditional_calculation' => {
                                                'activity_log__somethins' => { 'do nothing' => true }
                                              } }
                                            ] } }
                                          }
                                        ))
    expect(warnings.map { |notice| notice[:message] }.join).not_to include('no_masters')
  end

  it 'keeps the no_masters wording for a perspective base that the admin wrote no_masters for' do
    explicit_base = <<~YAML
      view_options:
        perspectives:
          activity_log__reviews:
            - conditional_calculation:
                no_masters: {}
                activity_log__somethins:
                  do nothing: true
    YAML
    page_layout = build_page_layout(explicit_base)
    page_layout.save!

    warnings = condition_warnings(OptionConfigs::ExtraOptions.all_option_configs_notices(page_layout.reload))
    expect(warnings).to contain_exactly(a_hash_including(
                                          message: "'activity_log__somethins' is not a known resource to use as the " \
                                                   'base of a no_masters: {} query'
                                        ))
  end

  it 'reports a warning for each perspective item that has a problem' do
    two_items = <<~YAML
      view_options:
        perspectives:
          addresses:
            - name: first
              conditional_calculation:
                first_missing_table:
                  missing_linter_field: return_value
            - name: second
              conditional_calculation:
                second_missing_table:
                  missing_linter_field: return_value
    YAML
    page_layout = build_page_layout(two_items)
    page_layout.save!

    warnings = condition_warnings(OptionConfigs::ExtraOptions.all_option_configs_notices(page_layout.reload))
    indexes = warnings.map { |notice| notice[:config_def].dig('view_options', 'perspectives', 'addresses') }
    expect(indexes.flatten.map { |item| item['conditional_calculation'].keys.first })
      .to contain_exactly('first_missing_table', 'second_missing_table')
    expect(indexes.map(&:length)).to all(eq(1))
  end

  it 'reports the additional configuration notices of a page layout, which has no option configurations of its own' do
    page_layout = build_page_layout(valid_perspectives)
    page_layout.define_singleton_method(:additional_configuration_notices) do |levels:|
      levels.include?(:warnings) ? [{ type: 'page layout extra', name: 'extra', message: 'extra notice' }] : []
    end

    expect(page_layout).not_to respond_to(:option_configs)
    expect(OptionConfigs::ExtraOptions.all_option_configs_notices(page_layout)).to include(
      a_hash_including(type: 'page layout extra', message: 'extra notice')
    )
  end

  it 'reports no condition warnings for a valid page layout perspective' do
    page_layout = build_page_layout(valid_perspectives)
    page_layout.save!

    expect(condition_warnings(OptionConfigs::ExtraOptions.all_option_configs_notices(page_layout.reload))).to be_empty
  end

  it 'includes dynamic definition condition warnings in Admin::AppType#check_option_configs' do
    @definition.update!(options: invalid_options, current_admin: @admin)
    app_type = Admin::AppType.new
    allow(app_type).to receive(:valid_associated_activity_logs).and_return([])
    allow(app_type).to receive(:associated_dynamic_models).and_return([@definition])
    allow(app_type).to receive(:associated_external_identifiers).and_return([])

    expect(app_type.check_option_configs).to include(
      a_hash_including(message: a_string_including('missing_linter_table'))
    )
  end

  it 'includes page layout condition warnings in Admin::AppType#check_option_configs' do
    app_type = create_app_type(name: 'condition_linter_app', label: 'Condition Linter App')
    build_page_layout(invalid_perspectives).tap { |layout| layout.app_type = app_type }.save!

    expect(app_type.reload.check_option_configs).to include(
      a_hash_including(message: a_string_including('missing_linter_table'))
    )
  end

  it 'excludes condition warnings from disabled page layouts in Admin::AppType#check_option_configs' do
    disabled_perspectives = <<~YAML
      view_options:
        perspectives:
          addresses:
            - name: open
              conditional_calculation:
                disabled_linter_table:
                  disabled_linter_field: return_value
    YAML
    app_type = create_app_type(name: 'condition_linter_disabled_app', label: 'Condition Linter Disabled App')
    build_page_layout(disabled_perspectives).tap do |layout|
      layout.app_type = app_type
      layout.disabled = true
    end.save!

    expect(app_type.reload.check_option_configs).not_to include(
      a_hash_including(message: a_string_including('disabled_linter_table'))
    )
  end

  describe 'condition warnings inherited from _default' do
    let(:inherited_default_options) do
      <<~YAML
        _default:
          showable_if:
            all:
              missing_linter_table:
                missing_linter_field: unexpected
        default: {}
        create_reference: {}
      YAML
    end

    let(:inherited_two_conditions_options) do
      <<~YAML
        _default:
          showable_if:
            all:
              missing_linter_table:
                missing_linter_field: unexpected
          creatable_if:
            all:
              missing_linter_table:
                missing_linter_field: unexpected
        default: {}
        create_reference: {}
      YAML
    end

    it 'reports a condition inherited from _default once, rather than once per option type' do
      @definition.update!(options: inherited_default_options, current_admin: @admin)

      warnings = condition_warnings(OptionConfigs::ExtraOptions.all_option_configs_notices(@definition.reload))
      expect(warnings.count { |notice| notice[:message].include?('missing_linter_table') }).to eq(1)
    end

    it 'shows the inherited condition within the snippet of the option type that it applies to' do
      @definition.update!(options: inherited_default_options, current_admin: @admin)

      warnings = condition_warnings(OptionConfigs::ExtraOptions.all_option_configs_notices(@definition.reload))
      expect(warnings.map { |notice| notice[:config_def] }).to eq([default_showable_snippet])
    end

    it 'keeps warnings for different conditions in the same _default separate' do
      @definition.update!(options: inherited_two_conditions_options, current_admin: @admin)

      warnings = condition_warnings(OptionConfigs::ExtraOptions.all_option_configs_notices(@definition.reload))
      expect(warnings.length).to eq(2)
      expect(warnings.map { |notice| notice[:config_def]['default'].keys }.flatten).to contain_exactly(
        'showable_if', 'creatable_if'
      )
    end
  end
end
