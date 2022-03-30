module AwsApi
  module S3Handler
    extend ActiveSupport::Concern

    class_methods do
      def s3_aws_region
        AwsApiSetup.s3_aws_region
      end
    end

    # Create and return an S3 client for reuse
    # @return [Aws::S3::Client]
    def aws_s3_client
      return @aws_s3_client if @aws_s3_client

      @aws_s3_client = Aws::S3::Client.new(region: self.class.s3_aws_region)
    end

    # Return the named S3 bucket for use, or if already initialized use the existing bucket
    # @param [bucket_name]
    # @return [Aws::S3::Bucket]
    def s3_bucket(name = nil)
      return @s3_bucket if name.nil? && @s3_bucket || name == @s3_bucket_name && bucket
      return nil unless name

      @s3_bucket_name = name
      @s3_bucket = aws_s3_client.get_bucket name
    end

    # Upload the file data to current @s3_bucket
    # @param filename [String] filename
    # @param data [String|Byte[]]
    # @param bucket: [String] optional name of bucket. Will reuse the existing bucket name if one is already being used and the param is nil
    # @return [Aws:S3:Object] object uploaded
    def s3_upload_file(filename, data, to_bucket: nil, options: nil)
      put_info = {
        key: filename,
        body: data,
        bucket: to_bucket || @s3_bucket_name

      }

      put_info.merge! options if options
      aws_s3_client.put_object(put_info)
    end

    # Check if the file exists in S3
    # @param filename [String] filename
    # @param bucket: [String] optional name of bucket. Will reuse the existing bucket name if one is already being used and the param is nil
    # @return [Boolean]
    def s3_file_exists?(filename, bucket: nil)
      res = aws_s3_client.head_object(
        key: filename,
        bucket: bucket || @s3_bucket_name
      )
      !!(res && res.etag)
    end

    # Get the whole file from S3
    # @param filename [String] filename
    # @param bucket: [String] optional name of bucket. Will reuse the existing bucket name if one is already being used and the param is nil
    # @return [Boolean]
    def s3_file_get_all(filename, bucket: nil)
      res = aws_s3_client.get_object(
        key: filename,
        bucket: bucket || @s3_bucket_name
      )
      res.body.read
    end

    # List S3 bucket
    # @param bucket: [String] optional name of bucket. Will reuse the existing bucket name if one is already being used and the param is nil\
    # @param prefix: [String] optional. Limits the response to keys that begin with the specified prefix.
    # @param start_after: [String] optional key to start after. S3 starts listing after this specified key. If a prefix is set but
    # => it doesn't appear in key, it will be added automatically
    # @return [Boolean]
    def s3_list(bucket: nil, prefix: nil, start_after: nil)
      cond = {
        bucket: bucket || @s3_bucket_name
      }

      cond[:prefix] = prefix if prefix
      if start_after
        start_after = prefix + start_after if prefix && !start_after.start_with?(prefix)
        cond[:start_after] = start_after
      end

      res = aws_s3_client.list_objects_v2(cond)

      res.contents
    end
  end
end
