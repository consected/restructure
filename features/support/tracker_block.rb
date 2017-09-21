module TrackerBlock
  TrackerTreeBlockCss = '.table.tracker-tree-results'
  def have_tracker_tree_block
    finish_form_formatting
    scroll_to TrackerTreeBlockCss
    have_selector(TrackerTreeBlockCss, visible: true)
  end

  
end

World(TrackerBlock)