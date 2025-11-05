require "spec_helper"

RSpec.describe ActiveStorage::CloudTransformations::Variant do
  after do
    ActiveStorage::CloudTransformations.instance_variable_set(:@config, nil)
  end

  describe "with presigned URLs disabled" do
    let(:blob) { fixture("image.jpeg") }

    before do
      ActiveStorage::CloudTransformations.configure do |config|
        config.use_presigned_urls = false
      end
    end

    it "generates a variant using S3 paths" do
      variant = blob.variant(resize_to_limit: [780, 780]).processed
      expect(variant).to be_present
      expect(variant_record_attributes(blob)).to eq \
        [{ id: 1, blob_id: 1, variation_digest: "Ee6bx7pT+nG7AynHq/vtQJ9lPPM=" }]
    end

    it "sends S3 paths without query parameters to crucible" do
      variant_instance = blob.variant(resize_to_limit: [780, 780])

      expect(variant_instance).to receive(:post!) do |endpoint, params, options|
        expect(endpoint).to eq("https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod/image/variant")
        expect(params[:blob_url]).not_to include("?")
        expect(params[:variant_url]).not_to include("?")
        true
      end

      variant_instance.processed
    end
  end

  describe "with presigned URLs enabled" do
    let(:blob) { fixture("image.jpeg") }

    before do
      ActiveStorage::CloudTransformations.configure do |config|
        config.use_presigned_urls = true
        config.presigned_url_expiration = 3600
      end
    end

    it "generates a variant using presigned URLs" do
      variant = blob.variant(resize_to_limit: [780, 780]).processed
      expect(variant).to be_present
      expect(variant_record_attributes(blob)).to eq \
        [{ id: 1, blob_id: 1, variation_digest: "Ee6bx7pT+nG7AynHq/vtQJ9lPPM=" }]
    end

    it "sends presigned URLs with query parameters to crucible" do
      variant_instance = blob.variant(resize_to_limit: [780, 780])

      expect(variant_instance).to receive(:post!) do |endpoint, params, options|
        expect(endpoint).to eq("https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod/image/variant")
        expect(params[:blob_url]).to include("?")
        expect(params[:blob_url]).to include("X-Amz-")
        expect(params[:variant_url]).to include("?")
        expect(params[:variant_url]).to include("X-Amz-")
        true
      end

      variant_instance.processed
    end

    it "uses configured expiration time" do
      variant_instance = blob.variant(resize_to_limit: [780, 780])
      input_blob = variant_instance.blob

      expect(input_blob).to receive(:url).with(expires_in: 3600).and_call_original

      variant_instance.processed
    end
  end

  describe "with per-instance crucible_endpoint" do
    let(:blob) { fixture("image.jpeg") }
    let(:user) { User.create!(endpoint: "https://custom.endpoint.com/prod") }

    before do
      user.avatar.attach(blob)
    end

    it "sends request to the instance's custom crucible_endpoint" do
      variant_instance = user.avatar.blob.variant(resize_to_limit: [780, 780])

      expect(variant_instance).to receive(:post!) do |endpoint, params, options|
        expect(endpoint).to eq("https://custom.endpoint.com/prod/image/variant")
        true
      end

      variant_instance.processed
    end

    it "falls back to global endpoint when record returns nil" do
      user.update!(endpoint: nil)
      variant_instance = user.avatar.blob.variant(resize_to_limit: [780, 780])

      expect(variant_instance).to receive(:post!) do |endpoint, params, options|
        expect(endpoint).to eq("https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod/image/variant")
        true
      end

      variant_instance.processed
    end
  end

  describe "video variants with presigned URLs" do
    let(:blob) { fixture("video.webm") }

    before do
      ActiveStorage::CloudTransformations.configure do |config|
        config.use_presigned_urls = true
      end
    end

    it "generates a video variant using presigned URLs" do
      variant = blob.variant(resize_to_limit: [160, 160]).processed
      expect(variant).to be_present
      expect(variant_record_attributes(blob)).to eq \
        [{ id: 1, blob_id: 1, variation_digest: "yOgRFIhbdlJlVIone9pWesK0TS8=" }]
    end

    it "sends request to video/variant endpoint with presigned URLs" do
      variant_instance = blob.variant(resize_to_limit: [160, 160])

      expect(variant_instance).to receive(:post!) do |endpoint, params, options|
        expect(endpoint).to eq("https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod/video/variant")
        expect(params[:blob_url]).to include("?")
        expect(params[:blob_url]).to include("X-Amz-")
        expect(params[:variant_url]).to include("?")
        expect(params[:variant_url]).to include("X-Amz-")
        true
      end

      variant_instance.processed
    end
  end
end
