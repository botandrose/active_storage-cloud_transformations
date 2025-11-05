require "spec_helper"

RSpec.describe ActiveStorage::CloudTransformations::Preview do
  let(:blob) { fixture("video.webm") }

  after do
    ActiveStorage::CloudTransformations.instance_variable_set(:@config, nil)
  end

  describe "with presigned URLs disabled" do
    before do
      ActiveStorage::CloudTransformations.configure do |config|
        config.use_presigned_urls = false
      end
    end

    it "generates a preview using S3 paths" do
      preview = blob.preview(resize_to_limit: [160, 160]).processed
      expect(preview).to be_present
      expect(blob.preview_image.blob.attributes.symbolize_keys).to \
        include(id: 2, filename: "video.png", content_type: "image/png")
    end

    it "sends S3 paths without query parameters to crucible" do
      preview_instance = blob.preview(resize_to_limit: [160, 160])

      expect(preview_instance).to receive(:post!) do |endpoint, params|
        expect(endpoint).to eq("https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod/video/preview")
        expect(params[:blob_url]).not_to include("?")
        expect(params[:preview_image_url]).not_to include("?")
        expect(params[:preview_image_variant_url]).not_to include("?")
        true
      end

      preview_instance.processed
    end
  end

  describe "with presigned URLs enabled" do
    before do
      ActiveStorage::CloudTransformations.configure do |config|
        config.use_presigned_urls = true
        config.presigned_url_expiration = 3600
      end
    end

    it "generates a preview using presigned URLs" do
      preview = blob.preview(resize_to_limit: [160, 160]).processed
      expect(preview).to be_present
      expect(blob.preview_image.blob.attributes.symbolize_keys).to \
        include(id: 2, filename: "video.png", content_type: "image/png")
      expect(variant_record_attributes(blob.preview_image.blob)).to eq \
        [{ id: 1, blob_id: 2, variation_digest: "LInXE/CAmtFqL2Z1NEWySi52EAQ=" }]
    end

    it "sends presigned URLs with query parameters to crucible" do
      preview_instance = blob.preview(resize_to_limit: [160, 160])

      expect(preview_instance).to receive(:post!) do |endpoint, params|
        expect(endpoint).to eq("https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod/video/preview")
        expect(params[:blob_url]).to include("?")
        expect(params[:blob_url]).to include("X-Amz-")
        expect(params[:preview_image_url]).to include("?")
        expect(params[:preview_image_url]).to include("X-Amz-")
        expect(params[:preview_image_variant_url]).to include("?")
        expect(params[:preview_image_variant_url]).to include("X-Amz-")
        true
      end

      preview_instance.processed
    end

    it "uses configured expiration time" do
      preview_instance = blob.preview(resize_to_limit: [160, 160])
      input_blob = preview_instance.blob

      expect(input_blob).to receive(:url).with(expires_in: 3600).and_call_original

      preview_instance.processed
    end
  end

  describe "with per-instance crucible_endpoint" do
    let(:user) { User.create!(endpoint: "https://custom-video.endpoint.com/prod") }

    before do
      user.avatar.attach(blob)
    end

    it "sends request to the instance's custom crucible_endpoint" do
      preview_instance = user.avatar.blob.preview(resize_to_limit: [160, 160])

      expect(preview_instance).to receive(:post!) do |endpoint, params|
        expect(endpoint).to eq("https://custom-video.endpoint.com/prod/video/preview")
        true
      end

      preview_instance.processed
    end

    it "falls back to global endpoint when record returns nil" do
      user.update!(endpoint: nil)
      preview_instance = user.avatar.blob.preview(resize_to_limit: [160, 160])

      expect(preview_instance).to receive(:post!) do |endpoint, params|
        expect(endpoint).to eq("https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod/video/preview")
        true
      end

      preview_instance.processed
    end
  end

  describe "reprocess" do
    before do
      ActiveStorage::CloudTransformations.configure do |config|
        config.use_presigned_urls = true
      end
    end

    it "reprocesses an existing preview" do
      preview = blob.preview(resize_to_limit: [160, 160]).processed
      expect(preview).to be_present

      preview.reprocess
      expect(blob.preview_image.blob).to be_present
    end
  end
end
