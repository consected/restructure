# frozen_string_literal: true

#
# Save trigger to generate a document from a template and store it in
# an NFS filestore container. Uses the same template mechanisms as the
# notify trigger (Admin::MessageTemplate) and reuses the file import
# mechanism (NfsStore::Import.import_file).
#
# Example configuration:
#   save_trigger:
#     on_save:
#       generate_document:
#         content_template_name: 'template_name'
#         layout_template: 'layout_name'
#         extra_substitutions:
#           key1: 'value1'
#         container:
#           from_this: model_reference
#         filename: 'generated-report-{{id}}.html'
#         content_type: 'text/html'
#         path: 'reports'
#         store_as_user: 'user@example.com'
#         store_in_app_type: 'app_type_name'
#         if: <conditional>
#
class SaveTriggers::GenerateDocument < SaveTriggers::SaveTriggersBase
  def initialize(config, item)
    super
    @model_defs = config
  end

  #
  # Perform the document generation and file storage.
  # Evaluates conditional if, renders template content, resolves
  # the container, and imports the rendered file.
  def perform
    @model_defs = [@model_defs] unless @model_defs.is_a? Array

    @model_defs.each do |config|
      @config = config.is_a?(Hash) ? config : {}

      # Evaluate conditional if
      next unless if_evaluates(@config[:if])

      rendered_content = render_content
      resolved_filename = resolve_filename
      resolved_container = resolve_container
      store_user = resolve_user

      stored_file = store_file(resolved_container, resolved_filename, rendered_content, store_user)

      store_trigger_results('generate_document', {
                              container_id: resolved_container.id,
                              filename: resolved_filename,
                              stored_file_id: stored_file&.id,
                              path: @config[:path],
                              content_type: @config[:content_type]
                            })
    end
  end

  private

  #
  # Render the document content from a named template or inline text.
  # Supports layout wrapping and extra substitutions, consistent with
  # the notify trigger.
  # @return [String] the rendered content
  def render_content
    content_template_name = @config[:content_template_name]
    content_template_text = resolve_content_template_text
    layout_template_name = @config[:layout_template]
    extra_subs = resolve_extra_substitutions

    unless content_template_name || content_template_text
      raise FphsException, 'generate_document requires content_template_name or content_template_text'
    end

    # Build a data hash that includes extra_substitutions for {{extra_substitutions.*}} tags
    data = build_substitution_data(extra_subs)

    if layout_template_name
      # Use layout template wrapping
      layout = Admin::MessageTemplate.active.layout_templates.find_by(name: layout_template_name)
      raise FphsException, "No layout template found with name: #{layout_template_name}" unless layout

      layout.generate(
        content_template_name:,
        content_template_text:,
        data:,
        ignore_missing: true
      )
    else
      # Generate content without layout
      Admin::MessageTemplate.generate_content(
        content_template_name:,
        content_template_text:,
        data:,
        ignore_missing: true
      )
    end
  end

  #
  # Resolve the content_template_text field.
  # If the value is a Hash, treat it as a conditional action and resolve it.
  # If it's a string, return it as-is for later substitution by generate_content,
  # which will have access to extra_substitutions data.
  # @return [String|nil]
  def resolve_content_template_text
    text = @config[:content_template_text]
    return nil unless text

    if text.is_a?(Hash)
      FieldDefaults.calculate_default(@item, text, allow_nil: true, ignore_missing: true)
    else
      text
    end
  end

  #
  # Build a data hash for template substitution that includes extra_substitutions.
  # Uses Formatter::Substitution.setup_data for the item data, then adds
  # extra_substitutions for {{extra_substitutions.*}} tag access.
  # @param [Hash] extra_subs - resolved extra substitutions
  # @return [Hash] data hash for substitution
  def build_substitution_data(extra_subs)
    data = Formatter::Substitution.setup_data(@item)
    data[:extra_substitutions] = extra_subs if extra_subs.present?
    data
  end

  #
  # Resolve extra_substitutions, performing {{curly}} substitutions within values
  # @return [Hash]
  def resolve_extra_substitutions
    extra = @config[:extra_substitutions]
    return {} unless extra

    resolved = {}
    extra.each do |k, v|
      resolved[k] = if v.is_a?(String)
                      Formatter::Substitution.substitute(v, data: @item, tag_subs: nil, ignore_missing: true)
                    else
                      v
                    end
    end
    resolved
  end

  #
  # Resolve the filename, performing {{curly}} substitutions and sanitizing
  # @return [String]
  def resolve_filename
    filename = @config[:filename]
    raise FphsException, 'generate_document requires filename to be specified' if filename.blank?

    # Perform substitutions
    filename = Formatter::Substitution.substitute(filename, data: @item, tag_subs: nil, ignore_missing: true)

    # Sanitize: remove path traversal and directory separators
    sanitize_filename(filename)
  end

  #
  # Sanitize a filename to prevent path traversal attacks
  # @param [String] filename
  # @return [String] sanitized filename
  def sanitize_filename(filename)
    # Remove path traversal sequences
    filename = filename.gsub('..', '')
    # Remove directory separators
    filename = filename.gsub(%r{[/\\]}, '')
    # Remove leading/trailing whitespace and dots
    filename.strip.gsub(/\A\.+|\.+\z/, '')
  end

  #
  # Resolve the target NFS container from the container configuration.
  # Supports:
  #   - from_this: model_reference (lookup via ModelReference)
  #   - name: 'container-name' (lookup by name in master)
  #   - id: container_id (lookup by database id)
  # @return [NfsStore::Manage::Container]
  def resolve_container
    container_config = @config[:container]
    raise FphsException, 'generate_document requires container configuration' unless container_config.is_a?(Hash)

    container = nil

    if container_config[:from_this] == 'model_reference'
      # Resolve via model reference from the current item
      refs = ModelReference.find_references(@item, to_record_type: 'nfs_store__manage__container', active: true)
      container = refs.first&.to_record if refs.present?
    elsif container_config[:id]
      # Resolve by database id
      container_id = FieldDefaults.calculate_default(@item, container_config[:id],
                                                     allow_nil: true, ignore_missing: true)
      container = NfsStore::Manage::Container.find_by(id: container_id)
    elsif container_config[:name]
      # Resolve by name in the master
      container_name = FieldDefaults.calculate_default(@item, container_config[:name],
                                                       allow_nil: true, ignore_missing: true)
      container = NfsStore::Manage::Container.where(
        master_id: @item.master_id,
        name: container_name
      ).first
    end

    unless container
      raise FphsException,
            "generate_document could not resolve container from config: #{container_config}"
    end

    container
  end

  #
  # Resolve the user for the file store operation.
  # Uses store_as_user and store_in_app_type configuration,
  # following the pattern in DynamicModel.user_for_conf_snippet.
  # @return [User]
  def resolve_user
    user_config = {
      user: @config[:store_as_user],
      app_type: @config[:store_in_app_type]
    }.compact

    if user_config.present?
      resolved = DynamicModel.user_for_conf_snippet(user_config)
      return resolved if resolved
    end

    # Fall back to the item's current user
    @user
  end

  #
  # Store the rendered content as a file in the container.
  # Creates a temp file, writes the content, and imports it
  # using NfsStore::Import.import_file.
  # @param [NfsStore::Manage::Container] container
  # @param [String] filename
  # @param [String] content - the rendered document content
  # @param [User] store_user - user to perform the import
  # @return [NfsStore::Manage::StoredFile|nil]
  def store_file(container, filename, content, store_user)
    temp_file = Tempfile.new(['generate_document', File.extname(filename)])
    temp_file.write(content)
    temp_file.close

    path = @config[:path]
    skip_existing = @config[:skip_existing]
    replace = @config[:replace]

    NfsStore::Import.import_file(
      container.id,
      filename,
      temp_file.path,
      store_user,
      path:,
      skip_existing:,
      replace:
    )
  ensure
    temp_file&.close
    temp_file&.unlink
  end
end
