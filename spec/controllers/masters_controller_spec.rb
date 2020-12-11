# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MastersController, type: :controller do
  include MasterSupport
  before_each_login_user

  before :each do
    @admin, = ControllerMacros.create_admin

    unless @user.can? :create_master
      Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :create_master, current_admin: @admin, user: @user
    end
  end

  describe 'Create master' do
    it 'asks user if they want to create a new record' do
      get :new
      expect(response).to render_template 'masters/new'
    end

    it 'creates a master record and shows it' do
      ac = Admin::AppConfiguration.where(app_type: @user.app_type, name: 'create master with').first

      if ac
        ac.value = 'player_info'
        ac.current_admin = @admin
        ac.save!
      else
        Admin::AppConfiguration.create! app_type: @user.app_type, name: 'create master with', value: 'player_info', current_admin: @admin
      end

      prev_master = Master.last

      setup_access :player_infos
      setup_access :trackers

      post :create
      @master = Master.last
      expect(@master).not_to eq prev_master
      mid = @master.id
      raise 'No master ID?' unless mid

      expect(response).to redirect_to master_url(mid)

      expect(@master.player_infos.length).to eq 1

      pi = @master.player_infos.first

      expect(pi.birth_date).to be_blank
      expect(pi.rank).to be_blank
    end
  end

  describe 'GET #index' do
    it 'returns jumps to search page when there are no params' do
      get :index
      expect(response).to redirect_to '/masters/search/'
    end

    it 'searches MSID and returns nothing' do
      post :create if Master.count == 0
      mid = (Master.maximum(:msid) || 0) + 1
      get :index, params: { mode: 'MSID', master: { msid: mid }, format: :json }
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}."
      expect(jres['count']['count']).to eq 0
    end

    it 'searches MSID and matches a result' do
      create_master
      m = create_master
      create_master

      get :index, params: { external_id: { msid: m.msid }, format: :json }
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']['count']).to eq 1
      expect(jres['masters'].length).to eq 1
      expect(jres['masters'].first['id']).to eq m.id
    end

    it 'searches Pro Id and returns nothing' do
      get :index, params: { mode: 'MSID', master: { pro_id: 10_000 }, format: :json }
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']['count']).to eq 0
    end

    it 'searches pro id and matches a result' do
      create_master
      m = create_master
      create_master

      get :index, params: { external_id: { pro_id: m.pro_id }, format: :json }
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']['count']).to eq 1
      expect(jres['masters'].length).to eq 1
      expect(jres['masters'].first['id']).to eq m.id
    end
    it 'searches record ID and returns nothing' do
      get :index, params: { mode: 'MSID', master: { id: 1_000_000 }, format: :json }
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']['count']).to eq 0
    end

    it 'searches record ID and matches a result' do
      create_master
      m = create_master
      create_master

      get :index, params: { mode: 'MSID', master: { id: m.id }, format: :json }
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']['count']).to eq 1
      expect(jres['masters'].length).to eq 1
      expect(jres['masters'].first['id']).to eq m.id
    end
  end

  describe 'show that Brakeman security warning is not an issue' do
    it 'attempts to force a create to fail' do
      put :create,  params: { testfail: 'testfail' }

      expect(response).to redirect_to '/masters/new'
    end
  end
end
