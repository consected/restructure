class UserBaseController < ApplicationController

  include FilterUtils
  include ModelNaming

  before_action :authenticate_user!

end
