# frozen_string_literal: true

module AccuracyScoreSupport
  include MasterSupport
  def list_valid_attribs
    res = []

    (1001..1005).each do |l|
      res << {
        name: "Score #{l}",
        value: l.to_s,
        disabled: false
      }
    end
    (1006..1010).each do |l|
      res << {
        name: "DisScore #{l}",
        value: l.to_s,
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
        name: nil
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

  def create_item(att = nil, admin = nil)
    att ||= valid_attribs
    att[:current_admin] = admin || @admin
    @accuracy_score = Classification::AccuracyScore.create att
  end
end
