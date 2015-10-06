class DefinitionsController < ApplicationController
  before_action :authenticate_user_or_admin!
  
  Available = {"protocol_events" => :selector_collection, "protocols" => :selector_collection, "sub_processes" => :selector_collection, "colleges" => :selector_array}.freeze
   
  def show
    
    def_type = params[:id]
    
    item_selector = available def_type
    # We will return a 404 if either the def_type requested by a user is nil, or
    # the def_type does not appear in the Available list
    # This protects against insecure requests
    return not_found unless item_selector
    
    item = def_type.classify.constantize
    
    j = item.send(item_selector)
    
    render json: j
    
  end

  
  
  private
  
    # This both looks up the selector method to use, and protects against insecure 
    # user-generated requests to access unexpected methods and classes
    def available def_type
      return nil unless def_type
      Available[def_type]
    end
end
