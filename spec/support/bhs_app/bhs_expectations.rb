module BhsExpectations

  def expect_bhs_tabs role, master_index: 0
    master_panel = all_master_record_panels[master_index]
    expect(master_panel).not_to be nil
    tabs = master_panel.all('ul.details-tabs li[role="presentation"]')

    if role == :ra
      #puts tabs.map(&:text)
      expect(tabs.length).to eq BhsUi::TabNames.length

      tabs.each do |tab|
        expect(tab.text).to be_in BhsUi::TabNames
        tab_a = tab.find('a')
        if tab.text.in? BhsUi::DefaultTabs
          expect(tab_a[:class]).not_to include 'collapsed'
        else
          expect(tab_a[:class]).to include 'collapsed'
        end
      end
    elsif role == :pi
      res = Admin::AppConfiguration.value_for :hide_player_tabs, @user
      expect(res).to eq 'true'
      expect(tabs.length).to eq 0
    end
  end

end
