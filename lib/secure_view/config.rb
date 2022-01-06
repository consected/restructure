# frozen_string_literal: true

module SecureView
  #
  # Configuration options for SecureView
  module Config
    mattr_accessor :pdftoppm_path, :pdfinfo_path, :libreoffice_path, :dcmj2pnm_path, :netpbm_path, :pdfgrep_path,
                   :tempdir, :resolution

    def self.setup(block)
      block.call self
    end
  end
end
