require 'rails_helper'

RSpec.describe MastersController, type: :controller do
  include MasterSupport
  before_each_login_user
  
  it "sign in through Devise user" do          
    get :new
    expect(response).to render_template 'masters/new'    
  end
  
  describe "GET #index" do
    it "returns jumps to search page when there are no params" do
      get :index
      expect(response).to redirect_to '/masters/search/'
    end
    
    it "searches MSID and returns nothing" do
      get :index, {mode: 'MSID', master: {id: 10000}}
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']).to eq 0
    end
    
    it "searches MSID and matches a result" do
      
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
    
    it "searches Pro Id and returns nothing" do
      get :index, {mode: 'MSID', master: {pro_id: 10000}}
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']).to eq 0
    end
    
    it "searches MSID and matches a result" do
      
      create_master
      m = create_master
      create_master
      
      get :index, {mode: 'MSID', master: {pro_id: m.id}}
      jres = JSON.parse response.body
      expect(jres).to have_key('masters'), "Result not correct: #{jres.to_json}"
      expect(jres['count']).to eq 1
      expect(jres['masters'].length).to eq 1
      expect(jres['masters'].first['id']).to eq m.id
      
    end    
  end

  

end
