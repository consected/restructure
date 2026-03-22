# frozen_string_literal: true

class Admin::MessageTemplate < ActiveRecord::Base
  self.table_name = 'message_templates'
  include AdminHandler
  include Dynamic::VersionHandler

  validates :message_type, presence: true
  validates :template_type, presence: true

  scope :content_templates, -> { where template_type: 'content' }
  scope :layout_templates, -> { where template_type: 'layout' }
  scope :dialog_templates, -> { where message_type: 'dialog' }
  scope :plain_templates, -> { where message_type: 'plain' }

  #
  # First matching definition matching name and optional type
  # This includes disabled templates. Scope MessageTemplate.active
  # to ensure only the first active item is returned.
  # @param [String|Symbol] name the name to find
  # @param [String|Symbol|nil] type optionally the type to find
  # @return [Admin::MessageTemplate|nil] matching instance
  def self.named(name, type: nil)
    res = where(name:)
    res = res.where(message_type: type) if type
    res.first
  end

  # Valid message types
  def self.message_types
    %i[email dialog sms plain]
  end

  # Valid template types
  def self.template_types
    %i[layout content]
  end

  # @return [True|False] is this a layout template type
  #
  def layout_template?
    template_type == 'layout'
  end

  # @return [True|False] is this a content template type
  #
  def content_template?
    template_type == 'content'
  end

  # Simply calls {Formatter::Substitution.substitute}
  def substitute(all_content, data: {}, tag_subs: nil, ignore_missing: false)
    Formatter::Substitution.substitute all_content, data:, tag_subs:, ignore_missing:
  end

  #
  # When the instance is a layout template, generate substituted text from
  # either a named content template or raw text
  #
  # In the layout template, the text {{main_content}} is replaced with the
  # result of the substituted content template. Any valid tags in the layout
  # template will also be substituted
  #
  # @param [String|Symbol] content_template_name name of content template
  # @param [String] content_template_text raw text to use a template
  # @param [Hash] data simple Hash to pass to #substitute
  # @param [Boolean] ignore_missing defaults to false
  # @param [Symbol|true|false] markdown_to_html - method to call to decide if markdown should be converted to html or literal value
  # @return [String] resulting text
  def generate(content_template_name: nil, content_template_text: nil, data: {}, ignore_missing: false,
               markdown_to_html: :force_markdown_to_html)
    raise FphsException, 'Must use a layout template to generate from' unless layout_template?

    # Generate the content to be embedded, forcing the result to be converted from markdown to HTML
    # if the content template indicates that this is required by calling #force_markdown_to_html on itself
    text = self.class.generate_content(content_template_name:,
                                       content_template_text:,
                                       data:,
                                       ignore_missing:,
                                       no_substitutions: true,
                                       markdown_to_html:)
    all_content = template.sub('{{main_content}}', text)
    substitute all_content, data:, ignore_missing:
  end

  #
  # Generate content using a content template, separately from a containing layout.
  # May be used standalone for generating *plain* type templates for embedding HTML blocks into the UI.
  # @param [String|Symbol] content_template_name name of content template
  # @param [String] content_template_text raw text to use a template
  # @param [Hash] data simple Hash to pass to #substitute
  # @param [Boolean] ignore_missing defaults to false
  # @param [Boolean] no_substitutions defaults to false - set to true to prevent substitution of data
  # @param [Boolean] allow_missing_template - return nil if the named template is missing
  # @param [Boolean | Symbol] markdown_to_html - at the end of processing convert markdown text to HTML.
  #                                              If a method name has been provided (Symbol), call that method to check
  #                                              if the content template should convert markdown to html.
  #                                              Otherwise use the provided value (Truthy | Falsey)
  # @param [String] category- optionally request content from the stated category
  # @return [String] resulting text
  def self.generate_content(content_template_name: nil, content_template_text: nil,
                            data: {}, ignore_missing: false, no_substitutions: false,
                            allow_missing_template: false, markdown_to_html: false,
                            category: nil)
    if content_template_name
      # Lookup the template based on its name
      cond = { name: content_template_name }
      cond[:category] = category if category
      content_template = Admin::MessageTemplate.active.content_templates.find_by(cond)
      return nil if allow_missing_template && !content_template

      raise FphsException, "No content template found with name: #{content_template_name}" unless content_template

      # The raw text is the #template definition
      content_template_text = content_template.template
    elsif !content_template_text
      raise FphsException, 'Either a content_template_name or content_template_text must be specified'
    end

    text = content_template_text.dup
    return unless text

    # If a method name has been provided, call that method to check if the content template should convert markdown to html
    # otherwise just use the value of the argument
    res_md = if markdown_to_html.is_a?(Symbol) && content_template.respond_to?(markdown_to_html)
               content_template.send markdown_to_html
             else
               markdown_to_html
             end

    text = Formatter::Substitution.text_to_html(text) if res_md
    text = Formatter::Substitution.substitute text, data: data, ignore_missing: ignore_missing unless no_substitutions

    text
  end

  #
  # For content templates that are email and were created after 1/1/2003,
  # the template is defined as markdown rather than HTML.
  # @return [true|false]
  def force_markdown_to_html
    template_type.to_s == 'content' &&
      message_type&.to_s&.in?(['email', 'dialog']) &&
      (!persisted? || created_at >= '2023-01-01')
  end
end
