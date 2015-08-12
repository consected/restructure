class PlayerInfo < ActiveRecord::Base
  
  include UserHandler
  
  BestAccuracyScore = 12
  FollowUpScore = 881
  
  
  # Allow simple search and compound searches to function
  attr_accessor :contact_data, :younger_than, :older_than, :age, :less_than_career_years, :more_than_career_years
  
  validate :dates_sensible
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
  
  def accuracy_score_name_for rank
    AccuracyScore.name_for(rank)        
  end
  
  def accuracy_score_name 
    accuracy_score_name_for self.rank    
  end
 
  def as_json extras={}
    extras[:include] ||= {}
    extras[:include][:item_flags] = {include: [:item_flag_name], methods: [:method_id, :item_type_us]}    
    extras[:methods] ||= []
    extras[:methods] << :accuracy_score_name
    extras[:methods] << :source_name
    super(extras)
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
      errors.add('birth date', "must be set unless rank is set to #{FollowUpScore} - #{accuracy_score_name_for FollowUpScore} ") if !birth_date && rank != FollowUpScore
    end

    def check_college
      College.create_if_new college, user unless college.blank?
    end
  
  
end
