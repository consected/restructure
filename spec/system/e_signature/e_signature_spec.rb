# frozen_string_literal: true

# System spec for GitHub issue #1457.
#
# Exercises the real electronic-signature review/sign UI flow end to end,
# covering the rendering path (ESignature::SignedDocument and the
# e_signature/_document + _notes_block partials) that leaked
# CommonTemplatesHelper#field_options_for memoized options between fields
# before the fix. Two checklist note fields are configured with distinct
# formats (markdown/plain); a regression in the fix would leak one field's
# format onto the other in the rendered review document.

require 'rails_helper'

describe 'Electronically sign a record', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include DynamicModelExpectationsSupport
  include ESignImportConfig

  def set_up_feature
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)

    ESignImportConfig.import_config
    setup_config

    aldef = ActivityLog::PlayerInfoESign.definition
    aldef.current_admin = @admin
    aldef.update_tracker_events

    dmdef = IpaInexChecklist.definition
    dmdef.current_admin = @admin
    # Configure two note fields with distinct formats, matching the real
    # e_signature_manager_spec render-level regression, so the reviewed
    # document's notes actually exercise the field_options_for leak (issue #1457).
    dmdef.options = dmdef.options.sub(
      "default:\n  caption_before:",
      "default:\n  field_options:\n    ix_consent_details:\n      format: markdown\n    ix_not_pro_details:\n      format: plain\n  caption_before:"
    )
    dmdef.save!
    dmdef.update_tracker_events

    @user, @good_password = create_user(create_master: true)
    @good_email = @user.email

    setup_access_as :user
    add_user_to_role 'nfs_store group 600'

    create_master
    setup_access :player_infos, user: @user
    setup_access :dynamic_model__ipa_inex_checklists, user: @user
    @player_info = @master.player_infos.create!(first_name: 'bob', last_name: 'jones')

    SetupHelper.reload_configs
    Rails.application.routes_reloader.reload!
  end

  describe 'show document to sign' do
    before(:all) do
      set_up_feature
    end

    before(:each) do
      validate_setup
      login
    end

    it 'reviews and signs a document with independently-rendered checklist fields' do
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading

      expect(page).to have_css("#master-#{@master.id}")

      find('a#tab-activity-log-player_info_e_sign').click
      finish_page_loading

      # "Setup Data" embeds a new checklist form (matching fixed_checklist_type:
      # test document), which becomes the e_sign reference once saved; "Sign"
      # then generates the review document server-side
      # (ESignature::SignedDocument#generate_doc_from_model).
      setup_button = find('a.add-item-button[data-extra-log-type="setup"]', visible: :all)
      scroll_into_view(setup_button)
      setup_button.click
      finish_page_loading
      finish_form_formatting

      within('form.new_activity_log_player_info_e_sign') do
        %w[
          ix_consent_blank_yes_no ix_not_pro_blank_yes_no ix_age_range_blank_yes_no ix_weight_ok_blank_yes_no
          ix_no_seizure_blank_yes_no ix_no_device_impl_blank_yes_no ix_no_ferromagnetic_impl_blank_yes_no
          ix_diagnosed_sleep_apnea_blank_yes_no ix_diagnosed_heart_stroke_or_meds_blank_yes_no
          ix_chronic_pain_and_meds_blank_yes_no ix_tmoca_score_blank_yes_no ix_no_hemophilia_blank_yes_no
          ix_raynauds_ok_blank_yes_no ix_mi_ok_blank_yes_no ix_bicycle_ok_blank_yes_no
        ].each { |field| set_yes_no_field(field, 'yes') }

        # ix_consent_details is configured with format: markdown (a rich-text editor);
        # ix_not_pro_details is configured with format: plain (a plain textarea).
        edit_rich_text_editor_field('ix_consent_details', 'consent markdown marker')
        fill_in_field('ix_not_pro_details', 'pro plain marker')

        click_on 'Save'
      end
      finish_page_loading

      # A fresh page load is needed here: the "sign" extra_log_type's creatable_if
      # (requires an existing "setup" record) is only re-evaluated on full page load.
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id}"
      dismiss_modal
      finish_page_loading
      find('a#tab-activity-log-player_info_e_sign').click
      finish_page_loading
      sleep 1

      sign_button = find('a.add-item-button[data-extra-log-type="sign"]', visible: :all)
      scroll_into_view(sign_button)
      sign_button.click
      sleep 2
      finish_page_loading
      finish_form_formatting
      sleep 1

      within('form.new_activity_log_player_info_e_sign') { click_on 'Save' }
      finish_page_loading
      sleep 1

      review_link = all('a.start-signature', visible: :all).first
      expect(review_link).not_to be_nil
      signed_record_id = review_link['href'][%r{player_info_e_signs/(\d+)/edit}, 1].to_i
      expect(signed_record_id).to be > 0
      scroll_into_view(review_link)
      review_link.click
      finish_page_loading
      sleep 1
      finish_form_formatting

      expect(page).to have_css('form.edit_activity_log_player_info_e_sign', wait: 10)
      expect(page).to have_css('.e_signature_document_iframe', visible: :all, wait: 10)

      # A regression in CommonTemplatesHelper#field_options_for's memoization (issue
      # #1457) would leak the markdown-formatted field's config onto the plain field,
      # wrapping its marker text in a <p> tag it should not have (and vice versa).
      doc_html = page.evaluate_script(
        "document.querySelector('.e_signature_document_iframe').contentDocument.documentElement.outerHTML"
      )
      expect(doc_html).to include('<p>consent markdown marker</p>')
      expect(doc_html).to include('pro plain marker')
      expect(doc_html).not_to include('<p>pro plain marker</p>')

      within('form.edit_activity_log_player_info_e_sign') do
        select_from_dropdown_field('e_signed_status', 'sign now')
        finish_form_formatting
        expect(page).to have_field('user[password]', visible: true)

        fill_in 'user[password]', with: @good_password
        click_on 'Save'
      end
      finish_page_loading

      signed_record = ActivityLog::PlayerInfoESign.find(signed_record_id)
      expect(signed_record.e_signed_status).to eq 'signed'
      expect(signed_record.e_signed_by).to eq @good_email
    end
  end
end
