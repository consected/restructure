module ExternalIdentifierSupport

  include MasterSupport




  def list_valid_attribs

    raise "Need a valid name" unless @implementation_table_name
    raise "Need a valid attribute_id" unless @implementation_attr_name
    [
      {
        name: @implementation_table_name,
        label: "test id",
        external_id_attribute: @implementation_attr_name,
        min_id: 1,
        max_id: 99999999,
        disabled: false
      },
      {
        name: 'not_ready_tests',
        label: "test id",
        external_id_attribute: @implementation_attr_name,
        min_id: 1,
        max_id: 99999999,
        disabled: true
      }
    ]


  end

  def list_invalid_attribs
    r = 'junk'
    [
      {
        name: "",
        label: "test id #{r}",
        external_id_attribute: "test_#{r}_id",
        min_id: 1,
        max_id: 99999999,
        disabled: false
      },
      {
        name: @implementation_table_name,
        label: 'abc',
        external_id_attribute: '',
        min_id: 1,
        max_id: 9999,
        disabled: false
      }
    ]
  end

  def list_invalid_update_attribs
    [

      {
        min_id: 1,
        max_id: -19999999
      }
    ]
  end

  def new_attribs
    @new_attribs = {
        label: "test id",
        disabled: true
      }
  end


  def disable_existing_records name, opt={}

    ext=opt[:external_id_attribute]
    admin=opt[:current_admin]

    if name != :all
      r = ExternalIdentifier.where("name=? or external_id_attribute=?", name, ext)
    else
      r = ExternalIdentifier.active
    end
    r.each do |a|
      a.disabled = true
      a.current_admin = admin
      a.save!
    end

  end



  def create_item att=nil, admin=nil, allow_dup=false
    att ||= valid_attribs

    att[:current_admin] = admin||@admin

    disable_existing_records att[:name], att unless allow_dup


    @external_identifier = ExternalIdentifier.create! att
    @external_identifier.update_tracker_events
    @external_identifier
  end

end
