RSpec.describe ActiveStorage::CloudVariant do
  it "monkeypatches our variant implementation in" do
    expect(ActiveStorage::Blob.new.send(:variant_class)).to eq(ActiveStorage::CloudVariant::Variant)
  end

  describe "images" do
    let(:blob) {
      ActiveStorage::Blob.create!({
        key: "0bs8bd7vjk2wq1bvq9rkttbb9ifr",
        filename: "Joe Costa.jpeg",
        service_name: "amazon",
        content_type: "image/jpeg",
        metadata: {"identified"=>true, "width"=>750, "height"=>1050, "analyzed"=>true},
        byte_size: 218462,
        checksum: "wywsJCAG5ZoqikULWeO80A==",
      })
    }

    it "generates a variant on the fly" do
      blob.variant(resize_to_limit: [780, 780]).process
    end

    it "it can fire and forget for quick eager variant queueing" do
      blob.variant(resize_to_limit: [780, 780]).process(wait: false)
    end
  end

  describe "videos" do
    let(:blob) {
      ActiveStorage::Blob.create!({
        key: "033mj3iolz756b3tj2q4625lx5kr",
        filename: "Marathon.mov",
        service_name: "amazon",
        content_type: "video/quicktime",
        metadata: {"identified"=>true, "width"=>1920, "height"=>1080, "analyzed"=>true},
        byte_size: 39278928,
        checksum: "6ad43090a3dd7a8c114433a3d0ac53df",
      })
    }

    it "generates a video variant" do
      blob.variant(resize_to_limit: [780, 780]).process
    end

    it "it can fire and forget for quick eager variant queueing" do
      blob.variant(resize_to_limit: [160, 160]).process(wait: false)
    end
  end
end

