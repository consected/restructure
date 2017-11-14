require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.
#
# Also compared to earlier versions of this generator, there are no longer any
# expectations of assigns and templates rendered. These features have been
# removed from Rails core in Rails 5, but can be added back in via the
# `rails-controller-testing` gem.

RSpec.describe ImportsController, type: :controller do

  include ModelSupport


  # This should return the minimal set of attributes required to create a valid
  # Import. As you add validations to Import, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {

  }

  let(:invalid_attributes) {

  }

  before :all do
    seed_database
    @admin, _ = create_admin
    @user, _ = create_user

  end

  def allow_import
    @user.user_authorizations.create(has_authorization: 'import_csv', current_admin: @admin) unless @user.can?(:import_csv)
  end

  def prevent_import
    @user.user_authorizations.where(has_authorization: 'import_csv').each do |a|
      a.delete! unless @user.can?(:import_csv)
    end
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # ImportsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    before_each_login_user
    it "returns a success response" do
      # Before the user has been allowed to import CSV, ensure they fail
      prevent_import
      expect(@user.can? :import_csv).to be nil

      get :index, {}, valid_session
      expect(response).not_to be_success

      allow_import
      get :index, {}, valid_session
      expect(response).to be_success
    end
  end


  describe "GET #new" do
    before_each_login_user
    it "returns a success response" do
      allow_import
      get :new, {}, valid_session
      expect(response).to be_success
    end
  end



end
