class Admin::PageLayout < ActiveRecord::Base

  self.table_name = 'page_layouts'

  include AdminHandler

  belongs_to :app_type
  belongs_to :admin

  validates :app_type_id, presence: {scope: :active}
  validates :layout_name, presence: {scope: :active}
  validates :panel_name, presence: {scope: :active}, uniqueness: {scope: [:app_type_id, :layout_name]}
  validates :panel_label, presence: {scope: :active}

  before_save :set_position

  def to_s
    "#{layout_name}: #{panel_label}"
  end


  protected
    # Force a sensible position, and shuffle items down if necessary
    def set_position
      unless disabled
        if panel_position.nil?
          max_pos = self.class.active.where(layout_name: layout_name).order(panel_position: :desc).limit(1).pluck(:panel_position).first
          self.panel_position = (max_pos || 0) + 1

        else
          panels = self.class.active.where(layout_name: layout_name).order(panel_position: :asc)
          pos = panel_position + 1
          panels.where('panel_position >= ?', panel_position).each do |p|
            p.update! panel_position: pos, current_admin: admin
            pos += 1
          end
        end
      end
    end


end
