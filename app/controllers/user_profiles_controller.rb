# frozen_string_literal: true

class UserProfilesController < UserBaseController
  #
  # For a full page load, show the landing page for user profile information.
  # If a resource_name param is specified, return the json for that resource
  def show
    # Need to check that this is a valid resource
    valid_rn = params[:resource_name]
    if valid_rn.present?
      if valid_rn == 'user_preference'
        # This is currently a special case, as it is not a real model. It should be combined with
        # the regular approach when it becomes a model
        resource = current_user.user_preference
      else
        resclass = resource_model(valid_rn)
        resource = resource_from_model(resclass)

      end
      if resource
        resource.current_user = current_user
        render json: { valid_rn => resource }
      else
        path_method = "new_#{resclass.base_route_name}_path"
        redirect_to send(path_method)
      end

    elsif request.format == :html
      @panels = page_layout_panels(layout_name: 'user_profile')
      render 'user_profiles/show'
    else
      render json: { user_profile: resources }
    end
  end

  private

  #
  # Get all the resources for this user's profile, using the same mechanism as we identify resources
  # in views/user_profiles/_resources_panel.html.erb
  # @return [<Type>] <description>
  def resources
    return @resources if @resources

    @resources = {
      user: current_user,
      user_preference: current_user.user_preference
    }

    panel_resource_names.each do |rn|
      m = resource_model(rn)
      next unless m

      res = resource_from_model(m)
      res.current_user = current_user
      @resources[rn.to_sym] = res
    end

    @resources
  end

  def panel_resource_names
    res = page_layout_panels(layout_name: 'user_profile').first&.contains&.resources
    unless res
      raise FphsException,
            'No resources defined in user_profiles panel (requires a contains: resources: <list>)'
    end

    res
  end

  def resource_model(valid_rn)
    Resources::Models.find_by(resource_name: valid_rn.pluralize)&.dig(:model)
  end

  def resource_from_model(resclass)
    resclass.where(user_id: current_user.id).first
  end
end
