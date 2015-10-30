require 'rails_helper'

RSpec.describe MastersController, type: :controller do
  include MasterSupport
  before_each_login_user
  
  
  describe "Create master" do
    it "asks user if they want to create a new record" do          
      get :new
      expect(response).to render_template 'masters/new'    
    end

    it "creates a master record and shows it" do
      
      post :create
      @master = Master.last
      mid = @master.id
      raise "No master ID?" unless mid
      expect(response).to redirect_to master_url(mid)
      
      expect(@master.player_infos.length).to eq 1
      
      pi = @master.player_infos.first
      
      expect(pi.birth_date).to be_blank
      expect(pi.rank).to be_blank
      
    end
    
  end
  
  describe "GET #index" do
    it "returns jumps to search page when there are no params" do
      get :index
      expect(response).to redirect_to '/masters/search/'
    end
    
    it "searches MSID and returns nothing" do
      mid = Master.maximum(:msid)+1
      get :index, {mode: 'MSID', master: {msid: mid}}
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']).to eq 0
    end
    
    it "searches MSID and matches a result" do
      
      create_master
      m = create_master
      create_master
      
      get :index, {mode: 'MSID', master: {msid: m.msid}}
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']).to eq 1
      expect(jres['masters'].length).to eq 1
      expect(jres['masters'].first['id']).to eq m.id
      
    end
    
    it "searches Pro Id and returns nothing" do
      get :index, {mode: 'MSID', master: {pro_id: 10000}}
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']).to eq 0
    end
    
    it "searches pro id and matches a result" do
      
      create_master
      m = create_master
      create_master
      
      get :index, {mode: 'MSID', master: {pro_id: m.pro_id}}
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']).to eq 1
      expect(jres['masters'].length).to eq 1
      expect(jres['masters'].first['id']).to eq m.id
      
    end    
    it "searches record ID and returns nothing" do
      get :index, {mode: 'MSID', master: {id: 10000}}
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']).to eq 0
    end
    
    it "searches record ID and matches a result" do
      
      create_master
      m = create_master
      create_master
      
      get :index, {mode: 'MSID', master: {id: m.id}}
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']).to eq 1
      expect(jres['masters'].length).to eq 1
      expect(jres['masters'].first['id']).to eq m.id
      
    end    
  end

  describe "show that Brakeman security warning is not an issue" do
    
    it "attempts to force a create to fail" do
      
      post :create, {testfail: 'testfail'}

      expect(response).to redirect_to "/masters/new"
    end
  end
  

end
