# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MfaController, type: :controller do
  include UserSupport

  def post_with_token(path, params, token = nil)
    post path, params: params.merge('authenticity_token' => (token || retrieve_authenticity_token)), xhr: true
  end

  describe 'MFA requests must be valid' do
    it 'fails for anything other than a post to step1 requesting a JSON format' do
      get :step1, params: { resource_type: 'user', user: { email: 'abc', password: 'def' } }
      expect(response).to have_http_status :not_found
      # Regular HTML request
      post :step1, params: { resource_type: 'user' }
      expect(response).to have_http_status :not_found

      expect_to_be_bad_route(get: '/mfa')
      expect_to_be_bad_route(get: '/mfa/1')
      expect_to_be_bad_route(post: '/mfa')
      expect(post: '/mfa/step1', format: :json).to be_routable
    end

    it 'fails if the resource_type (user or admin) is not provided' do
      post :step1, params: {}, format: :json
      expect(response).to have_http_status :unprocessable_entity

      post :step1, params: { resource_type: '' }, format: :json
      expect(response).to have_http_status :unprocessable_entity
    end

    it 'fails if the user username and password are not provided' do
      post :step1, params: { resource_type: 'user' }, format: :json
      expect(response).to have_http_status :unprocessable_entity

      post :step1, params: { resource_type: 'user', user: 'bad' }, format: :json
      expect(response).to have_http_status :unprocessable_entity

      post :step1, params: { resource_type: 'user', user: { email: '', password: '' } }, format: :json
      expect(response).to have_http_status :unprocessable_entity

      post :step1, params: { resource_type: 'user', user: { email: 'abc', password: '' } }, format: :json
      expect(response).to have_http_status :unprocessable_entity

      post :step1, params: { resource_type: 'user', user: { email: '', password: 'def' } }, format: :json
      expect(response).to have_http_status :unprocessable_entity

      post :step1, params: { resource_type: 'admin', user: { email: 'badrestype', password: 'def' } }, format: :json
      expect(response).to have_http_status :unprocessable_entity
    end

    it 'fails if the admin username and password are not provided' do
      post :step1, params: { resource_type: 'admin' }, format: :json
      expect(response).to have_http_status :unprocessable_entity

      post :step1, params: { resource_type: 'admin', admin: 'bad' }, format: :json
      expect(response).to have_http_status :unprocessable_entity

      post :step1, params: { resource_type: 'admin', admin: { email: '', password: '' } }, format: :json
      expect(response).to have_http_status :unprocessable_entity

      post :step1, params: { resource_type: 'admin', admin: { email: 'abc', password: '' } }, format: :json
      expect(response).to have_http_status :unprocessable_entity

      post :step1, params: { resource_type: 'admin', admin: { email: '', password: 'def' } }, format: :json
      expect(response).to have_http_status :unprocessable_entity

      post :step1, params: { resource_type: 'admin', user: { email: 'badrestype', password: 'def' } }, format: :json
      expect(response).to have_http_status :unprocessable_entity
    end

    it 'returns a JSON result if the username and password are provided' do
      post :step1, params: { resource_type: 'user', user: { email: 'abc', password: 'def' } }, format: :json
      expect(response).to have_http_status :ok
      expect(JSON.parse(response.body)).to have_key 'need_2fa'
    end
  end

  describe 'step1 check if user needs to use MFA to login' do
    let :good_user_password do
      @good_user_password
    end

    let :test_user do
      return @user if @user

      @user, @good_user_password = create_user
      @user
    end

    context '2FA disabled on server' do
      before :all do
        change_setting('TwoFactorAuthDisabledForUser', true)
      end

      it 'says 2FA is not required if the user is not found, to avoid bad actors using the endpoint to find valid users' do
        post :step1, params: { resource_type: 'user', user: { email: 'abc', password: 'def' } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => false
      end

      it 'says 2FA is not required if the user is found but the password is incorrect' do
        post :step1, params: { resource_type: 'user', user: { email: test_user.email, password: 'badpassword' } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => false
      end

      it 'says 2FA is not required if the user is found' do
        post :step1, params: { resource_type: 'user', user: { email: test_user.email, password: good_user_password } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => false
      end
    end

    context '2FA enabled on server' do
      before :all do
        change_setting('TwoFactorAuthDisabledForUser', false)
      end

      it 'says 2FA is required if the user is not found, to avoid bad actors using the endpoint to find valid users' do
        post :step1, params: { resource_type: 'user', user: { email: 'abc', password: 'def' } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => true
      end

      it 'says 2FA is required if the user password is incorrect' do
        post :step1, params: { resource_type: 'user', user: { email: test_user.email, password: 'bad password' } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => true
      end

      it 'says 2FA is required if the user has set up 2FA' do
        test_user.update! otp_required_for_login: true
        post :step1, params: { resource_type: 'user', user: { email: test_user.email, password: good_user_password } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => true
      end

      it 'says 2FA is not required if the user has not yet set up 2FA' do
        test_user.update! otp_required_for_login: false
        post :step1, params: { resource_type: 'user', user: { email: test_user.email, password: good_user_password } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => false
      end
    end
  end

  describe 'step1 check if admin needs to use MFA to login' do
    let :good_admin_password do
      @good_admin_password
    end

    let :test_admin do
      return @admin if @admin

      @admin, @good_admin_password = create_admin
      @admin
    end

    context '2FA disabled on server' do
      before :all do
        change_setting('TwoFactorAuthDisabledForAdmin', true)
      end

      it 'says 2FA is not required if the admin is not found, to avoid bad actors using the endpoint to find valid admins' do
        post :step1, params: { resource_type: 'admin', admin: { email: 'abc', password: 'def' } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => false
      end

      it 'says 2FA is not required if the admin is found but the password is incorrect' do
        post :step1, params: { resource_type: 'admin', admin: { email: test_admin.email, password: 'badpassword' } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => false
      end

      it 'says 2FA is not required if the admin is found' do
        post :step1, params: { resource_type: 'admin', admin: { email: test_admin.email, password: good_admin_password } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => false
      end
    end

    context '2FA enabled on server' do
      before :all do
        change_setting('TwoFactorAuthDisabledForAdmin', false)
      end

      it 'says 2FA is required if the admin is not found, to avoid bad actors using the endpoint to find valid admins' do
        post :step1, params: { resource_type: 'admin', admin: { email: 'abc', password: 'def' } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => true
      end

      it 'says 2FA is required if the admin has set up 2FA' do
        test_admin.update! otp_required_for_login: true
        post :step1, params: { resource_type: 'admin', admin: { email: test_admin.email, password: good_admin_password } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => true
      end

      it 'says 2FA if the password is incorrect, even if the admin has not yet set up 2FA' do
        test_admin.update! otp_required_for_login: false
        post :step1, params: { resource_type: 'admin', admin: { email: test_admin.email, password: 'bad password' } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => true
      end

      it 'says 2FA is not required if the admin has not yet set up 2FA' do
        test_admin.update! otp_required_for_login: false
        post :step1, params: { resource_type: 'admin', admin: { email: test_admin.email, password: good_admin_password } }, format: :json
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eq 'need_2fa' => false
      end
    end
  end
end
