class ManageUsersController < ApplicationController

  before_action :authenticate_admin!
  before_action :set_manage_user, only: [:show, :edit, :update, :destroy]


  
  # GET /manage_users
  # GET /manage_users.json
  def index
    @users = User.all
    
  end

  # GET /manage_users/1
  # GET /manage_users/1.json
  def show
  end

  # GET /manage_users/new
  def new
    @user = User.new
    
  end

  # GET /manage_users/1/edit
  def edit
  end

  # POST /manage_users
  # POST /manage_users.json
  def create
    @user = User.new(manage_user_params)
    
    res = @user.save
      
    respond_to do |format|
      if res
        format.html { render :show, notice: 'Manage user was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
    
    
  end

  # PATCH/PUT /manage_users/1
  # PATCH/PUT /manage_users/1.json
  def update
    if params[:gen_new_pw] == "1"
      
      @user.force_password_reset 
      logger.info "Force password reset"
    end
    
    
    respond_to do |format|
      if @user.update(manage_user_params)
        format.html { render :show, notice: 'Manage user was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /manage_users/1
  # DELETE /manage_users/1.json
  def destroy
    @manage_user.destroy
    respond_to do |format|
      format.html { redirect_to manage_users_url, notice: 'Manage user was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  
    # Use callbacks to share common setup or constraints between actions.
    def set_manage_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def manage_user_params
      params.require(:user).permit(:email)
    end
end
