class UsersController < ApplicationController

  def update
    current_user.app_type_id = params[:user][:app_type_id]
    current_user.save

    redirect_to '/'
  end

end
