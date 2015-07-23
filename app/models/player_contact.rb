class PlayerContact < ActiveRecord::Base
  include UserHandler
  
  
  validates :data, email: true, if: :is_email?
  validates :data, phone: true, if: :is_phone?
  
    
  protected
    def is_email?
      rec_type == 'email'
    end
    def is_phone?
      rec_type == 'phone'
    end
end
