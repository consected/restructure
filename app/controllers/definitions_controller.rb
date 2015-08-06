class DefinitionsController < ApplicationController
  before_action :authenticate_user_or_admin!
  
  Available = {"protocol_events" => :selector_collection, "colleges" => :selector_array}.freeze
  
  def show
    
    id = params[:id]
    
    item_selector = available id
    
    return not_found unless item_selector
    
    item = id.classify.constantize
    
    j = item.send(item_selector)
    
    render json: j
    
  end

  
  
  private
  
    def available id
      return nil unless id
      Available[id]
    end
end
