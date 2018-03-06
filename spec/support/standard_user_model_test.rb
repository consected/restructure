require 'set'
shared_examples 'a standard user model' do

  describe "sends updates to tracker" do

    before :all do
      seed_database
      create_admin
      create_user
      uacs = UserAccessControl.active.where app_type: @user.app_type, resource_type: :table

      uacs.each do |u|
        u.access = 'create'
        u.current_admin = @admin
        u.save!
      end

      unless @user.has_access_to? :read, :general, :app_type
        UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :general, resource_name: :app_type, current_admin: @admin
      end
    end

    it "records a creation" do

      create_user

      item = create_item

      ts = item.trackers

      expect(ts.length).to eq 1

      t = ts.first

      expect(t.record_type).to eq item.class.name
      expect(t.record_id).to eq item.id

      expect(t.protocol_name.downcase).to eq 'updates'
      expect(t.sub_process_name.downcase).to eq 'record updates'
      expect(t.protocol_event_id).not_to be_nil,  "expected a good event, but got #{t.protocol_event_id}"
      expect(t.event_name.downcase).to eq("created #{item.item_type.humanize.downcase}")

    end
    it "records an update" do
      create_user

      item = create_item

      res = item.update(new_attribs)

      expect(res).to be true

      ts = item.trackers

      expect(ts.length).to eq 1

      t = ts.first

      expect(t.record_type).to eq item.class.name
      expect(t.record_id).to eq item.id

      expect(t.protocol_name.downcase).to eq 'updates'
      expect(t.sub_process_name.downcase).to eq 'record updates'
      expect(t.protocol_event_id).not_to be_nil,  "expected a good event, but got #{t.protocol_event_id}"
      expect(t.event_name.downcase).to eq("updated #{item.item_type.humanize.downcase}")


    end
  end

end
