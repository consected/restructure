# frozen_string_literal: true

class InfoPagesController < ActionController::Base
  include AppConfigurationsHelper
  include NavHandler
  before_action :setup_navs
  helper_method :body_class_list

  #
  # Show a public or internal page
  # Public pages must have category 'public'
  # Internal app pages will be used if a current user is authenticated and
  # a category 'public' page is not found. In this case, the category will be based
  # on the first portion of the supplied slug, appearing before a double underscore.
  # For example some_study__info_page - some_study will be used as the category
  def show
    id = params[:id].gsub(/[^a-zA-Z0-9\-_]/, '')
    @content = Admin::MessageTemplate.generate_content content_template_name: id, category: :public,
                                                       allow_missing_template: true, markdown_to_html: true

    if current_user && !@content
      pre, page = id.split('__', 2)
      raise FphsException, "Requested info page not valid for #{id}" unless pre.present? && page.present?

      pre = "#{pre} - info-page"
      @content = Admin::MessageTemplate.generate_content content_template_name: page, category: pre,
                                                         allow_missing_template: true, markdown_to_html: true
    end

    unless @content
      @content = '<h1>Page Not Found</h1>'.html_safe
      render :show, status: :not_found, layout: 'public_application'
      return
    end

    unless current_user
      @secondary_navs = []
      @nav_right_plain = '<li><a href="/" class="btn btn-warning public-page-login-btn">login</a></li>'.html_safe
    end

    if params[:display_as] == 'embedded' && params[:display_embed_where] == 'sidebar'
      render partial: 'info_pages/show_in_sidebar', content_type: 'text/html'
    else
      render :show, layout: 'public_application'
    end
  end

  private

  def current_email; end

  def body_class_list
    env_name = Settings::EnvironmentName.gsub(' ', '_').underscore.downcase
    "#{controller_name} #{action_name} #{env_name} #{Rails.env.test? ? 'rails-env-test' : ''}"
  end
end
