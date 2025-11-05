require "spec_helper"

RSpec.describe ActiveStorage::CloudTransformations::Config do
  describe "#initialize" do
    subject { described_class.new }

    it "sets default crucible_endpoint" do
      expect(subject.crucible_endpoint).to eq("https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod")
    end

    it "sets use_presigned_urls to false by default" do
      expect(subject.use_presigned_urls).to eq(false)
    end

    it "sets presigned_url_expiration to 3600 by default" do
      expect(subject.presigned_url_expiration).to eq(3600)
    end
  end

  describe "configuration" do
    after do
      ActiveStorage::CloudTransformations.instance_variable_set(:@config, nil)
    end

    it "allows configuring crucible_endpoint" do
      ActiveStorage::CloudTransformations.configure do |config|
        config.crucible_endpoint = "https://custom.endpoint.com/prod"
      end

      expect(ActiveStorage::CloudTransformations.config.crucible_endpoint).to eq("https://custom.endpoint.com/prod")
    end

    it "allows configuring use_presigned_urls" do
      ActiveStorage::CloudTransformations.configure do |config|
        config.use_presigned_urls = true
      end

      expect(ActiveStorage::CloudTransformations.config.use_presigned_urls).to eq(true)
    end

    it "allows configuring presigned_url_expiration" do
      ActiveStorage::CloudTransformations.configure do |config|
        config.presigned_url_expiration = 7200
      end

      expect(ActiveStorage::CloudTransformations.config.presigned_url_expiration).to eq(7200)
    end
  end
end
