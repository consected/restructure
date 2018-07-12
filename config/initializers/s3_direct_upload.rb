S3DirectUpload.config do |c|
  if Rails.env.development?
    c.access_key_id = ENV["S3_ACCESS_KEY"]       # your access key id
    c.secret_access_key = ENV["S3_SECRET_KEY"]   # your secret access key
    c.bucket = ENV["S3_BUCKET_NAME"]              # your bucket name
    c.region = nil             # region prefix of your bucket url. This is _required_ for the non-default AWS region, eg. "s3-eu-west-1"
    c.url = nil                # S3 API endpoint (optional), eg. "https://#{c.bucket}.s3.amazonaws.com/"
  end
  if Rails.env.production?
    c.access_key_id = ENV["S3_ACCESS_KEY"]       # your access key id
    c.secret_access_key = ENV["S3_SECRET_KEY"]   # your secret access key
    c.bucket = ENV["S3_BUCKET_NAME"]              # your bucket name
    c.region = nil             # region prefix of your bucket url. This is _required_ for the non-default AWS region, eg. "s3-eu-west-1"
    c.url = nil                # S3 API endpoint (optional), eg. "https://#{c.bucket}.s3.amazonaws.com/"
  end
end
