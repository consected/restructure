class AddressesController < ApplicationController
  include MasterHandler

  before_action :set_address, only: [:show]


  def show
    
    
    a = {address: @address.as_json}
    
    
    logger.info a.as_json
    render json: a
  end

  def new
    @address = @master.addresses.build
    render partial: 'edit_form'
    end

  def edit
    render partial: 'edit_form'
  end

  def create
    logger.info "Starting create: #{Address.to_s.underscore.pluralize.to_sym}"
    @address = @master.addresses.build(address_params)

    if @address.save
      show
    else
      logger.warn "Error creating address: #{@address.errors.inspect}"
      render json: @address.errors, status: :unprocessable_entity     
    end
  end

  def update
    if @address.update(address_params)
      show
    else
      logger.warn "Error updating player info: #{@address.errors.inspect}"
      render json: @address.errors, status: :unprocessable_entity 
    end
  end

  def destroy
    not_authorized
  end

  private
    def set_address
      return if params[:id] == 'cancel'
      @address = Address.find(params[:id])
    end
 
    def address_params
      params.require(:address).permit(:master_id, :street, :street2, :street3, :city, :state, :zip, :source, :rank, :rec_type, :user_id)
    end
end
