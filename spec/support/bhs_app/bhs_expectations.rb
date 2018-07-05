module BhsExpectations

  def expect_bhs_tabs role, master_index: 0
    master_panel = all_master_record_panels[master_index]
    expect(master_panel).not_to be nil
    tabs = master_panel.all('ul.details-tabs li[role="presentation"]')

    if role == :ra
      expect(tabs.length).to eq BhsUi::TabNames.length

      tabs.each do |tab|
        expect(tab.text).to be_in BhsUi::TabNames
        if tab.text.in? BhsUi::DefaultTabs
          expect(tab).to have_css('a[aria-expanded="true"]')
        end
      end
    elsif role == :pi
      expect(tabs.length).to eq 0
    end
  end

end
