class PlayerInfo < UserBase

  include UserHandler

  BestAccuracyScore = 12
  FollowUpScore = 881
  BirthDateRanks = 1..BestAccuracyScore


  # Allow simple search and compound searches to function
  attr_accessor :contact_data, :younger_than, :older_than, :age

  before_validation :prevent_user_changes, on: :update
  validate :dates_sensible
  validates :source, presence: true, if: :rank?
  before_save :check_college


  def accuracy_rank
    if rank && rank > BestAccuracyScore
      return rank * -1
    elsif !rank
      return nil
    else
      return rank
    end
  end

  def accuracy_score_name
    rank_name
  end

  # Override the standard rank_name, to ensure correct validation, since
  # player ranks are a special case and are defined as AccuracyScore instances
  def rank_name
    PlayerInfo.get_rank_name self.rank
  end
  def self.get_rank_name value
    AccuracyScore.name_for(value)
  end



  protected
    def dates_sensible

      latest_year = Time.now.year+1
      errors.add('start year', "is after #{latest_year}") if start_year && start_year > latest_year
      errors.add('end year', "is after  #{latest_year}") if end_year && end_year > latest_year
      errors.add('start year', 'and end year are not sensible') if end_year && start_year && start_year > end_year
      errors.add('birth date', 'and death date are not sensible') if birth_date && death_date && birth_date > death_date
      errors.add('birth date', 'is after today') if birth_date && birth_date > DateTime.now
      errors.add('death date', 'is after today') if death_date && death_date > DateTime.now
      errors.add('start year', "is more than 30 years after birth date") if start_year && birth_date && start_year > (birth_date + 29.years).year
      errors.add('start year', "is less than 19 years after birth date") if start_year && birth_date && start_year < (birth_date + 19.years).year

      # Make this restriction less strict... Only prevent birth date for 'real' players.
      errors.add('birth date', "must be set if rank is set to \"#{BirthDateRanks}\"") if !birth_date && rank && BirthDateRanks.include?(rank)
    end

    def check_college
      College.create_if_new college, user unless college.blank?
    end

    def prevent_user_changes

      errors.add :source, "can not be updated by a user after a record has been created. Contact an administrator to change this field." if source_changed? && !source_was.nil? && !is_admin?
    end

end
