# frozen_string_literal: true

#
# Support user profiles and access to each of the resources that a user can access.
# User profiles are presented based on configurations of Page Layouts with
# the user_profile type. Each panel may have one or more resources specified (by resource name).
# Only resources based on the user's current user access controls (for their current app) are
# presented.
# The implementation gets the full set of defined resources, then for each one pulls the details
# for it from Resources::Models, to generate a *resource info* hash, containing useful information
# for presentation.
class UserProfile
  include PageLayoutsHelper
  attr_accessor :current_user

  def initialize(current_user:)
    self.current_user = current_user
    super()
  end

  #
  # The set of resource info hashes accessible by the current user
  # @return [Array{Hash}]
  def current_user_resource_infos
    res = all_panel_resource_infos
    unless res.present?
      raise FphsException,
            'No resources defined in Page Layout user_profile panel (requires a contains: resources: <list>)'
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
