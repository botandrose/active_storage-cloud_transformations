require "aws-sdk-s3"

# Set DISABLE_CRUCIBLE_MOCKS=true to run full integration tests against real Lambda and S3
CRUCIBLE_MOCKS_ENABLED = ENV["DISABLE_CRUCIBLE_MOCKS"] != "true"

RSpec.configure do |config|
  if CRUCIBLE_MOCKS_ENABLED
    # Default: Mock Lambda API by patching HTTP calls
    # S3 calls go through normally (uses real AWS credentials)
    config.before do
      mock_crucible_api
    end
  end
end

def mock_crucible_api
  # Stub Net::HTTP to mock Lambda API calls
  # The code uses Net::HTTP.new followed by http.request()
  original_http_new = Net::HTTP.method(:new)

  allow(Net::HTTP).to receive(:new) do |host, port|
    if host.include?("huuabwxpqf.execute-api.us-west-2.amazonaws.com")
      # Return a mocked HTTP instance for Lambda API calls
      mock_http = double("Net::HTTP")
      allow(mock_http).to receive(:use_ssl=) { true }
      allow(mock_http).to receive(:request) do |request|
        # Simulate processing delay (2.1 seconds) to match test expectations
        sleep 2.1

        # Parse the request body to get the variant URL(s)
        request_body = JSON.parse(request.body)
        variant_url = request_body["variant_url"] || request_body["preview_image_variant_url"]
        preview_image_url = request_body["preview_image_url"]

        # If this is a variant/preview request, create the S3 object(s)
        [variant_url, preview_image_url].compact.each do |url|
          # Extract the S3 object key from the URL
          # URL format: https://s3.us-west-2.amazonaws.com/crucible-sandbox/KEY?query=params
          uri = URI.parse(url)
          s3_key = uri.path.split("/", 2)[1] # Remove leading slash and bucket name
          if s3_key
            # Create the S3 object with minimal content
            bucket.put_object(key: s3_key, body: "mock transformed content")
          end
        end

        # Return a successful 201 response
        response = double("response")
        allow(response).to receive(:code).and_return("201")
        allow(response).to receive(:body).and_return("")
        response
      end
      mock_http
    else
      # For non-Lambda calls, use the original Net::HTTP
      original_http_new.call(host, port)
    end
  end
end

def mock_crucible_api_timeout
  # Stub to return 504 Gateway Timeout
  original_http_new = Net::HTTP.method(:new)

  allow(Net::HTTP).to receive(:new) do |host, port|
    if host.include?("huuabwxpqf.execute-api.us-west-2.amazonaws.com")
      mock_http = double("Net::HTTP")
      allow(mock_http).to receive(:use_ssl=) { true }
      allow(mock_http).to receive(:request) do |request|
        response = double("response")
        allow(response).to receive(:code).and_return("504")
        allow(response).to receive(:body).and_return("")
        response
      end
      mock_http
    else
      original_http_new.call(host, port)
    end
  end
end

def mock_crucible_api_failure
  # Stub to return 500 error
  original_http_new = Net::HTTP.method(:new)

  allow(Net::HTTP).to receive(:new) do |host, port|
    if host.include?("huuabwxpqf.execute-api.us-west-2.amazonaws.com")
      mock_http = double("Net::HTTP")
      allow(mock_http).to receive(:use_ssl=) { true }
      allow(mock_http).to receive(:request) do |request|
        response = double("response")
        allow(response).to receive(:code).and_return("500")
        allow(response).to receive(:body).and_return("Internal Server Error")
        response
      end
      mock_http
    else
      original_http_new.call(host, port)
    end
  end
end

