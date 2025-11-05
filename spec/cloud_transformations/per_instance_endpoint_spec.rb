require "spec_helper"

RSpec.describe "Per-instance crucible endpoint" do
  let(:image_blob) { fixture("image.jpeg") }
  let(:video_blob) { fixture("video.webm") }

  after do
    ActiveStorage::CloudTransformations.instance_variable_set(:@config, nil)
  end

  describe "image variants" do
    context "with custom endpoint" do
      let(:user) { User.create!(endpoint: "https://premium.crucible.com/prod") }

      before do
        user.avatar.attach(image_blob)
      end

      it "uses the user's custom endpoint for variant processing" do
        variant = user.avatar.blob.variant(resize_to_limit: [780, 780])
        endpoint = variant.send(:resolve_crucible_endpoint)

        expect(endpoint).to eq("https://premium.crucible.com/prod")
      end
    end

    context "without custom endpoint" do
      let(:user) { User.create!(endpoint: nil) }

      before do
        user.avatar.attach(image_blob)
      end

      it "falls back to global config endpoint" do
        variant = user.avatar.blob.variant(resize_to_limit: [780, 780])
        endpoint = variant.send(:resolve_crucible_endpoint)

        expect(endpoint).to eq("https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod")
      end
    end

    context "with different endpoints for different users" do
      let(:premium_user) { User.create!(endpoint: "https://premium.crucible.com/prod") }
      let(:standard_user) { User.create!(endpoint: "https://standard.crucible.com/prod") }

      before do
        fixture_path = "spec/support/fixtures/image.jpeg"
        premium_blob = ActiveStorage::Blob.create_and_upload!(
          io: File.new(fixture_path),
          filename: "image.jpeg"
        )
        standard_blob = ActiveStorage::Blob.create_and_upload!(
          io: File.new(fixture_path),
          filename: "image.jpeg"
        )
        premium_user.avatar.attach(premium_blob)
        standard_user.avatar.attach(standard_blob)
      end

      it "uses correct endpoint for each user" do
        premium_variant = premium_user.avatar.blob.variant(resize_to_limit: [780, 780])
        standard_variant = standard_user.avatar.blob.variant(resize_to_limit: [780, 780])

        expect(premium_variant.send(:resolve_crucible_endpoint)).to eq("https://premium.crucible.com/prod")
        expect(standard_variant.send(:resolve_crucible_endpoint)).to eq("https://standard.crucible.com/prod")
      end
    end
  end

  describe "video previews" do
    context "with custom endpoint" do
      let(:user) { User.create!(endpoint: "https://video.crucible.com/prod") }

      before do
        user.avatar.attach(video_blob)
      end

      it "uses the user's custom endpoint for preview processing" do
        preview = user.avatar.blob.preview(resize_to_limit: [160, 160])
        endpoint = preview.send(:resolve_crucible_endpoint)

        expect(endpoint).to eq("https://video.crucible.com/prod")
      end
    end

    context "without custom endpoint" do
      let(:user) { User.create!(endpoint: nil) }

      before do
        user.avatar.attach(video_blob)
      end

      it "falls back to global config endpoint" do
        preview = user.avatar.blob.preview(resize_to_limit: [160, 160])
        endpoint = preview.send(:resolve_crucible_endpoint)

        expect(endpoint).to eq("https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod")
      end
    end
  end

  describe "video variants" do
    context "with custom endpoint" do
      let(:user) { User.create!(endpoint: "https://video-variant.crucible.com/prod") }

      before do
        user.avatar.attach(video_blob)
      end

      it "uses the user's custom endpoint for video variant processing" do
        variant = user.avatar.blob.variant(resize_to_limit: [160, 160])
        endpoint = variant.send(:resolve_crucible_endpoint)

        expect(endpoint).to eq("https://video-variant.crucible.com/prod")
      end
    end
  end
end
