# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe 'admin page' do
    include MasterSupport
    before_each_login_admin

    it 'shows the admin menu page' do
      get :index, params: {}
      expect(response).to have_http_status :success
      expect(response).to render_template 'pages/index'
    end
  end

  describe 'user page' do
    include MasterSupport
    before_each_login_user

    it 'redirects to search page' do
      get :index, params: {}
      expect(response).to redirect_to '/masters'
    end
  end
end
