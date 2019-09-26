module AwsApi
  module S3Handler

    extend ActiveSupport::Concern


    # Create and return an S3 client for reuse
    # @return [Aws::S3::Client]
    def aws_s3_client
      return @aws_s3_client if @aws_s3_client
      @aws_s3_client = Aws::S3::Client.new(region: 'us-east-1')
    end

    # Return the named S3 bucket for use, or if already initialized use the existing bucket
    # @param [bucket_name]
    # @return [Aws::S3::Bucket]
    def s3_bucket name=nil
      return @s3_bucket if name.nil? && @s3_bucket || name == @s3_bucket_name && bucket
      return nil unless name
      @s3_bucket_name = name
      @s3_bucket = aws_s3_client.get_bucket name
    end

    # Upload file data to current @s3_bucket
    # @return [Aws:S3:Object] object uploaded
    def s3_upload_file filename, data, to_bucket: nil, options: nil


      put_info = {
        key: filename,
        body: data,
        bucket: to_bucket || @s3_bucket_name

      }

      put_info.merge! options if options
      obj = aws_s3_client.put_object(put_info)

      obj
    end

    # Check if the redirect file exists in S3
    # @param filename [String] filename
    # @param bucket: [String] optional name of bucket. Will reuse the existing bucket name if one is already being used and the param is nil
    # @return [Boolean]
    def s3_file_exists? filename, bucket: nil
      res = aws_s3_client.head_object(
        key: filename,
        bucket: bucket || @s3_bucket_name
      )
      !!(res && res.etag)
    end

  end
end
