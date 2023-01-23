# frozen_string_literal: true

module ApplicationHelper
  #
  # Hyphenated name (singular) of the current controller
  def hyphenated_name
    controller_name.singularize.hyphenate
  end

  #
  # Current email is the user or admin if the user is not logged in
  def current_email
    return nil unless current_user || current_admin

    (current_user || current_admin).email
  end

  #
  # App environment name for body class attribute
  def env_name
    Settings::EnvironmentName.gsub(' ', '_').underscore.downcase
  end

  #
  # An admin_page or user_page class to add to a body class attribute
  def admin_or_user_class
    return 'admin_page' if @is_admin_index

    request.path.start_with?('/admin/') ? 'admin_page' : 'user_page'
  end

  #
  # class name for the body class attribute
  def current_app_type_id_class
    "app-type-id-#{current_user.app_type_id}" if current_user
  end

  #
  # 'class=""' attribute to add to the main body tag
  def body_classes
    class_list = "#{controller_name} #{action_name} #{env_name} #{current_app_type_id_class} #{admin_or_user_class} #{Rails.env.test? ? 'rails-env-test' : ''}"
    " class=\"#{class_list} initial-compiling \"".html_safe
  end

  #
  # Block cancel button for a common template
  def common_inline_cancel_button(class_extras = nil, link_text = nil)
    path_pref = "/masters/#{object_instance.master_id}" unless object_instance.class.no_master_association

    cancel_href = if object_instance.id
                    "#{path_pref}/#{controller_name}/#{object_instance.id}"
                  else
                    "#{path_pref}/#{controller_name}/cancel"
                  end

    button_class = 'glyphicon glyphicon-remove-sign'
    class_extras ||= 'pull-right' unless link_text

    <<~END_HTML
      <a class="show-entity is-cancel-btn show-#{hyphenated_name} #{class_extras} #{link_text ? '' : button_class}" title="cancel" href="#{cancel_href}" data-remote="true" data-#{hyphenated_name}-id="#{object_instance.id}" data-result-target="##{hyphenated_name}-#{@master&.id}-#{@id}" data-template="#{hyphenated_name}-result-template" >#{link_text}</a>
    END_HTML
      .html_safe
  end

  #
  # Generate the edit form id for a common template
  def common_edit_form_id
    "#{hyphenated_name}-edit-form-#{@master&.id}-#{@id}"
  end

  #
  # Options to pass to an edit form for a common template
  def common_edit_form_hash(extras = {})
    res = extras.dup

    res[:remote] = true
    res[:html] ||= {}
    res[:html].merge!(
      'data-result-target' => "##{hyphenated_name}-#{@master&.id}-#{@id}, " \
                              "[form-res-id='#{hyphenated_name}-#{@master&.id}-#{@id}']",
      'data-template' => "#{hyphenated_name}-result-template"
    )
    res
  end

  #
  # Options to pass to an edit form
  def edit_form_hash(extras = {})
    send("#{edit_form_helper_prefix}_edit_form_hash", extras)
  end

  #
  # Generate the edit form id
  def edit_form_id
    send("#{edit_form_helper_prefix}_edit_form_id")
  end

  #
  # Cancel button for a block
  def inline_cancel_button(class_extras = nil, link_text = nil)
    send("#{edit_form_helper_prefix}_inline_cancel_button", class_extras, link_text)
  end

  #
  # Edit icons to appear for each index item
  def admin_edit_controls
    <<~END_HTML
      <div class="admin-edit-controls">
        #{link_to 'cancel', url_for(action: :edit)}
        #{link_to 'admin menu', '/'}
      </div>
    END_HTML
      .html_safe
  end

  #
  # Show a templated dialog script within an edit form
  # The template used will correspond with the created_date of
  # the instance. During creation therefore, the current dialog template
  # will be used. Future edits will show the dialog text that was shown
  # when the instance was created, even if the template has subsequently changed
  # @param [Symbol] key - symbol name of the dialog
  # @param [ActiveRecord::Base] object_instance - the instance underlying the form
  # @param [Hash] dialogs - option configs section specifying dialog_before
  # @return [String] resulting text after generation
  def show_dialog_before(key, object_instance, dialogs)
    return unless dialogs && dialogs[key]

    dname = dialogs[key][:name]
    dlabel = dialogs[key][:label]
    dmsg = Formatter::DialogTemplate.generate_message(dname, object_instance)
    id = "dialog-#{dname}-#{dlabel}".id_hyphenate
    if strip_tags(dmsg).length <= 100 || dlabel.blank?
      <<~END_HTML
        <div class="in-form-dialog collapse" id="#{id}">#{dmsg}</div><div class="dialog-btn-container"><p>#{dmsg}</p></div>
      END_HTML
        .html_safe
    else
      <<~END_HTML
        <div class="in-form-dialog collapse" id="#{id}">#{dmsg}</div>
        <div class="dialog-btn-container">
          <p>#{strip_tags dmsg[0..100]}...</p>
          <a class="btn btn-default in-form-dialog-btn"
             onclick="$('.in-form-dialog').collapse('hide'); $('.dialog-btn-container').show(); $('##{id}').collapse('show'); $(this).parents('.dialog-btn-container').hide();"
          >#{dlabel}</a></div>
      END_HTML
        .html_safe
    end
  end

  #
  # Generate the caption to appear before a field, based on the dynamic extra options
  # Use the <mode>_caption definition based on the following precedence:
  #  - <mode>_caption *mode* has been specified
  #  - new_caption if the current action is 'new'
  #  - edit_caption
  #
  # @param [String] key - field key
  # @param [Hash] captions - defined captions
  # @param [Symbol] mode - one of :new, :edit, :show
  # @return [String] HTML result
  def show_caption_before(key, captions, mode = nil)
    return unless captions && captions[key]

    mode ||= action_name == 'new' ? :new : :edit
    caption = captions[key]
    caption = caption["#{mode}_caption".to_sym] || caption[:caption] || '' if caption.is_a?(Hash)
    if @form_object_instance
      caption = Formatter::Substitution.substitute(caption, data: @form_object_instance, tag_subs: nil)
    end
    caption.html_safe
  end

  #
  # Present the field label for the specified key, based on the dynamic extra options
  def label_for(key, labels, remove = nil, force_default: nil)
    res = labels && labels[key]
    return res if res

    key = key.to_s
    return force_default if force_default

    key = key.sub(remove, '') if remove
    t("field_names.#{key}", default: key.humanize).capitalize
  end

  #
  # A standard set of block size classes for different block styles
  def layout_item_block_sizes
    {
      narrow: 'col-md-6 col-lg-4',
      regular: 'col-md-8 col-lg-6',
      wide: 'col-md-12 col-lg-12',
      e_signature: 'col-md-24 col-lg-18'
    }
  end

  #
  # Cache key for pregenerated partials
  def partial_cache_key(partial)
    u = current_user || current_admin
    auth_type = u.class.name
    if u.is_a? User
      apptype = u.app_type_id
      userrole = Admin::UserRole.where(app_type_id: apptype)
                                .reorder(updated_at: :desc)
                                .limit(1)
                                .first&.updated_at.to_i.to_s

      uac = Admin::UserAccessControl.where(app_type_id: apptype)
                                    .reorder(updated_at: :desc)
                                    .limit(1)
                                    .first&.updated_at.to_i.to_s
    end

    unless @item_updates
      cs = [Admin::MessageTemplate,
            DynamicModel, ActivityLog, ExternalIdentifier,
            Admin::ConfigLibrary, Admin::PageLayout]
      @item_updates = cs.map { |c| c.reorder(updated_at: :desc).limit(1).first&.updated_at.to_i.to_s }.join('-')
    end

    ver = Application.server_cache_version
    "#{partial}-partial2-#{ver}-#{auth_type}-#{u&.id}-#{u&.current_sign_in_at}-#{apptype}-#{@item_updates}-#{userrole}-#{uac}"
  end

  #
  # Generate a checksum version for the partial cache key
  def template_version
    Digest::SHA256.hexdigest partial_cache_key(:loaded)
  end

  #
  # Convert markdown text to html that can be used
  def markdown_to_html(md_text)
    Kramdown::Document.new(md_text).to_html.html_safe if md_text
  end

  #
  # Generate a label with icon attached that indicates a link will open in a new window
  def link_label_open_in_new(label)
    "#{label} <i class=\"glyphicon glyphicon-new-window\"></i>".html_safe
  end

  #
  # Format the *date_time* according to the current user's timezone and preferences
  def current_user_date_time(date_time)
    return unless date_time

    Formatter::TimeWithZone.format date_time, nil, current_user: current_user
  end

  #
  # Generate a block from a plain message template, configured in markdown format
  # @param [String] name - message template name
  # @param [Hash|UserBase|nil] data - data for substitutions
  # @param [Boolean] allow_missing_template - return nil if no matching template found
  # @param [Boolean] markdown_to_html - by default assume the template is markdown and must be converted to html
  # @return [String]
  def template_block(name, data: nil, allow_missing_template: true, markdown_to_html: true)
    data ||= {}
    data = data.attributes if data.respond_to? :attributes
    Admin::MessageTemplate.generate_content content_template_name: name, data: data,
                                            allow_missing_template: allow_missing_template,
                                            markdown_to_html: markdown_to_html
  end
end
