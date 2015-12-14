require 'rails_helper'


RSpec.describe Admin::AccuracyScoresController, type: :controller do

  include AccuracyScoreSupport
  
  def object_class
    AccuracyScore
  end
  def item
    @accuracy_score
  end

  before(:all) do    
    @path_prefix = "/admin"
  end  
  
  it_behaves_like 'a standard admin controller'
  

end
