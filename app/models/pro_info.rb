# frozen_string_literal: true

class ProInfo < UserBase
  include UserHandler
  include ViewHandlers::SecondaryInfo

  before_update :prevent_save

  # Handle special functionality and allow simple search and compound searches to function
  attr_accessor :enable_updates, :contact_data, :less_than_career_years, :more_than_career_years

  add_model_to_list

  def data
    "#{first_name} #{last_name}"
  end

  def self.prevent_crosswalk_check
    %i[pro_info_id pro_id]
  end

  protected

  def prevent_save
    instance_var_init :enable_updates
    throw(:abort) unless @enable_updates
  end

  # Override to not track this
  def track_record_update
    true
  end
end
