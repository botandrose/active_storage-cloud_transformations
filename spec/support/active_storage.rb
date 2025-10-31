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

  @fixtures[path] = ActiveStorage::Blob.create_and_upload!(
    io: File.new(fixture_path),
    filename: path
  )
end

def variant_record_attributes blob
  blob.variant_records.map(&:attributes).map(&:symbolize_keys)
end

def keys
  bucket.objects.map(&:key)
end

