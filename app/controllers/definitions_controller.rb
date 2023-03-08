# frozen_string_literal: true

class DefinitionsController < ApplicationController
  before_action :init_vars
  before_action :authenticate_user_or_admin!

  Available = {
    'protocol_events' => :selector_collection,
    'protocols' => :selector_collection,
    'sub_processes' => :selector_collection,
    'colleges' => :selector_array,
    'accuracy_scores' => :selector_collection,
    'external_links' => :selector_collection,
    'users' => :active_id_name_list,
    'user_roles' => :active_role_names
    # ,
    # 'general_selections' => :selector_with_config_overrides
  }.freeze

  def show
    def_type = params[:id]
    j = get_def def_type

    render json: j unless performed?
  end

  def create
    dts = params[:names].split(',')
    j = {}
    dts.each do |dt|
      j[dt] = get_def(dt)
    end

    render json: j unless performed?
  end

  private

  def get_def(def_type)
    item_selector = available def_type
    # We will return a 404 if either the def_type requested by a user is nil, or
    # the def_type does not appear in the Available list
    # This protects against insecure requests
    return not_found unless item_selector

    item = Admin::AdminBase.class_from_name @def_class # .classify.constantize
    item.send(item_selector, @filter)
  end

  def no_action_log
    true
  end

  def init_vars
    instance_var_init :filter
  end

  # This both looks up the selector method to use, and protects against insecure
  # user-generated requests to access unexpected methods and classes
  def available(def_type)
    return nil unless def_type

    def_type_split = def_type.split('-')
    filters = def_type_split[1..-1]
    @filter = {}
    filters.each do |filter|
      if filter
        fs = filter.split('+')
        @filter[fs.first] = fs.last
      end
    end
    @filter.symbolize_keys!
    @filter = nil unless @filter.first

    @def_class = def_type_split.first
    Available[@def_class]
  end
end
