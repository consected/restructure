require 'rails_helper'


RSpec.describe AccuracyScoresController, type: :controller do

  include AccuracyScoreSupport
  
  def object_class
    AccuracyScore
  end
  def item
    @accuracy_score
  end

  it_behaves_like 'a standard admin controller'
  

end
