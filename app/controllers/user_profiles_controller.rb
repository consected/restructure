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
  helper_method :resources, :resource_names
  #
  # For a full page load, show the landing page for user profile information.
  # If a resource_name param is specified, return the json for that resource
  def show
    # Need to check that this is a valid resource
    valid_rn = params[:resource_name]
    if valid_rn.present?
      resclass = resource_model(valid_rn)
      resource = resource_from_model(resclass)
      if resource
        resource.current_user = current_user
        render json: { valid_rn => resource }
      else
        path_method = "new_#{resclass.base_route_name}_path"
        redirect_to send(path_method)
      end

    elsif request.format == :html
      @panels = user_profile_panels
      render :show
    else
      render json: { user_profile: resource_data }
    end
  end

  private

  def resources
    resource_names.map { |resource_name| [resource_name, resource_model(resource_name.pluralize)] }.to_h
  end

  #
  # Get all the resource data for this user's profile
  # @return [<Type>] <description>
  def resource_data
    return @resource_data if @resource_data

    current_user.user_preference.current_user = current_user

    @resource_data = {
      user: current_user,
      user_preference: current_user.user_preference
    }

    resource_names.each do |resource_name|
      model = resource_model(resource_name.pluralize)
      next unless model

      resource = resource_from_model(model)
      next unless resource # if the resource is not found, assume that we are building a resource (not persisted).

      resource.current_user = current_user
      @resource_data[resource_name.to_sym] = resource
    end

    @resource_data
  end

  def resource_names
    res = user_profile_panels.map { |p| p.contains&.resources }.reduce([], :concat)
    unless res.present?
      raise FphsException,
            'No resources defined in user_profiles panel (requires a contains: resources: <list>)'
    end

    res.select do |resname|
      current_user.has_access_to?(:access, :table, resname.pluralize)
    end
  end

  #
  # Get panels - since this could represent one for the current app type and one for all app types
  # (app_type_id is set to nil) then remove items where the panel_name has already been seen
  def user_profile_panels
    got_names = {}
    arr = page_layout_panels(layout_name: 'user_profile').to_a
    arr.reject! do |a|
      res = got_names[a.panel_name]
      got_names[a.panel_name] = true
      res
    end

    arr.sort { |a, b| a.panel_position <=> b.panel_position }
  end

  def resource_model(valid_rn)
    Resources::Models.find_by(resource_name: valid_rn.pluralize)&.dig(:model)
  end

  def resource_from_model(resource_class)
    resource_class.find_by(user_id: current_user.id)
  end
end
