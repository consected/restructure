class PlayerInfo < ActiveRecord::Base
  
  include UserHandler
  
  
  # This is here to link the player_info record to the matched pro_info record from the master list
  # Although the player_info does not formally belong to the pro_info, the pro_info_id foreign 
  # key is on the player_info table, and therefore requires a belongs_to association
  # belongs_to :pro_info, inverse_of: :player_info
 
  # Allow simple search to function
  attr_accessor :contact_data, :younger_than, :older_than, :age, :less_than_career_years, :more_than_career_years
  
  before_save :check_college
  
  validate :dates_sensible

  BestAccuracyScore = 12
  FollowUpScore = 881
  
  def accuracy_rank    
    if rank && rank > BestAccuracyScore  
      return rank * -1 
    elsif !rank
      return nil
    else 
      return rank 
    end
  end
  
  def accuracy_score_name_for rank
    res = AccuracyScore.find_by_value(self.rank)    
    (res ? res.name : nil)
  end
  
  def accuracy_score_name 
    accuracy_score_name_for self.rank
    
  end
 
  def as_json extras={}
    extras[:include] ||= {}
    extras[:include][:item_flags] = {include: [:item_flag_name], methods: [:method_id, :item_type_us]}    
    extras[:methods] ||= []
    extras[:methods] << :accuracy_score_name
    super(extras)
  end
  
  protected
    def dates_sensible
      
      latest_year = Time.now.year+1
      errors.add('start year', "is after #{latest_year}") if start_year && start_year > latest_year
      errors.add('end year', "is after  #{latest_year}") if end_year && end_year > latest_year
      errors.add('start and end years', 'are not sensible') if end_year && start_year && start_year > end_year
      errors.add('birth and death dates', 'are not sensible') if birth_date && death_date && birth_date > death_date
      errors.add('birth date', 'is after today') if birth_date && birth_date > DateTime.now
      errors.add('death date', 'is after today') if death_date && death_date > DateTime.now
      errors.add('start year', "is more than 30 years after birth date") if start_year && birth_date && start_year > (birth_date + 29.years).year
      errors.add('start year', "is less than 19 years after birth date") if start_year && birth_date && start_year < (birth_date + 19.years).year
      errors.add('birth date', "must be set unless rank is set to #{FollowUpScore} - #{accuracy_score_name_for FollowUpScore} ") if !birth_date && rank != FollowUpScore
    end


  private

    def check_college
      College.create_if_new college, user
    end
  
  
end
