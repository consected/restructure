class Admin::MessageTemplate < ActiveRecord::Base

  self.table_name = 'message_templates'
  include AdminHandler

  validates :message_type, presence: true
  validates :template_type, presence: true

  scope :content_templates, ->{ where template_type: 'content' }
  scope :layout_templates, ->{ where template_type: 'layout' }
  scope :dialog_templates, ->{ where message_type: 'dialog' }

  def self.named name, type: nil
    res = where(name: name)
    res = res.where(message_type: type) if type
    res.first
  end

  def self.message_types
    [:email, :dialog, :sms]
  end

  def self.template_types
    [:layout, :content]
  end

  def layout_template?
    template_type == 'layout'
  end

  def content_template?
    template_type == 'content'
  end

  def substitute all_content, data: {}, tag_subs: nil
    self.class.substitute all_content, data: data, tag_subs: tag_subs
  end


  # Perform subsititions on the the text, using either a Hash of data or an object item.
  # Provide a tag substitution to be used to enclose the substituted items
  # Substitution text examples:
  # {{select_who}} {{player_info.first_name}} {{user.email}}
  # @param all_content [String] the text containing possible {{something.else}} to be substituted
  # @param data [Hash | UserBase] represent the substitution data with a Hash or a an object instance
  # @param tag_subs [String] for example 'span class="someclass"'
  def self.substitute all_content, data: {}, tag_subs:
    tags = all_content.scan(/{{[0-9a-zA-z_\.]+}}/)

    data = setup_data(data) unless data.is_a? Hash

    tags.each do |tag_container|
      tag = tag_container[2..-3]

      tagpair = tag.split('.', 2)

      d = data
      if tagpair.length == 2
        d = get_tag_value data, tagpair.first
        tag = tagpair.last
      end

      raise FphsException.new "Data does not contain the tag #{tag} or :#{tag}\n#{d ? d : 'data is empty'}" unless d && (d.key?(tag) || d.key?(tag.to_sym))

      tag_value = get_tag_value d, tag
      if tag_subs
        tag_subs_type = tag_subs.split(' ').first
        tag_value = "<#{tag_subs}>#{tag_value}</#{tag_subs_type}>"
      else
        tag_value = tag_value.to_s
      end
      all_content.gsub!(tag_container, tag_value)
    end
    raise FphsException.new "Not all the tags were replaced. This suggests there was an error in the markup." if all_content.scan(/{{.*}}/).length > 0
    all_content
  end

  def generate content_template_name: nil, data: {}

    raise FphsException.new "Must use a layout template to generate from" unless layout_template?
    raise FphsException.new "Must use a hash for data" unless !data || data.is_a?(Hash)

    content_template = Admin::MessageTemplate.active.content_templates.where(name: content_template_name).first
    raise FphsException.new "No content template found with name: #{content_template_name}" unless content_template

    all_content = self.template.sub('{{main_content}}', content_template.template)

    substitute all_content, data: data

    return all_content
  end


  private
    def self.get_tag_value data, tag
      data[tag] || data[tag.to_sym]
    end

    def self.setup_data item
      data = item.attributes.dup

      data[:base_url] = ENV['BASE_URL']

      # if the referenced item has its own referenced item (much like an activity log might), then get it
      if item.respond_to?(:item) && item.item.respond_to?(:attributes)
        data[:item] = item.item.attributes
      end

      if item.respond_to?(:user) && item.user
        data[:user_email] = item.user.email
      end

      if item.respond_to?(:current_user) && item.current_user
        data[:user_email] ||= item.current_user.email
      end

      if item.respond_to?(:master) && item.master.respond_to?(:player_infos) && item.master.player_infos&.first
        data[:player_info] = item.master.player_infos.first.attributes
      end

      if item.respond_to?(:master)
        data[:ids] = item.master.alternative_ids
      end

      data
    end

end
