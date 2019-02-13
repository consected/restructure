module ESignature
  class Hashing


    # Generate a plain checksum (no salt) to allow verification that documents have not changed
    def self.checksum document
      Digest::SHA2.hexdigest document
    end



  end
end
