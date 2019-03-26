module SecureView
  module Config

    # class << self
      mattr_accessor :tempdir, :pdftoppm_path, :pdfinfo_path, :libreoffice_path, :resolution
    # end


    def self.setup block
      block.call self
    end

  end
end
