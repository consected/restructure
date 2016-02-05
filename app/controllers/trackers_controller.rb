class TrackersController < ApplicationController
  include MasterHandler

  before_action :merge_entry_if_exists, only: [:create]

  # A tracker update represents the intent to add a new tracker record for a
  # protocol that is already listed for a master record (person).
  # Since the database triggers handle the rules around updating tracker records,
  # an update must be handled as an insert into the database rather than an update.
  # This ensures that the DB can make the decision which tracker history entry actually
  # appears in the trackers table as the latest item for a specific protocol.  
  def update

    # Start by building a new tracker item that reflects the existing item that 
    # Rails believes is being updated
    new_tracker = @master_objects.build
    new_tracker.protocol = object_instance.protocol
    new_tracker.sub_process = object_instance.sub_process
    new_tracker.protocol_event = object_instance.protocol_event
    new_tracker.event_date = object_instance.event_date
    new_tracker.notes = object_instance.notes
    new_tracker.created_at = object_instance.created_at
    new_tracker.updated_at = DateTime.now
    
    # Now update the newly created item with the submitted data from the user
    res = new_tracker.update(secure_params)
    
    # Assuming the update was successful (all validations were met) then go on to 
    # get the latest item in the tracker to return to the user
    if res
      res = new_tracker.merge_if_exists
      # If there were no errors getting the latest item then show the result
      # Note: we state _merged as nil, since that is what the UI expects to see 
      # for this update mode
      if res
        res._merged = nil
        @tracker = res        
        show
        return
      end    
    else
      # Save the error from the failed update to the @tracker to return to the end user
      @tracker.errors.add new_tracker.errors.first.first
    end
    
    
    logger.warn "Error updating #{human_name}: #{object_instance.errors.inspect}"
    
    render json: object_instance.errors, status: :unprocessable_entity 
    
  end
  
    
  private
  
    def merge_entry_if_exists
      @tracker = @master_objects.build(secure_params)

      res = @tracker.merge_if_exists

      # If the tracker record exists with the requested protocol then return the updated record and show the result
      # Otherwise just follow the default record creation flow
      if res
        @tracker = res
        show
        # prevent additional renders by returning false
        return false
      end
    end

    def secure_params
      params.require(:tracker).permit(:master_id,  :protocol_id, :protocol_event_id, :event_date, :sub_process_id, :user_id, :notes, :item_id, :item_type)
    end
end
