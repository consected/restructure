
fn = ENV['FPHS_VALIDATE_FILENAME']
content = File.read fn
begin
  result = ESignature::SignedDocument.validate_text_document content

rescue ESignature::ESignatureException => e
  if e.message == 'The document prepared for signature has changed'
    result = false
  else
    raise e
  end
end
puts "The document '#{fn}' is #{result ? 'valid' : 'invalid'}"
