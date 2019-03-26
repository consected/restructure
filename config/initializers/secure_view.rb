require 'secure_view'
SecureView.setup do |config|

  config.tempdir = "/tmp"
  config.pdftoppm_path = "pdftoppm"
  config.pdfinfo_path = 'pdfinfo'
  config.libreoffice_path = 'libreoffice'


  config.resolution = {
    pdf: 150
  }

end
