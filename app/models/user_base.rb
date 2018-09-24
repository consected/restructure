# Common abstract class for all user authenticated models to subclass.
# Follows the sensible Rails 5 convention, allow us to incorporate common, essential methods into
# all user models. Previously we had duplication across similar but different model concerns. This allows
# us to pull the essentials in one time only
class UserBase < ActiveRecord::Base

  self.abstract_class = true

  belongs_to :user
  include HandlesUserBase

  def model_data_type
    :default
  end

end
