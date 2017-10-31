class ExternalIdentifiersController < ApplicationController
  before_action :set_external_identifier, only: [:show, :edit, :update, :destroy]

  # GET /external_identifiers
  def index
    @external_identifiers = ExternalIdentifier.all
  end

  # GET /external_identifiers/1
  def show
  end

  # GET /external_identifiers/new
  def new
    @external_identifier = ExternalIdentifier.new
  end

  # GET /external_identifiers/1/edit
  def edit
  end

  # POST /external_identifiers
  def create
    @external_identifier = ExternalIdentifier.new(external_identifier_params)

    if @external_identifier.save
      redirect_to @external_identifier, notice: 'External identifier was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /external_identifiers/1
  def update
    if @external_identifier.update(external_identifier_params)
      redirect_to @external_identifier, notice: 'External identifier was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /external_identifiers/1
  def destroy
    @external_identifier.destroy
    redirect_to external_identifiers_url, notice: 'External identifier was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_external_identifier
      @external_identifier = ExternalIdentifier.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def external_identifier_params
      params.require(:external_identifier).permit(:name, :label, :external_id_attribute, :external_id_view_formatter, :prevent_edit, :pregenerate_ids, :admin_id)
    end
end
