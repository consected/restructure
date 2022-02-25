# frozen_string_literal: true

#
# Show user profile page and send resource data on request
# The resources to be displayed on a page are set within the Admin panel: Page Layouts
# For testing, create a new Page Layout with the following details:
#   app type: (all)
#   use as: User Profile
#   panel name: user_profile_all
#   panel label: User Profile
#   position: 1
#   yaml options block:
#      contains:
#        categories:
#        resources:
#         - user_preference
#
# Also in Admin: User Access Controls add a new User Access Control:
#   app type: (all)
#   user override: <the username you will test with>
#   resource type: table
#   resource name: Common Master Tables | user_preferences
#   access: update
#
# You may need to restart the server.
# This should allow you to view the user profile from the user icon, and see a tab for
# user preferences.
#
class UserProfilesController < UserBaseController
  helper_method :resources, :all_resources
  #
  # For a full page load, show the landing page for user profile information.
  # If a resource_name param is specified, return the json for that resource
  def show
    user_profile = UserProfile.new(current_user: current_user)

    valid_rn = params[:resource_name]
    if valid_rn.present?
      resource = user_profile.current_user_resource_instance(valid_rn)
      if resource
        resource.current_user = current_user
        render json: { resource.resource_name.to_s.singularize => resource }
      else
        path_method = "new_#{resclass.base_route_name}_path"
        redirect_to send(path_method)
      end

    elsif request.format == :html
      @panels = user_profile.current_user_resource_infos
      render :show
    else
      render json: { user_profile: user_profile.current_user_resource_instances }
    end
  end
end
