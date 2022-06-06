module ActiveStorage
  module CloudTransformations
    class Preview < ActiveStorage::Preview
      def process
        # TODO
        # if image.attached?
        #   if image.variant(variation).processed?
        #     variant
        #   else
        #     create_blob_preview_image_variant
        #   end
        # else
          create_blob_preview_image_and_blob_preview_image_variant
        # end
        self
      end

      def processed?
        image.variant(variation)&.processed?
      end

      private

      def create_blob_preview_image_and_blob_preview_image_variant
        preview_image_blob = ActiveStorage::Blob.create_before_direct_upload!(**{
          filename: "#{blob.filename.base}.#{variation.format}",
          content_type: variation.content_type,
          service_name: blob.service_name,
          byte_size: 0, # we don"t know this yet, can we get it from the results?
          checksum: 0, # we don"t know this yet, can we get it from the results?
        })
        blob.preview_image.attach(preview_image_blob)

        variant_variation = variation.default_to(preview_image_blob.send(:default_variant_transformations))
        variant_record = blob.preview_image.variant_records.create!(variation_digest: variant_variation.digest)
        variant_blob = ActiveStorage::Blob.create_before_direct_upload!(**{
          filename: "#{blob.filename.base}.#{variant_variation.format}",
          content_type: variant_variation.content_type,
          service_name: blob.service_name,
          byte_size: 0, # we don"t know this yet, can we get it from the results?
          checksum: 0, # we don"t know this yet, can we get it from the results?
        })
        variant_record.image.attach(variant_blob)

        width, height = variation.transformations.fetch(:resize_to_limit)
        rotation = variation.transformations.fetch(:rotation, 0)
        post! "https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod/video/preview", {
          blob_url: blob.url.split("?").first,
          dimensions: "#{width}x#{height}",
          rotation: rotation,
          preview_image_url: preview_image_blob.url.split("?").first,
          preview_image_variant_url: variant_blob.url.split("?").first,
        }
      end

      def post! url, body
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        request = Net::HTTP::Post.new(uri.request_uri, {"Content-Type": "application/json"})
        request.body = body.to_json
        response = http.request(request)
        response.code == "201" || (raise body.to_json + response.inspect)
      end
    end
  end
end

