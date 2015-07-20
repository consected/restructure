class PlayerContact < ActiveRecord::Base
  include UserHandler
  
  
  validates :data, :allow_blank => true, email: true, if: :is_email?
  validates :data, :allow_blank => true, phone: true, if: :is_phone?
  
    
  protected
    def is_email?
      rec_type == 'email'
    end
    def is_phone?
      rec_type == 'phone'
    end
end
