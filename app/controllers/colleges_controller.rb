class CollegesController < ApplicationController
  include AdminControllerHandler


  private
    def secure_params
        params.require(:college).permit(:name, :synonym_for_id, :disabled)
    end
end
