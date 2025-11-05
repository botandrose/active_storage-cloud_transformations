module ActiveStorage
  module CloudTransformations
    class Config
      attr_accessor :crucible_endpoint
      attr_accessor :use_presigned_urls
      attr_accessor :presigned_url_expiration

      def initialize
        @crucible_endpoint = "https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod"
        @use_presigned_urls = false
        @presigned_url_expiration = 3600
      end
    end
  end
end
