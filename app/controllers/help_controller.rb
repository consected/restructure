# frozen_string_literal: true

class HelpController < ApplicationController
  before_action :authenticate_user_or_admin!

  def index
    return not_authorized unless current_user || current_admin

    @library = if current_admin
                 :admin_reference
               elsif current_user
                 :user_reference
               else
                 :guest_reference
               end

    @section = 'main'
    @subsection = 'README'

    show
  end

  # Simple action to refresh the session timeout
  def show
    @library ||= params[:library]
    @section ||= params[:section] || params[:id]
    @subsection ||= params[:subsection]

    redirect_to '/help/' if @library.blank? || @section.blank? || @subsection.blank?

    @library = @library.to_s.gsub(/[^a-zA-Z0-9\-_]/, '_')
    @section = @section.to_s.gsub(/[^a-zA-Z0-9\-_]/, '_')
    @subsection = @subsection.to_s.gsub(/[^a-zA-Z0-9\-_]/, '_')

    render 'help/show'
  end

  private

  def no_action_log
    true
  end
end
