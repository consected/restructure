# frozen_string_literal: true

class InfoPagesController < ActionController::Base
  include AppConfigurationsHelper
  include NavHandler
  before_action :setup_navs
  helper_method :body_class_list

  # public page
  def show
    id = params[:id].gsub(/[^a-zA-Z0-9\-_]/, '')
    @content = Admin::MessageTemplate.generate_content content_template_name: id, category: :public,
                                                       allow_missing_template: true, markdown_to_html: true
    unless @content
      @content = '<h1>Page Not Found</h1>'.html_safe
      render :show, status: 404, layout: 'public_application'
      return
    end

    unless current_user
      @secondary_navs = []
      @nav_right_plain = '<li><a href="/" class="btn btn-warning public-page-login-btn">login</a></li>'.html_safe
    end

    render :show, layout: 'public_application'
  end

  private

  def current_email; end

  def body_class_list
    env_name = Settings::EnvironmentName.gsub(' ', '_').underscore.downcase
    "#{controller_name} #{action_name} #{env_name} #{Rails.env.test? ? 'rails-env-test' : ''}"
  end
end
