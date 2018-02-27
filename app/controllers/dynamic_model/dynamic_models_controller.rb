class DynamicModel::DynamicModelsController < ApplicationController

  # def edit
  #   not_authorized
  # end
  #
  # def update
  #   not_authorized
  # end
  #
  # def new
  #   not_authorized
  # end
  #
  # def create
  #   not_authorized
  # end

  def destroy
    not_authorized
  end

  private

    def secure_params
    end
end
