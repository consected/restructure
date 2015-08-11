module AccuracyScoreSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    
    (1..5).each do |l|
      res << {
        name: "Score #{l}",
        value: "val#{l}",
        disabled: false
      }
    end
    (1..5).each do |l|
      res << {
        name: "DisScore #{l}",
        value: "disval#{l}",
        disabled: true
      }
    end
    res
  end
  
  def list_invalid_attribs
    [
      {
        name: nil
      },
      {
        value: nil
      }
    ]
  end
  
  def list_invalid_update_attribs
    [      
      {
        value: 'anynewvalue'
      },
      {
        value: nil
      }
    ]
  end  
  
  def new_attribs
    @new_attribs = {
      name: 'alt 1'
    }
  end
  
  
  
  def create_item att=nil, admin=nil
    att ||= valid_attribs    
    att[:current_admin] = admin||@admin    
    @accuracy_score = AccuracyScore.create! att
  end
  
end
