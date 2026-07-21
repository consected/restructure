# frozen_string_literal: true

# System spec for GitHub issue #1269 - yaml_object field workflow.
#
# Purpose: verify end-to-end behavior of a dynamic model field named `yaml_object_*`
# backed by a text/varchar column:
# 1. The edit form renders a YAML CodeMirror editor (code-editor-yaml class).
# 2. Valid YAML Hash/Array text can be submitted and persists as raw YAML text.
# 3. After save, the show view renders the parsed YAML as a structured object
#    (via the yaml_parse Handlebars helper and the 'typeof object' template path).
# 4. Edit mode re-opens the CodeMirror editor pre-filled with the persisted YAML text.
#
# The spec creates a minimal dynamic model with a yaml_object_config text field,
# exercises create/edit via the CodeMirror helper, and verifies persistence and display.

require 'rails_helper'

describe 'dynamic model yaml_object field', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelSupport
  include DynamicModelExpectationsSupport
  include CodemirrorEditorSupport

  def set_up_feature
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('AllowDynamicMigrations', true)

    create_admin

    ms = Master.no_temporary_masters
    if ms.none? || ms.first.nil? || ms.first.id < 1
      create_data_set_outside_tx
      @master ||= ms.first
      @master_id ||= @master.id
    else
      @master = ms.first
      @master_id = @master.id
    end

    expect(@master_id).to be > 0

    @user, @good_password = create_user(create_master: true)
    @good_email = @user.email
    @app_type = @user.app_type
    expect(@app_type).not_to be nil
    expect(@user.two_factor_setup_required?).to be_falsey
  end

  def setup_yaml_object_dm
    DynamicModel.active.where(table_name: 'test_yaml_object_fields').reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestYamlObjectField) if defined? DynamicModel::TestYamlObjectField

    dm_options = <<~YAML
      _configurations: {}

      default:
        labels:
          yaml_object_config: Config
          title: Title
    YAML

    dm = DynamicModel.create! current_admin: @admin,
                              name: 'test yaml object fields',
                              schema_name: 'dynamic_test',
                              table_name: 'test_yaml_object_fields',
                              category: :details,
                              options: dm_options,
                              field_list: 'title yaml_object_config',
                              primary_key_name: 'id',
                              foreign_key_name: 'master_id'

    dm.current_admin = @admin
    dm.update_tracker_events

    setup_access :dynamic_model__test_yaml_object_fields, user: @user

    dm
  end

  describe 'create and edit with yaml_object field' do
    before(:all) do
      set_up_feature
      @yaml_dm = setup_yaml_object_dm

      @yaml_dm.force_regenerate = true
      @yaml_dm.generate_model
      @yaml_dm.add_master_association

      DynamicModel.routes_load
      Rails.application.routes_reloader.reload!
    end

    before(:each) do
      validate_setup
      login
    end

    it 'creates a record with valid YAML in a CodeMirror editor and persists raw text' do
      yaml_text = "name: test\nitems:\n  - one\n  - two"

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      expand_master_record_tab('details')
      finish_page_loading

      new_button_selector = '.details-item-type-dynamic-model--test-yaml-object-fields .new-button-container a.btn'
      expect(page).to have_css(new_button_selector, wait: 10)

      new_button = find(new_button_selector, wait: 10)
      scroll_into_view(new_button)
      new_button.click
      finish_page_loading

      form_selector = 'form.new_dynamic_model_test_yaml_object_field'
      expect(page).to have_css(form_selector, wait: 10)
      finish_form_formatting
      sleep 1

      # Verify the CodeMirror YAML editor is rendered
      within(form_selector) do
        expect(page).to have_css('textarea.code-editor-yaml[data-code-editor-type="yaml"]', visible: :all)
        fill_in 'Title', with: 'yaml test record'
      end

      # Set YAML content via the CodeMirror helper
      form_id = find(form_selector)[:id]
      codemirror_set_value(form_id: form_id, field_name: 'yaml_object_config', value: yaml_text)

      within(form_selector) do
        click_on 'Save'
      end

      finish_page_loading

      # Verify the record persisted the raw YAML text in the database
      record = DynamicModel::TestYamlObjectField.last
      expect(record).not_to be_nil
      # Browser textareas submit CRLF; normalize before comparing
      expect(record.yaml_object_config.gsub("\r\n", "\n")).to eq(yaml_text)
      expect(record.title).to eq('yaml test record')

      # Verify the show view renders the parsed YAML as a structured object
      # The yaml_parse helper converts the text to an object, then the 'typeof object'
      # branch renders it with the .typeof-object-field class
      show_selector = ".common-templates--result-item[data-item-class='dynamic_model__test_yaml_object_field']"
      expect(page).to have_css(show_selector, wait: 10)

      within(show_selector) do
        expect(page).to have_css('li.typeof-object-field[data-field-name="yaml_object_config"]', wait: 10)

        # The nested key/value content sits inside a Bootstrap 'collapse' block that is
        # collapsed by default, so it must be read with visible: :all rather than
        # requiring it to be on-screen. This confirms the parsed YAML content actually
        # rendered (name/items/one/two), not just that the container element exists.
        object_field = find('li.typeof-object-field[data-field-name="yaml_object_config"]', visible: :all, wait: 10)
        content = object_field.text(:all).downcase

        expect(content).to include('name')
        expect(content).to include('test')
        expect(content).to include('items')
        expect(content).to include('one')
        expect(content).to include('two')
      end
    end

    it 'edits an existing record and updates the YAML content' do
      # Create a record directly for editing
      @master.current_user = @user
      initial_yaml = 'key: initial_value'
      record = DynamicModel::TestYamlObjectField.create!(
        current_user: @user,
        master: @master,
        title: 'edit test',
        yaml_object_config: initial_yaml
      )

      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      expand_master_record_tab('details')
      finish_page_loading

      # Find the show view for the record and click edit
      show_selector = ".common-templates--result-item[data-item-class='dynamic_model__test_yaml_object_field']"
      expect(page).to have_css(show_selector, wait: 10)

      click_edit_button_in(show_selector)

      edit_form_selector = 'form.edit_dynamic_model_test_yaml_object_field'
      expect(page).to have_css(edit_form_selector, wait: 10)
      finish_form_formatting
      sleep 1

      # Verify the CodeMirror editor has the existing YAML content
      form_id = find(edit_form_selector)[:id]
      editor_content = codemirror_get_value(form_id: form_id)
      expect(editor_content).to eq(initial_yaml)

      # Update with new YAML content
      updated_yaml = "key: updated_value\nnew_key: added"
      codemirror_set_value(form_id: form_id, field_name: 'yaml_object_config', value: updated_yaml)

      within(edit_form_selector) do
        click_on 'Save'
      end

      finish_page_loading

      # Verify persistence of the updated value
      record.reload
      # Browser textareas submit CRLF; normalize before comparing
      expect(record.yaml_object_config.gsub("\r\n", "\n")).to eq(updated_yaml)

      # Verify the updated structured display
      expect(page).to have_css(show_selector, wait: 10)
      within(show_selector) do
        expect(page).to have_css('li.typeof-object-field[data-field-name="yaml_object_config"]', wait: 10)

        # As above, read with visible: :all since the nested content sits inside a
        # collapsed Bootstrap block by default - confirms the updated YAML content
        # (key/new_key/updated_value/added) actually rendered, not just the container.
        object_field = find('li.typeof-object-field[data-field-name="yaml_object_config"]', visible: :all, wait: 10)
        content = object_field.text(:all).downcase

        expect(content).to include('key')
        expect(content).to include('updated')
        expect(content).to include('new key')
        expect(content).to include('added')
      end
    end
  end
end
