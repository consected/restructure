module ScantronSupport
  include MasterSupport
  def list_valid_attribs
    res = []

    (1..5).each do |l|
      res << {
        scantron_id: rand(999998)+1
      }
    end
    res << {scantron_id: 999999 }
    res << {scantron_id: 1 }
    res
  end

  def list_invalid_attribs
    [
      {
        scantron_id: 1000000
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
      scantron_id: rand(999998) + 1
    }
  end

  def delete_previous_records scantron_id=nil
    whereclause = ''
    whereclause =  "where scantron_id = '#{scantron_id}'" if scantron_id
    ActiveRecord::Base.connection.execute "delete from scantron_history #{whereclause};
    delete from scantrons  #{whereclause};
    "
  end


  def create_item att=nil, master=nil, allow_dup=false

    att ||= valid_attribs
    unless allow_dup
      delete_previous_records att[:scantron_id]
    end


    master ||= create_master
    @scantron = master.scantrons.create! att
  end

end
