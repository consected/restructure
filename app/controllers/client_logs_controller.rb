# frozen_string_literal: true

class ClientLogsController < ApplicationController
  protect_from_forgery with: :exception, if: proc { |c| c.params[:user_token].blank? }
  protect_from_forgery with: :null_session, if: proc { |c| !c.params[:user_token].blank? }
  acts_as_token_authentication_handler_for User
  before_action :authenticate_user!

  include AppExceptionHandler

  def create
    log_message params[:msg], params[:error], params[:details]
  end

  protected

  def log_message(msg, error, details)
    user_id = current_user&.id
    admin_id = current_admin&.id
    msg ||= 'error'
    info = {
      message: msg,
      main: error,
      backtrace: details,
      user_id: user_id,
      admin_id: admin_id
    }
    if user_id
      if Rails.env.production?
        Admin::ExceptionLog.create info
      else
        puts "CLIENT ERROR\n#{info.to_yaml}"
      end
    end
    render plain: 'OK', status: 200
  end

  def no_action_log
    true
  end
end
