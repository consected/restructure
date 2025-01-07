Rails.application.config.to_prepare do

  ESignature::Hashing.pepper = (Rails.env.production? ? ENV['FPHS_E_SIGNATURE_PEPPER'] || Settings::SecretKeyBase : 'abc123' )

end
