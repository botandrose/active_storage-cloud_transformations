module ActiveStorage
  module CloudTransformations
    class Config
      attr_accessor :crucible_endpoint

      def initialize
        @crucible_endpoint = "https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod"
      end
    end
  end
end
