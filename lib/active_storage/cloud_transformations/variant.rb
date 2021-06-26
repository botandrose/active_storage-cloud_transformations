require "active_storage/variant_with_record"
require "transloadit"

module ActiveStorage
  module CloudTransformations
    class Variant < ActiveStorage::VariantWithRecord
      def process
        raise ActiveStorage::InvariableError unless blob.image?

        ActiveRecord::Base.connected_to(role: ActiveRecord::Base.writing_role) do
          # FIXME #create_or_find_by! runs the block in both cases. bug in rails?
          blob.variant_records.find_or_create_by!(variation_digest: variation.digest) do |record|
            output_blob = ActiveStorage::Blob.create_before_direct_upload!({
              filename: "#{blob.filename.base}.#{variation.format}",
              content_type: variation.content_type,
              service_name: blob.service_name,
              byte_size: 0, # we don"t know this yet, can we get it from the results?
              checksum: 0, # we don"t know this yet, can we get it from the results?
            })
            record.image.attach(output_blob)
            run_crucible_job(blob, output_blob)
          end
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end

      private

      def run_crucible_job input_blob, output_blob
        width, height = variation.transformations.fetch(:resize_to_limit)
        post! "https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod/image/variant", {
          blob_url: input_blob.url.split("?").first,
          dimensions: "#{width}x#{height}",
          image_variant_url: output_blob.url.split("?").first,
        }
      end

      def format
        variation.transformations.fetch(:format)
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

