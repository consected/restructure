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
    valid_rn = params[:resource_name]
    if valid_rn.present?
      resource = current_user_resource_instance(valid_rn)
      if resource
        resource.current_user = current_user
        render json: { resource.resource_name.to_s.singularize => resource }
      else
        path_method = "new_#{resclass.base_route_name}_path"
        redirect_to send(path_method)
      end

    elsif request.format == :html
      @panels = current_user_resource_infos
      render :show
    else
      render json: { user_profile: current_user_resource_instances }
    end
  end

  private

  #
  # The set of resource info hashes accessible by the current user
  # @return [Array{Hash}]
  def current_user_resource_infos
    res = all_panel_resource_infos
    unless res.present?
      raise FphsException,
            'No resources defined in user_profiles panel (requires a contains: resources: <list>)'
    end

    res.select do |res_hash|
      resname = res_hash[:resource_name]
      current_user.has_access_to?(:access, :table, resname)
    end
  end

  #
  # Get a set of resource hashes as a hash keyed by resource_name.
  # Each panel definition may have multiple resources listed (as either
  # a resource name, or a hash of {label:, resource_name:})
  # We concatenate all the lists, then get the resource info for each,
  # returning an array
  # @return [Array{Hash}] - array of resource_info hashes
  def all_panel_resource_infos
    all_page_layout_panels
      .map { |panel_def| panel_def.contains&.resources }
      .reduce([], :concat)
      .map { |res| resource_info(res) }
      .compact
  end

  #
  # Get all the resource data for this user's profile as a hash, keyed by the resource name
  # @return [Hash{resource_name => UserBase}]
  def current_user_resource_instances
    return @current_user_resource_instances if @current_user_resource_instances

    current_user.user_preference.current_user = current_user
    @current_user_resource_instances = {
      user: current_user,
      user_preference: current_user.user_preference
    }

    all_panel_resource_infos.each do |res_def|
      resource_name = res_def[:resource_name]
      res_instance = current_user_resource_instance(resource_name)
      next unless res_instance # if the resource is not found, assume that we are building a resource (not persisted).

      res_instance.current_user = current_user
      @current_user_resource_instances[resource_name.to_sym] = res_instance
    end

    @current_user_resource_instances
  end

  #
  # Get all user_profile panel definitions for the current user's app
  # and for those defined for all apps (app_type_id is set to nil in the panel definition).
  # Since results could contain one for the current app type and one for all app types
  # ensure this is unique on panel_name. Those for the current app override those without.
  def all_page_layout_panels
    got_names = {}
    arr = page_layout_panels(layout_name: 'user_profile').to_a
    arr.reject! do |a|
      res = got_names[a.panel_name]
      got_names[a.panel_name] = true
      res
    end

    arr.sort { |a, b| a.panel_position <=> b.panel_position }
  end

  #
  # Get resource model information - either *model_only* or a hash of
  # useful information for the panel
  # @param [String|Hash{label:, resource_name}] valid_rn - valid resource name string or a hash from the panel config
  # @param [true] model_only - return only a model, or by default return a hash
  # @return [UserBase|Hash]
  def resource_info(valid_rn, model_only: nil)
    rn = valid_rn
    if valid_rn.is_a? Hash
      label = valid_rn['label']
      rn = valid_rn['resource_name']
    end

    model = Resources::Models.find_by(resource_name: rn.to_s.pluralize)
    return model&.model if model_only || model&.model.nil?

    {
      model: model.model,
      resource_name: model.resource_name,
      label: label ||  model.model.human_name || rn.humanize.titleize,
      hyphenated_name: model.hyphenated_name,
      type: model.type
    }
  end

  #
  # Get the instance of the resource for the current user
  # @param [String] resource_name
  # @return [UserBase]
  def current_user_resource_instance(resource_name)
    resclass = resource_info(resource_name, model_only: true)
    resclass.find_by(user_id: current_user.id)
  end
end
