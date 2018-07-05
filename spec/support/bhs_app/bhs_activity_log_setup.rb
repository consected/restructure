module BhsActivityLogSetup

  include FeatureHelper
  include FeatureSupport
  include MasterDataSupport
  include ModelSupport
  include SpecSetup
  include UserActionsSetup

  # Most of the database items are set up in the DB seed. This method just allows for some additional
  # test specific items to be added
  def create_bhs_config
    admin, _ = create_admin

    @app_type = import_config

    create_user_for_login
  end


end
