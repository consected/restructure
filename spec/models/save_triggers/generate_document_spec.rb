# frozen_string_literal: true

# Tests for SaveTriggers::GenerateDocument - Issue #961
#
# This spec verifies the generate_document save trigger, which renders content
# from a template (using the same template mechanisms as the notify trigger),
# then stores the rendered document as a file in an NFS filestore container.
#
# Covers:
# - Registration in ValidSaveTriggers
# - Template rendering with content_template_name (named template lookup)
# - Template rendering with content_template_text (inline text)
# - Layout wrapping via layout_template
# - Extra substitutions for {{extra_substitutions.*}} tags
# - Curly substitutions in filename, content_template_text, and extra_substitutions
# - File storage in NFS container via NfsStore::Import.import_file
# - Container resolution via model reference (from_this)
# - Container resolution via name-based lookup
# - Container resolution via id lookup
# - User context via store_as_user and store_in_app_type
# - Conditional execution via if: configuration
# - Trigger results stored in save_trigger_results['generate_document']
# - Error handling for missing container, missing template, empty content
# - Filename sanitization
# - skip_existing and replace options for duplicate filenames

require 'rails_helper'

RSpec.describe SaveTriggers::GenerateDocument, type: :model do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  before :each do
    setup_nfs_store
    @master = @player_contact.master
    @master.current_user = @user

    # Create message templates for testing
    @content_template = Admin::MessageTemplate.create!(
      name: 'test generate doc content',
      message_type: :plain,
      template_type: :content,
      template: '<p>Document for master {{master_id}}. Who: {{select_who}}.</p>',
      current_admin: @admin
    )

    @layout_template = Admin::MessageTemplate.create!(
      name: 'test generate doc layout',
      message_type: :plain,
      template_type: :layout,
      template: '<html><body>{{main_content}}</body></html>',
      current_admin: @admin
    )

    # Create an activity log instance with a filestore container
    @al = @player_contact.activity_log__player_contact_phones.create!(
      select_call_direction: 'from player',
      select_who: 'test user',
      extra_log_type: 'step_1',
      master: @master
    )

    @al.save_trigger_results ||= {}

    # Get the container that was created by the save trigger on @al
    refs = ModelReference.find_references(@al, to_record_type: 'nfs_store__manage__container', active: true)
    expect(refs).not_to be_empty
    @container = refs.first.to_record
    expect(@container).to be_a(NfsStore::Manage::Container)
  end

  describe 'ValidSaveTriggers registration' do
    it 'is included in ValidSaveTriggers' do
      expect(OptionConfigs::ExtraOptionImplementers::SaveTriggers::ValidSaveTriggers).to include(:generate_document)
    end

    it 'can be resolved via trigger_class' do
      klass = OptionConfigs::ExtraOptions.trigger_class(:generate_document)
      expect(klass).to eq SaveTriggers::GenerateDocument
    end
  end

  describe 'template rendering with content_template_name' do
    it 'renders content from a named template and stores the file' do
      config = {
        content_template_name: 'test generate doc content',
        container: { from_this: 'model_reference' },
        filename: 'test-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      # Verify the file was stored
      stored = @container.stored_files.find_by(file_name: 'test-doc.html')
      expect(stored).not_to be_nil

      # Verify content was rendered with substitutions
      file_path = stored.retrieval_path
      content = File.read(file_path)
      expect(content).to include("master #{@master.id}")
      expect(content).to include('test user')
    end
  end

  describe 'template rendering with content_template_text' do
    it 'renders inline template text and stores the file' do
      config = {
        content_template_text: '<p>Inline doc for {{master_id}}</p>',
        container: { from_this: 'model_reference' },
        filename: 'inline-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      stored = @container.stored_files.find_by(file_name: 'inline-doc.html')
      expect(stored).not_to be_nil

      file_path = stored.retrieval_path
      content = File.read(file_path)
      expect(content).to include(@master.id.to_s)
    end
  end

  describe 'layout wrapping' do
    it 'wraps content in a layout template' do
      config = {
        content_template_name: 'test generate doc content',
        layout_template: 'test generate doc layout',
        container: { from_this: 'model_reference' },
        filename: 'layout-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      stored = @container.stored_files.find_by(file_name: 'layout-doc.html')
      expect(stored).not_to be_nil

      file_path = stored.retrieval_path
      content = File.read(file_path)
      expect(content).to include('<html><body>')
      expect(content).to include('</body></html>')
      expect(content).to include("master #{@master.id}")
    end
  end

  describe 'extra substitutions' do
    it 'supports extra_substitutions for additional tag substitutions' do
      config = {
        content_template_text: '<p>Report: {{extra_substitutions.report_title}}</p>',
        extra_substitutions: {
          report_title: 'Monthly Summary'
        },
        container: { from_this: 'model_reference' },
        filename: 'extra-subs-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      stored = @container.stored_files.find_by(file_name: 'extra-subs-doc.html')
      expect(stored).not_to be_nil

      file_path = stored.retrieval_path
      content = File.read(file_path)
      expect(content).to include('Monthly Summary')
    end

    it 'substitutes item attributes within extra_substitutions values' do
      config = {
        content_template_text: '<p>{{extra_substitutions.ref}}</p>',
        extra_substitutions: {
          ref: 'master-{{master_id}}'
        },
        container: { from_this: 'model_reference' },
        filename: 'extra-subs-substituted.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      stored = @container.stored_files.find_by(file_name: 'extra-subs-substituted.html')
      expect(stored).not_to be_nil

      file_path = stored.retrieval_path
      content = File.read(file_path)
      expect(content).to include("master-#{@master.id}")
    end
  end

  describe 'curly substitutions in filename' do
    it 'substitutes item attributes in the filename' do
      config = {
        content_template_text: '<p>doc content</p>',
        container: { from_this: 'model_reference' },
        filename: 'report-{{id}}.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      expected_filename = "report-#{@al.id}.html"
      stored = @container.stored_files.find_by(file_name: expected_filename)
      expect(stored).not_to be_nil
    end
  end

  describe 'container resolution' do
    it 'resolves container via model reference (from_this)' do
      config = {
        content_template_text: '<p>from_this container</p>',
        container: { from_this: 'model_reference' },
        filename: 'from-this-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      stored = @container.stored_files.find_by(file_name: 'from-this-doc.html')
      expect(stored).not_to be_nil
    end

    it 'resolves container by name lookup' do
      config = {
        content_template_text: '<p>named container</p>',
        container: { name: @container.name },
        filename: 'named-container-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      # Verify the trigger stored results with the correct container info
      results = @al.save_trigger_results['generate_document']
      expect(results).not_to be_nil
      expect(results[:stored_file_id]).not_to be_nil

      # Verify the file exists in the resolved container
      resolved_container = NfsStore::Manage::Container.find(results[:container_id])
      stored = resolved_container.stored_files.find_by(file_name: 'named-container-doc.html')
      expect(stored).not_to be_nil
    end

    it 'resolves container by id lookup' do
      config = {
        content_template_text: '<p>id container</p>',
        container: { id: @container.id },
        filename: 'id-container-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      results = @al.save_trigger_results['generate_document']
      expect(results).not_to be_nil
      expect(results[:container_id]).to eq(@container.id)

      stored = @container.stored_files.find_by(file_name: 'id-container-doc.html')
      expect(stored).not_to be_nil
    end

    it 'raises an error when container id does not exist' do
      config = {
        content_template_text: '<p>bad id</p>',
        container: { id: -999 },
        filename: 'bad-id-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /could not resolve container/)
    end
  end

  describe 'file storage path' do
    it 'stores the file in a subdirectory when path is specified' do
      config = {
        content_template_text: '<p>path doc</p>',
        container: { from_this: 'model_reference' },
        filename: 'pathed-doc.html',
        content_type: 'text/html',
        path: 'reports',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      stored = @container.stored_files.find_by(file_name: 'pathed-doc.html', path: 'reports')
      expect(stored).not_to be_nil
    end
  end

  describe 'user context' do
    it 'uses store_as_user to resolve the user for file import' do
      config = {
        content_template_text: '<p>user context doc</p>',
        container: { from_this: 'model_reference' },
        filename: 'user-context-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      stored = @container.stored_files.find_by(file_name: 'user-context-doc.html')
      expect(stored).not_to be_nil
    end
  end

  describe 'conditional execution' do
    it 'generates document when if condition is met' do
      config = {
        if: {
          all: {
            this: {
              select_call_direction: 'from player'
            }
          }
        },
        content_template_text: '<p>conditional doc</p>',
        container: { from_this: 'model_reference' },
        filename: 'conditional-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      stored = @container.stored_files.find_by(file_name: 'conditional-doc.html')
      expect(stored).not_to be_nil
    end

    it 'skips document generation when if condition is not met' do
      config = {
        if: {
          all: {
            this: {
              select_call_direction: 'nonexistent direction'
            }
          }
        },
        content_template_text: '<p>should not generate</p>',
        container: { from_this: 'model_reference' },
        filename: 'skipped-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      stored = @container.stored_files.find_by(file_name: 'skipped-doc.html')
      expect(stored).to be_nil
    end
  end

  describe 'trigger results' do
    it 'stores results in save_trigger_results for subsequent triggers' do
      config = {
        content_template_text: '<p>results doc</p>',
        container: { from_this: 'model_reference' },
        filename: 'results-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      results = @al.save_trigger_results['generate_document']
      expect(results).not_to be_nil
      expect(results).to be_a(Hash)
      expect(results[:container_id]).to eq @container.id
      expect(results[:filename]).to eq 'results-doc.html'
      expect(results[:stored_file_id]).not_to be_nil
    end
  end

  describe 'error handling' do
    it 'raises an error when container cannot be resolved' do
      config = {
        content_template_text: '<p>no container</p>',
        container: { name: 'nonexistent-container-name' },
        filename: 'error-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /container/i)
    end

    it 'raises an error when content_template_name references a non-existent template' do
      config = {
        content_template_name: 'nonexistent_template_name',
        container: { from_this: 'model_reference' },
        filename: 'error-template-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /template/i)
    end

    it 'raises an error when neither content_template_name nor content_template_text is specified' do
      config = {
        container: { from_this: 'model_reference' },
        filename: 'no-content-doc.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /content_template/)
    end
  end

  describe 'filename sanitization' do
    it 'sanitizes dangerous characters from the filename' do
      config = {
        content_template_text: '<p>sanitized doc</p>',
        container: { from_this: 'model_reference' },
        filename: 'report/../../../etc/passwd',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      trigger = SaveTriggers::GenerateDocument.new(config, @al)
      trigger.perform

      # The filename should have been sanitized - no path traversal
      results = @al.save_trigger_results['generate_document']
      expect(results[:filename]).not_to include('..')
      expect(results[:filename]).not_to include('/')
    end
  end

  describe 'duplicate filename handling' do
    it 'replaces existing file when replace option is set' do
      base_config = {
        content_template_text: '<p>original content</p>',
        container: { from_this: 'model_reference' },
        filename: 'replace-test.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      # First create
      trigger = SaveTriggers::GenerateDocument.new(base_config, @al)
      trigger.perform

      stored1 = @container.stored_files.where(file_name: 'replace-test.html').first
      expect(stored1).not_to be_nil

      # Update with replace
      replace_config = base_config.merge(
        content_template_text: '<p>replaced content</p>',
        replace: true
      )

      trigger2 = SaveTriggers::GenerateDocument.new(replace_config, @al)
      trigger2.perform

      # Should still have one file (replaced)
      stored_count = @container.stored_files.where(file_name: 'replace-test.html').count
      expect(stored_count).to eq 1
    end

    it 'skips file creation when skip_existing option is set and file exists' do
      base_config = {
        content_template_text: '<p>original content</p>',
        container: { from_this: 'model_reference' },
        filename: 'skip-test.html',
        content_type: 'text/html',
        store_as_user: @user.email
      }

      # First create
      trigger = SaveTriggers::GenerateDocument.new(base_config, @al)
      trigger.perform

      stored1 = @container.stored_files.where(file_name: 'skip-test.html').first
      expect(stored1).not_to be_nil

      # Try to create again with skip_existing
      skip_config = base_config.merge(skip_existing: true)
      trigger2 = SaveTriggers::GenerateDocument.new(skip_config, @al)
      trigger2.perform

      # Should still only have one file
      stored_count = @container.stored_files.where(file_name: 'skip-test.html').count
      expect(stored_count).to eq 1
    end
  end
end
