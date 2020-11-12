require 'secure_view/config'
module SecureView

  def self.setup &block
    Config.setup block
  end

end
