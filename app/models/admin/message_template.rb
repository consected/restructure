class Admin::MessageTemplate < ActiveRecord::Base

  self.table_name = 'message_templates'
  include AdminHandler

  validates :message_type, presence: true
  validates :template_type, presence: true

  scope :content_templates, ->{ where template_type: 'content' }
  scope :layout_templates, ->{ where template_type: 'layout' }
  scope :dialog_templates, ->{ where message_type: 'dialog' }

  def self.named name
    where(name: name).first
  end

  def self.message_types
    [:email, :dialog]
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

  def substitute all_content, data: {}, tag_subs: 'span'
    tags = all_content.scan(/{{[0-9a-zA-z_\.]+}}/)

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
      tag_subs_type = tag_subs.split(' ').first
      tag_value = "<#{tag_subs}>#{tag_value}</#{tag_subs_type}>"
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
    def get_tag_value data, tag
      data[tag] || data[tag.to_sym]
    end

end
