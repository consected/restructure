# frozen_string_literal: true

class PlayerInfo < UserBase
  include UserHandler
  include ViewHandlers::Subject

  FollowUpScore = 881
  BirthDateRanks = (1..BestAccuracyScore).freeze

  # Allow simple search and compound searches to function
  attr_accessor :contact_data, :younger_than, :older_than, :age

  before_validation :prevent_user_changes, on: :update
  before_save :check_college
  add_model_to_list

  def self.human_name
    'Person'
  end

  def data
    "#{first_name} #{last_name}"
  end

  def self.permitted_params
    %i[master_id first_name last_name middle_name nick_name birth_date death_date start_year end_year college source
       rank notes]
  end

  protected

  def dates_sensible
    latest_year = Time.now.year + 1
    errors.add('start year', "is after #{latest_year}") if start_year && start_year > latest_year
    errors.add('end year', "is after  #{latest_year}") if end_year && end_year > latest_year
    errors.add('start year', 'and end year are not sensible') if end_year && start_year && start_year > end_year
    errors.add('death date', 'is after today') if death_date && death_date > DateTime.now
    if start_year && birth_date && start_year > (birth_date + 29.years).year
      errors.add('start year', 'is more than 30 years after birth date')
    end
    if start_year && birth_date && start_year < (birth_date + 19.years).year
      errors.add('start year', 'is less than 19 years after birth date')
    end

    # Make this restriction less strict... Only prevent birth date for 'real' players.
    if !birth_date && rank && BirthDateRanks.include?(rank)
      errors.add('birth date', "must be set if rank is set to '#{BirthDateRanks}'")
    end

    super
  end

  def check_college
    Classification::College.create_if_new college, user unless college.blank?
  end

  # Validation method to prevent a user changing the source attribute after it has already been set
  # If the current_admin has been set on the associated master this validation is skipped
  def prevent_user_changes
    return unless source_changed? && !source_was.nil? && !current_admin?

    errors.add :source, 'can not be updated by a user after a record has been created. ' \
                        'Contact an administrator to change this field.'
  end
end
