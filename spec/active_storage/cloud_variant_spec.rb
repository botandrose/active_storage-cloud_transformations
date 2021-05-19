def bucket
  @bucket ||= ActiveStorage::Blob.service.bucket
end

def fixture path
  fixture_path = "spec/support/fixtures/#{path}"
  ActiveStorage::Blob.create_and_upload!({
    io: File.new(fixture_path),
    filename: path,
  })
end

def variant_record_attributes blob
  blob.variant_records.map(&:attributes).map(&:symbolize_keys)
end

def keys
  bucket.objects.map(&:key)
end

RSpec.describe ActiveStorage::CloudVariant do
  before do
    bucket.clear!
  end

  describe "images" do
    let(:blob) { fixture("image.jpeg") }

    it "generates a variant on the fly" do
      variant = blob.variant(resize_to_limit: [780, 780]).processed
      expect(variant_record_attributes(blob)).to eq \
        [{ id: 1, blob_id: 1, variation_digest: "Ee6bx7pT+nG7AynHq/vtQJ9lPPM=" }]
      expect(keys).to match_array [blob.key, variant.key]
    end

    it "it can fire and forget for quick eager variant queueing" do
      variant = blob.variant(resize_to_limit: [780, 780]).process(wait: false)
      expect(variant_record_attributes(blob)).to eq \
        [{ id: 1, blob_id: 1, variation_digest: "Ee6bx7pT+nG7AynHq/vtQJ9lPPM=" }]
      expect(keys).to match_array [blob.key]
      sleep 10
      expect(keys).to match_array [blob.key, variant.image.blob.key]
    end
  end

  describe "videos" do
    let(:blob) { fixture("video.webm") }

    describe "variant" do
      it "generates a video variant" do
        variant = blob.variant(resize_to_limit: [160, 160]).processed
        expect(variant_record_attributes(blob)).to eq \
          [{ id: 1, blob_id: 1, variation_digest: "yOgRFIhbdlJlVIone9pWesK0TS8=" }]
        expect(keys).to match_array [blob.key, variant.key]
      end

      it "it can fire and forget for quick eager variant queueing" do
        variant = blob.variant(resize_to_limit: [160, 160]).process(wait: false)
        expect(variant_record_attributes(blob)).to eq \
          [{ id: 1, blob_id: 1, variation_digest: "yOgRFIhbdlJlVIone9pWesK0TS8=" }]
        expect(keys).to match_array [blob.key]
        sleep 10
        expect(keys).to match_array [blob.key, variant.image.blob.key]
      end
    end

    xdescribe "preview" do
      it "generates a image preview" do
        variant = blob.preview(resize_to_limit: [160, 160]).processed
        expect(blob.preview_image.blob.attributes.symbolize_keys).to \
          include(id: 2, filename: "video.png", content_type: "image/png")
        expect(variant_record_attributes(blob.preview_image.blob)).to eq \
          [{ id: 1, blob_id: 2, variation_digest: "yAq1z9pRmPsEnaRMLDdqMl9fhYM=" }]
        expect(keys).to match_array [blob.key, blob.preview_image.blob.key, variant.key]
      end

      it "it can fire and forget for quick eager variant queueing" do
        blob.preview(resize_to_limit: [160, 160]).process(wait: false)
        assert_image_preview
        assert_variant
        assert_no_s3_presence
        wait
        assert_image_preview
        assert_variant
        assert_s3_presence
      end
    end
  end
end

