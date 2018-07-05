module BhsActions



    def create_bhs_master
      click_link BhsUi::CreateSubjectRecord
      fill_in BhsUi::BhsIdField, with: '234612'
      click_button BhsUi::NewSubjectCreateButton
      expect_master_record
    end

    def search_player name
      expand_search_with_button BhsUi::SearchPlayer

      if name.present?
        fill_in "Name", with: name
      end
      click_button BhsUi::SearchButton

    end

end
