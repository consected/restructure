require 'rails_helper'


RSpec.describe AccuracyScoresController, type: :controller do

  include AccuracyScoreSupport
  ObjectClass = AccuracyScore
  def item
    @accuracy_score
  end
  
  ObjectsSymbol = ObjectClass.to_s.underscore.pluralize.to_sym
  
  ObjectSymbol = ObjectClass.to_s.underscore.to_sym
  
  def item_id
    item.to_param
  end
  
  def edit_form
    "#{ObjectsSymbol}/edit"
  end
  
  it_behaves_like 'a standard admin controller'
  

end
