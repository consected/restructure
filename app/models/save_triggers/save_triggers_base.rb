class SaveTriggers::SaveTriggersBase

  attr_accessor :config, :user, :item

  def initialize config, item
    @config = config
    raise FphsException.new "save_trigger configuration must be a Hash" unless config.is_a? Hash
    @item = item
    raise FphsException.new "save_trigger item must be set" unless item
    @user = item.master.current_user
    raise FphsException.new "save_trigger item master user must be set" unless item.master && item.master.current_user
  end

end
