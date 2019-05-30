class ClientLogsController < ApplicationController

  protect_from_forgery with: :exception, if: Proc.new { |c| c.params[:user_token].blank? }
  protect_from_forgery with: :null_session, if: Proc.new { |c| !c.params[:user_token].blank? }
  acts_as_token_authentication_handler_for User
  before_action :authenticate_user!

  include AppExceptionHandler

  def create
    log_message params[:msg], params[:error], params[:details]
  end

  protected

    def log_message msg, error, details
      user_id = current_user&.id
      admin_id = current_admin&.id
      Admin::ExceptionLog.create message: (msg || 'error'), main: error, backtrace: details, user_id: user_id, admin_id: admin_id if Rails.env.production? && user_id
      render text: 'OK', status: 200
    end

    def no_action_log
      true
    end
end
