module Formatter
  class DialogTemplate
    #
    # Generate dialog text from a named dialog template.
    # The template used will correspond with the created_date of
    # the *item* instance. During creation therefore, the current dialog template
    # will be used. Future edits will show the dialog text that was shown
    # when the instance was created, even if the template has subsequently changed

    # @param [String] name - plain text dialog template name
    # @param [ActiveRecord::Base] item - instance item
    # @return [String] resulting dialog text after generation
    def self.generate_message(name, item)
      mt = Admin::MessageTemplate.active.dialog_templates
                                 .order(id: :desc)
                                 .find_by(name: name)
      raise FphsException, "Dialog template '#{name}' not found" unless mt

      # Get the versioned message template, or use the
      # current one if there is no corresponding version
      versioned_mt = mt.versioned(item.created_at) || mt

      all_content = versioned_mt.template.dup
      all_content = Formatter::Substitution.text_to_html(all_content)

      mt.substitute all_content, data: item, tag_subs: 'em class="all_caps"', ignore_missing: :show_tag
    end
  end
end
