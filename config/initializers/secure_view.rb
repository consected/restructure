require 'secure_view'
SecureView.setup do |config|
  config.tempdir = '/tmp'
  config.pdftoppm_path = 'pdftoppm'
  config.pdfinfo_path = 'pdfinfo'
  config.libreoffice_path = 'libreoffice'
  config.dcmj2pnm_path = 'dcmj2pnm'
  config.netpbm_path = 'jpegtopnm'
  config.pdfgrep_path = 'pdfgrep'

  config.resolution = {
    pdf: 150
  }
end
