RSpec.describe ActiveStorage::CloudTransformations do
  describe "images" do
    let(:blob) { fixture("image.jpeg") }

    it "generates a variant on the fly" do
      expect(->{
        @variant = blob.variant(resize_to_limit: [780, 780]).processed
      }).to take_more_than(2.seconds)
      expect(variant_record_attributes(blob)).to eq \
        [{ id: 1, blob_id: 1, variation_digest: "Ee6bx7pT+nG7AynHq/vtQJ9lPPM=" }]
      expect(keys).to match_array [blob.key, @variant.key]

      expect(->{
        blob.variant(resize_to_limit: [780, 780]).processed
      }).to take_less_than(1.second)

      expect(keys).to match_array [blob.key, @variant.key]
    end

    it "it can fire and forget for quick eager variant queueing" do
      expect(->{
        @variant = blob.variant(resize_to_limit: [780, 780]).process(wait: false)
      }).to take_less_than(2.seconds)
      expect(variant_record_attributes(blob)).to eq \
        [{ id: 1, blob_id: 1, variation_digest: "Ee6bx7pT+nG7AynHq/vtQJ9lPPM=" }]
      expect(keys).to match_array [blob.key]
      sleep 10
      expect(keys).to match_array [blob.key, @variant.image.blob.key]

      expect(->{
        blob.variant(resize_to_limit: [780, 780]).processed
      }).to take_less_than(1.second)
      expect(keys).to match_array [blob.key, @variant.image.blob.key]
    end
  end

  describe "videos" do
    let(:blob) { fixture("video.webm") }

    describe "variant" do
      it "generates a video variant" do
        expect(->{
          @variant = blob.variant(resize_to_limit: [160, 160]).processed
        }).to take_more_than(2.seconds)
        expect(variant_record_attributes(blob)).to eq \
          [{ id: 1, blob_id: 1, variation_digest: "yOgRFIhbdlJlVIone9pWesK0TS8=" }]
        expect(keys).to match_array [blob.key, @variant.key]

        expect(->{
          blob.variant(resize_to_limit: [160, 160]).processed
        }).to take_less_than(2.seconds)
        expect(keys).to match_array [blob.key, @variant.key]
      end

      it "it can fire and forget for quick eager variant queueing" do
        expect(->{
          @variant = blob.variant(resize_to_limit: [160, 160]).process(wait: false)
        }).to take_less_than(2.seconds)
        expect(variant_record_attributes(blob)).to eq \
          [{ id: 1, blob_id: 1, variation_digest: "yOgRFIhbdlJlVIone9pWesK0TS8=" }]
        expect(keys).to match_array [blob.key]
        sleep 10
        expect(keys).to match_array [blob.key, @variant.image.blob.key]

        expect(->{
          blob.variant(resize_to_limit: [160, 160]).processed
        }).to take_less_than(2.seconds)
        expect(keys).to match_array [blob.key, @variant.image.blob.key]
      end
    end

    describe "preview" do
      it "generates a image preview" do
        expect(->{
          @preview = blob.preview(resize_to_limit: [160, 160]).processed
        }).to take_more_than(2.seconds)
        expect(blob.preview_image.blob.attributes.symbolize_keys).to \
          include(id: 2, filename: "video.png", content_type: "image/png")
        expect(variant_record_attributes(blob.preview_image.blob)).to eq \
          [{ id: 1, blob_id: 2, variation_digest: "LInXE/CAmtFqL2Z1NEWySi52EAQ=" }]
        expect(keys).to match_array [blob.key, blob.preview_image.key, @preview.key]

        expect(->{
          blob.preview(resize_to_limit: [160, 160]).processed
        }).to take_less_than(2.seconds)
        expect(keys).to match_array [blob.key, blob.preview_image.key, @preview.key]
      end

      it "it can fire and forget for quick eager variant queueing" do
        expect(->{
          @preview = blob.preview(resize_to_limit: [160, 160]).process(wait: false)
        }).to take_less_than(2.seconds)
        expect(blob.preview_image.blob.attributes.symbolize_keys).to \
          include(id: 2, filename: "video.png", content_type: "image/png")
        expect(variant_record_attributes(blob.preview_image.blob)).to eq \
          [{ id: 1, blob_id: 2, variation_digest: "LInXE/CAmtFqL2Z1NEWySi52EAQ=" }]
        expect(keys).to match_array [blob.key]
        sleep 10
        expect(blob.preview_image.blob.attributes.symbolize_keys).to \
          include(id: 2, filename: "video.png", content_type: "image/png")
        expect(variant_record_attributes(blob.preview_image.blob)).to eq \
          [{ id: 1, blob_id: 2, variation_digest: "LInXE/CAmtFqL2Z1NEWySi52EAQ=" }]
        expect(keys).to match_array [blob.key, blob.preview_image.key, @preview.key]

        expect(->{
          blob.preview(resize_to_limit: [160, 160]).processed
        }).to take_less_than(2.seconds)
        expect(keys).to match_array [blob.key, blob.preview_image.key, @preview.key]
      end
    end
  end
end

