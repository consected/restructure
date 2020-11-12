class ModelReferencesController < UserBaseController

  include ParentHandler

  before_action :init_vars

  before_action :set_parent_item

  def edit
    render partial: 'model_references/edit_form'
  end

  # Allow a model reference to be updated
  # Currently this only allows for a reference to be disabled, althought
  # in the future this could be extended to allow a model reference to be updated
  # to point to a different record instead
  def update
    @model_reference.update!(secure_params)

    render json: {model_reference: @model_reference}
  end


  private
    def init_vars
      instance_var_init :id
      instance_var_init :update_action
    end

    def item_controller
      params[:item_controller]
    end

    def set_parent_item
      @id = params[:id].to_i

      @model_reference = ModelReference.find(@id)
      icn = @model_reference.from_record_type

      raise FphsException.new("Model reference does not match from record item class name #{item_class_name}") unless item_class_name == icn

      @from_item = parent_item_instance

      raise "Failed to get @from_item for #{item_class_name}" unless @from_item
      raise FphsException.new("Model reference from record id does not match the requested item #{params[:item_id]}") unless parent_item_instance.id == @from_item.id


      @master = @from_item.master
      @model_reference.current_user = current_user
      @master.current_user = current_user

      raise "Failed to get @master for #{@from_item.inspect}" unless @master
      @master
    end

    def secure_params
      params.require(:model_reference).permit(:disabled)
    end

    def no_action_log
      false
    end

end
