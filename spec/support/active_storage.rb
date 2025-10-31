RSpec.configure do |config|
  config.before do
    bucket.clear!
  end
end

def bucket
  @bucket ||= ActiveStorage::Blob.service.bucket
end

def fixture path
  @fixtures ||= {}
  return @fixtures[path] if @fixtures[path]

  fixture_path = "spec/support/fixtures/#{path}"

  # Generate the key with prefix if configured
  key = if ENV["S3_TEST_PREFIX"].present?
    File.join(ENV["S3_TEST_PREFIX"], ActiveStorage::Blob.generate_unique_secure_token)
  end

  @fixtures[path] = ActiveStorage::Blob.create_and_upload!(
    io: File.new(fixture_path),
    filename: path,
    key: key
  )
end

def variant_record_attributes blob
  blob.variant_records.map(&:attributes).map(&:symbolize_keys)
end

def keys
  prefix = ENV["S3_TEST_PREFIX"]
  bucket.objects(prefix: prefix).map(&:key)
end

