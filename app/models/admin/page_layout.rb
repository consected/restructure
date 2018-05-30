class Admin::PageLayout < ActiveRecord::Base

  self.table_name = 'page_layouts'

  include AdminHandler
  include AppTyped

  validates :app_type_id, presence: {scope: :active}
  validates :layout_name, presence: {scope: :active}
  validates :panel_name, presence: {scope: :active}, uniqueness: {scope: [:app_type_id, :layout_name]}
  validates :panel_label, presence: {scope: :active}

  after_initialize :access_options
  before_save :set_position

  OptionTypes = [:contains, :tab, :view_options]
  attr_accessor(*OptionTypes)

  class Contains
    attr_accessor :categories, :resources
    def initialize(params)
      params.each { |key, value| send "#{key}=", value }
    end
  end

  class Tab
    attr_accessor :parent
    def initialize(params)
      params.each { |key, value| send "#{key}=", value }
    end
  end

  class ViewOptions
    attr_accessor :initial_show
    def initialize(params)
      params.each { |key, value| send "#{key}=", value }
    end
  end


  def to_s
    "#{layout_name}: #{panel_label}"
  end

  def access_options

    begin
      return unless options
      o = YAML.load options
      return unless o

      OptionTypes.each do |ot|
        option_type = ot.to_s
        ot_class = "#{self.class.name}::#{option_type.camelize}".constantize
        c = o[option_type]
        self.send("#{option_type}=", ot_class.new(c)) if c
      end

#    rescue
    end
    return o
  end

  protected
    # Force a sensible position, and shuffle items down if necessary
    def set_position
      unless disabled
        if panel_position.nil?
          max_pos = self.class.active.where(app_type_id: app_type_id, layout_name: layout_name).order(panel_position: :desc).limit(1).pluck(:panel_position).first
          self.panel_position = (max_pos || 0) + 1

        else
          panels = self.class.active.where(app_type_id: app_type_id, layout_name: layout_name).order(panel_position: :asc)
          pos = panel_position + 1
          panels.where('id <> ? AND panel_position >= ?', id, panel_position).each do |p|
            p.update! panel_position: pos, current_admin: admin if p.panel_position != pos
            pos += 1
          end
        end
      end
    end


end
