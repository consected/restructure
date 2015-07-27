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

  def accuracy_rank
    if rank && rank >= 20  
      return rank * -1 
    else 
      return rank 
    end
  end
  
  def accuracy_score_name 
    res = AccuracyScore.find_by_value(self.rank)
    
    (res ? res.name : nil)
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

      logger.info "Checking #{end_year} and #{start_year}"
      logger.info "Checking #{birth_date} and #{death_date}"

      errors.add(:start_year, 'Start and End years are not sensible') if end_year && start_year && start_year > end_year
      errors.add(:birth_date, 'Birth and Death dates are not sensible') if birth_date && death_date && birth_date > death_date
      errors.add(:birth_date, 'Birth date is after today') if birth_date && birth_date > DateTime.now
      errors.add(:death_date, 'Death date is after today') if death_date && death_date > DateTime.now

    end


  private

    def check_college
      College.create_if_new college
    end
  
  
end
