class Admin::ActivityLogsController < ApplicationController
  include AdminControllerHandler

  private
    def secure_params
      params.require(:activity_log).permit(:name, :item_type, :rec_type, :disabled)
    end
end

