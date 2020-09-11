# frozen_string_literal: true

require 'active_record/migration/app_generator'
class UpdateIpaPsInitialScreenings < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_ps_initial_screenings'
    self.fields = %i[form_version placeholder_ps_intro_v1 placeholder_ps_intro_v2 select_is_good_time_to_speak looked_at_website_yes_no placeholder_ps_overview_v1 placeholder_ps_overview_v2 any_questions_blank_yes_no placeholder_ps_details_v1 placeholder_ps_details_v2 same_hotel_yes_no placeholder_select_schedule embedded_report_ipa__ipa_appointments select_schedule placeholder_ps_details_sched_a_v2 placeholder_ps_details_sched_b_v2 select_still_interested placeholder_complete_intro follow_up_date follow_up_time placeholder_not_interested notes]

    ActiveRecord::Base.connection.execute 'DROP VIEW ipa_ops.ipa_view_subject_statuses'

    update_fields
    create_dynamic_model_trigger
  end
end
