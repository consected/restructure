Rails.application.config.to_prepare do

  ESignature::Hashing.pepper = (Rails.env.production? ? ENV['FPHS_E_SIGNATURE_PEPPER'] || ENV['FPHS_RAILS_SECRET_KEY_BASE'] : 'abc123' )

end
