require 'rails_helper'


RSpec.describe AccuracyScoresController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # AccuracyScore. As you add validations to AccuracyScore, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    {
      name: 'test score',
      value: '7',
      disabled: false
    }
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # AccuracyScoresController. Be sure to keep this updated too.
  let(:valid_session) { {} }
  
  describe "GET #index" do
    before_each_login_admin
    it "assigns all accuracy_scores as @accuracy_scores" do
      accuracy_score = AccuracyScore.create! valid_attributes
      get :index, {}, valid_session
      expect(assigns(:accuracy_scores)).to eq([accuracy_score])
    end
  end

  describe "GET #show" do
    before_each_login_admin
    it "assigns the requested accuracy_score as @accuracy_score" do
      accuracy_score = AccuracyScore.create! valid_attributes
      get :show, {:id => accuracy_score.to_param}, valid_session
      expect(assigns(:accuracy_score)).to eq(accuracy_score)
    end
  end

  describe "GET #new" do
    before_each_login_admin
    it "assigns a new accuracy_score as @accuracy_score" do
      get :new, {}, valid_session
      expect(assigns(:accuracy_score)).to be_a_new(AccuracyScore)
    end
  end

  describe "GET #edit" do
    before_each_login_admin
    it "assigns the requested accuracy_score as @accuracy_score" do
      accuracy_score = AccuracyScore.create! valid_attributes
      get :edit, {:id => accuracy_score.to_param}, valid_session
      expect(assigns(:accuracy_score)).to eq(accuracy_score)
    end
  end

  describe "POST #create" do
    before_each_login_admin
    context "with valid params" do
      it "creates a new AccuracyScore" do
        expect {
          post :create, {:accuracy_score => valid_attributes}, valid_session
        }.to change(AccuracyScore, :count).by(1)
      end

      it "assigns a newly created accuracy_score as @accuracy_score" do
        post :create, {:accuracy_score => valid_attributes}, valid_session
        expect(assigns(:accuracy_score)).to be_a(AccuracyScore)
        expect(assigns(:accuracy_score)).to be_persisted
      end

      it "redirects to the created accuracy_score" do
        post :create, {:accuracy_score => valid_attributes}, valid_session
        expect(response).to redirect_to(AccuracyScore.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved accuracy_score as @accuracy_score" do
        post :create, {:accuracy_score => invalid_attributes}, valid_session
        expect(assigns(:accuracy_score)).to be_a_new(AccuracyScore)
      end

      it "re-renders the 'new' template" do
        post :create, {:accuracy_score => invalid_attributes}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    before_each_login_admin
    context "with valid params" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested accuracy_score" do
        accuracy_score = AccuracyScore.create! valid_attributes
        put :update, {:id => accuracy_score.to_param, :accuracy_score => new_attributes}, valid_session
        accuracy_score.reload
        skip("Add assertions for updated state")
      end

      it "assigns the requested accuracy_score as @accuracy_score" do
        accuracy_score = AccuracyScore.create! valid_attributes
        put :update, {:id => accuracy_score.to_param, :accuracy_score => valid_attributes}, valid_session
        expect(assigns(:accuracy_score)).to eq(accuracy_score)
      end

      it "redirects to the accuracy_score" do
        accuracy_score = AccuracyScore.create! valid_attributes
        put :update, {:id => accuracy_score.to_param, :accuracy_score => valid_attributes}, valid_session
        expect(response).to redirect_to(accuracy_score)
      end
    end

    context "with invalid params" do
      it "assigns the accuracy_score as @accuracy_score" do
        accuracy_score = AccuracyScore.create! valid_attributes
        put :update, {:id => accuracy_score.to_param, :accuracy_score => invalid_attributes}, valid_session
        expect(assigns(:accuracy_score)).to eq(accuracy_score)
      end

      it "re-renders the 'edit' template" do
        accuracy_score = AccuracyScore.create! valid_attributes
        put :update, {:id => accuracy_score.to_param, :accuracy_score => invalid_attributes}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    before_each_login_admin
    it "destroys the requested accuracy_score" do
      accuracy_score = AccuracyScore.create! valid_attributes
      expect {
        delete :destroy, {:id => accuracy_score.to_param}, valid_session
      }.to change(AccuracyScore, :count).by(-1)
    end

    it "redirects to the accuracy_scores list" do
      accuracy_score = AccuracyScore.create! valid_attributes
      delete :destroy, {:id => accuracy_score.to_param}, valid_session
      expect(response).to redirect_to(accuracy_scores_url)
    end
  end

end
