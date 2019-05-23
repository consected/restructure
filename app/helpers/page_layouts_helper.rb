module PageLayoutsHelper

  def page_layout_panels layout_name: 'master'
    Admin::PageLayout.active.where(app_type_id: current_user.app_type_id, layout_name: layout_name).order(panel_position: :asc)
  end

  def page_layout_panel panel_name: nil, category: nil, layout_name: 'master'
    res = page_layout_panels(layout_name: layout_name)
    res = res.where(panel_name: panel_name) if panel_name
    res = res.select {|r| r.contains&.categories.include? category} if category

    res.first
  end

end
