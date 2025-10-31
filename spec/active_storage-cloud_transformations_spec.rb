RSpec.describe ActiveStorage::CloudTransformations do
  describe "images" do
    let(:blob) { fixture("image.jpeg") }

    it "generates a variant on the fly" do
      @variant = blob.variant(resize_to_limit: [780, 780]).processed
      expect(variant_record_attributes(blob)).to eq \
        [{ id: 1, blob_id: 1, variation_digest: "Ee6bx7pT+nG7AynHq/vtQJ9lPPM=" }]
      expect(keys).to match_array [blob.key, @variant.key]

      blob.variant(resize_to_limit: [780, 780]).processed

      expect(keys).to match_array [blob.key, @variant.key]
    end
  end

  describe "videos" do
    let(:blob) { fixture("video.webm") }

    describe "variant" do
      it "generates a video variant" do
        @variant = blob.variant(resize_to_limit: [160, 160]).processed
        expect(variant_record_attributes(blob)).to eq \
          [{ id: 1, blob_id: 1, variation_digest: "yOgRFIhbdlJlVIone9pWesK0TS8=" }]
        expect(keys).to match_array [blob.key, @variant.key]

        blob.variant(resize_to_limit: [160, 160]).processed
        expect(keys).to match_array [blob.key, @variant.key]
      end
    end

    describe "preview" do
      it "generates a image preview" do
        @preview = blob.preview(resize_to_limit: [160, 160]).processed
        expect(blob.preview_image.blob.attributes.symbolize_keys).to \
          include(id: 2, filename: "video.png", content_type: "image/png")
        expect(variant_record_attributes(blob.preview_image.blob)).to eq \
          [{ id: 1, blob_id: 2, variation_digest: "LInXE/CAmtFqL2Z1NEWySi52EAQ=" }]
        expect(keys).to match_array [blob.key, blob.preview_image.key, @preview.key]

        blob.preview(resize_to_limit: [160, 160]).processed
        expect(keys).to match_array [blob.key, blob.preview_image.key, @preview.key]
      end
    end
  end
end

