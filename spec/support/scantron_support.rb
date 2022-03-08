module ScantronSupport
  include MasterSupport

  # Since scantron definition can be redefined after the initial load of this module,
  # make sure that we use the current version of the model for building tests
  def current_scantron_model
    Resources::Models.find_by(resource_name: 'scantrons').model
  end

  def list_valid_attribs
    res = []

    (1..5).each do |_l|
      res << {
        scantron_id: rand(1..999_998)
      }
    end
    res << { scantron_id: 999_999 }
    res << { scantron_id: 1 }
    res
  end

  def list_invalid_attribs
    [
      {
        scantron_id: 1_000_000
      },
      {
        scantron_id: 'asjfjgsf'
      },
      {
        scantron_id: nil
      },
      {
        scantron_id: ''
      },
      {
        scantron_id: 0
      }
    ]
  end

  def new_attribs
    @new_attribs = {
      scantron_id: rand(1..999_998)
    }
  end

  def delete_previous_records(scantron_id = nil)
    whereclause = ''
    whereclause = "where scantron_id = '#{scantron_id}'" if scantron_id
    ActiveRecord::Base.connection.execute "delete from scantron_history #{whereclause};
    delete from scantrons  #{whereclause};
    "
  end

  def create_item(att = nil, master = nil, allow_dup = false)
    att ||= valid_attribs
    delete_previous_records att[:scantron_id] unless allow_dup

    master ||= create_master
    att[:master] = master
    @scantron = current_scantron_model.create! att
  end
end
