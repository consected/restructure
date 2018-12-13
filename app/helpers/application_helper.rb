  module ApplicationHelper


    # def object_name
    #   (@object_name || controller_name.singularize)
    # end

    # Namespace safe lower cased name
    # def full_object_name
    #   if controller.class.parent.name != 'Object'
    #     "#{controller.class.parent.name.underscore}__#{object_name}"
    #   else
    #     object_name
    #   end
    # end

    # def object_instance
    #   instance_variable_get("@#{object_name}")
    # end

    def hyphenated_name
      controller_name.singularize.hyphenate
    end


    def current_email
      return nil unless current_user || current_admin
      (current_user || current_admin).email
    end

    def env_name
      (ENV['FPHS_ENV_NAME'] || 'unknown').gsub(' ','_').underscore.downcase
    end

    def admin_or_user_class
      request.path.start_with?('/admin/') ? 'admin_page' : 'user_page'
    end

    def current_app_type_id_class
      "app-type-id-#{current_user.app_type_id}" if current_user
    end

    def body_classes
      " class=\"#{controller_name} #{action_name} #{env_name} #{current_app_type_id_class} #{admin_or_user_class}\"".html_safe
    end

    def common_inline_cancel_button class_extras=nil, link_text=nil

      path_pref = "/masters/#{object_instance.master_id}" unless object_instance.class.no_master_association

      if object_instance.id
        cancel_href = "#{path_pref}/#{controller_name}/#{object_instance.id}"
      else
        cancel_href = "#{path_pref}/#{controller_name}/cancel"
      end

      button_class = "glyphicon glyphicon-remove-sign"
      class_extras ||= "pull-right" unless link_text

      "<a class=\"show-entity show-#{hyphenated_name} #{class_extras} #{link_text ? '' : button_class}\" title=\"cancel\" href=\"#{cancel_href}\" data-remote=\"true\" data-#{hyphenated_name}-id=\"#{object_instance.id}\" data-result-target=\"##{hyphenated_name}-#{@master&.id}-#{@id}\" data-template=\"#{hyphenated_name}-result-template\" >#{link_text}</a>".html_safe
    end

    def common_edit_form_id
      "#{hyphenated_name}-edit-form-#{@master&.id}-#{@id}"
    end

    def common_edit_form_hash extras={}
      res = extras.dup

      res[:remote] = true
      res[:html] ||= {}
      res[:html].merge!("data-result-target" => "##{hyphenated_name}-#{@master&.id}-#{@id}, [form-res-id='#{hyphenated_name}-#{@master&.id}-#{@id}']", "data-template" => "#{hyphenated_name}-result-template")
      res
    end

    def edit_form_hash extras={}
      send("#{edit_form_helper_prefix}_edit_form_hash", extras)
    end

    def edit_form_id
      send("#{edit_form_helper_prefix}_edit_form_id")
    end


    def inline_cancel_button class_extras=nil, link_text=nil
        send("#{edit_form_helper_prefix}_inline_cancel_button", class_extras, link_text)
    end

    def admin_edit_controls
      "<div class=\"admin-edit-controls\">
        #{link_to "cancel", url_for(action: :edit)}
        #{link_to "admin menu", '/'}
        </div>
      ".html_safe

    end

    def show_dialog_before key, object_instance, dialogs
      return unless dialogs && dialogs[key]
      dname = dialogs[key][:name]
      dlabel = dialogs[key][:label]
      dmsg = DialogTemplate.generate_message(dname, object_instance)
      id = "dialog-#{dname}-#{dlabel}".gsub(' ', '-')
      if strip_tags(dmsg).length <= 100 || dlabel.blank?
        "<div class='in-form-dialog collapse' id='#{id}'>#{dmsg}</div><div class='dialog-btn-container'><p>#{dmsg}</p></div>".html_safe
      else
        "<div class='in-form-dialog collapse' id='#{id}'>#{dmsg}</div><div class='dialog-btn-container'><p>#{strip_tags dmsg[0..100]}...</p><a class='btn btn-default in-form-dialog-btn' onclick=\"$('.in-form-dialog').collapse('hide'); $('.dialog-btn-container').show(); $('##{id}').collapse('show'); $(this).parents('.dialog-btn-container').hide();\">#{dlabel}</a></div>".html_safe
      end
    end


    def show_caption_before key, captions
      return unless captions && captions[key]
      caption = captions[key]
      if caption.is_a?(Hash)
        caption = caption[:caption]
      end
      caption = Admin::MessageTemplate.substitute(caption, data: @form_object_instance, tag_subs: 'em class="all_caps"') if @form_object_instance
      caption.gsub("\n","<br/>").html_safe
    end

    def label_for key, labels, remove=nil, force_default: nil
      res = labels && labels[key]
      return res if res

      key = key.to_s
      return force_default if force_default

      key = key.sub(remove, '') if remove
      t("field_names.#{key}", default: key.humanize).capitalize
    end

    def layout_item_block_sizes
      {
        narrow: 'col-md-6 col-lg-4',
        regular: 'col-md-8 col-lg-6',
        wide: 'col-md-12 col-lg-12'
      }
    end
  end
