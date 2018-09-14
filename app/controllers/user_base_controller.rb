class UserBaseController < ApplicationController

  protect_from_forgery with: :exception, if: Proc.new { |c| c.params[:user_token].blank? }
  protect_from_forgery with: :null_session, if: Proc.new { |c| !c.params[:user_token].blank? }
  acts_as_token_authentication_handler_for User


  include FilterUtils
  include ModelNaming

  before_action :authenticate_user!

end
