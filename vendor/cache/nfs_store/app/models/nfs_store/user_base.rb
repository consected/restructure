module NfsStore
  class UserBase < ActiveRecord::Base

    self.abstract_class = true

    def allows_current_user_access_to? perform, with_options=nil
      true
    end

  end
end
