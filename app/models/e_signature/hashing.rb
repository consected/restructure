module ESignature
  class Hashing

    def self.pepper
      @pepper
    end

    def self.pepper= p
      @pepper = p
    end

    # Generate a plain checksum (no salt) to allow verification that documents have not changed
    def self.checksum document
      Digest::SHA2.hexdigest document
    end

    def self.sign_with salt, content
      raise FphsException.new "salt is blank for signing" unless salt.present?
      raise FphsException.new "pepper is blank for signing" unless pepper.present?
      raise FphsException.new "content is blank for signing" unless content.present?
      Digest::SHA2.hexdigest("#{salt}--#{self.pepper}--#{content}")
    end


  end
end
