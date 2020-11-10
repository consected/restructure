module BhsActions



    def create_bhs_master
      bhs_id = BhsAssignment.order(bhs_id: :desc).first&.bhs_id || 234612
      bhs_id += 1
      click_link BhsUi::CreateSubjectRecord
      fill_in BhsUi::BhsIdField, with: bhs_id
      click_button BhsUi::NewSubjectCreateButton
      expect_master_record

    end

    def search_player name
      expand_search_with_button BhsUi::SearchPlayer

      if name.present?
        fill_in "Name", with: name
      end
      click_button BhsUi::SearchButton

      expect(page).to have_css('.results-panel')

    end

end
