class Admin::ActivityLogsController < ApplicationController
  include AdminControllerHandler

  private
    def secure_params
      params.require(:activity_log).permit(:name, :item_type, :rec_type, :action_when_attribute, :field_list, :blank_log_field_list, :disabled)
    end
end
