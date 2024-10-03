require "active_storage"

module ActiveStorage
  module CloudTransformations
    class Variant < ActiveStorage::VariantWithRecord
      def process
        raise ActiveStorage::InvariableError unless blob.image? || blob.video?

        role = ActiveRecord.respond_to?(:writing_role) ? ActiveRecord.writing_role : ActiveRecord::Base.writing_role
        ActiveRecord::Base.connected_to(role: role) do
          # FIXME #create_or_find_by! runs the block in both cases. bug in rails?
          blob.variant_records.find_or_create_by!(variation_digest: variation.digest) do |record|
            output_blob = ActiveStorage::Blob.create_before_direct_upload!(**{
              filename: "#{blob.filename.base}.#{variation.format}",
              content_type: variation.content_type,
              service_name: blob.service_name,
              byte_size: 0, # we don"t know this yet, can we get it from the results?
              checksum: 0, # we don"t know this yet, can we get it from the results?
            })
            record.image.attach(output_blob)
            run_crucible_job(blob, output_blob, ignore_timeouts: true)
          end
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end

      def reprocess
        raise ActiveStorage::InvariableError unless blob.image? || blob.video?
        record = blob.variant_records.find_by!(variation_digest: variation.digest)
        output_blob = record.image.blob
        run_crucible_job(blob, output_blob, ignore_timeouts: true)
      end

      public :processed?

      private

      def run_crucible_job input_blob, output_blob, ignore_timeouts: false
        width, height = variation.transformations.fetch(:resize_to_limit)
        rotation = variation.transformations.fetch(:rotation, 0)
        post! "https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod/#{path}", {
          blob_url: input_blob.url.split("?").first,
          dimensions: "#{width}x#{height}",
          rotation: rotation,
          variant_url: output_blob.url.split("?").first,
        }, ignore_timeouts: ignore_timeouts
      end

      def path
        return "image/variant" if blob.image?
        return "video/variant" if blob.video?
      end

      def format
        variation.transformations.fetch(:format)
      end

      def post! url, body, ignore_timeouts: false
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        request = Net::HTTP::Post.new(uri.request_uri, {"Content-Type": "application/json"})
        request.body = body.to_json
        response = http.request(request)
        response.code == "201" || (response.code == "504" && ignore_timeouts) || (raise body.to_json + response.inspect + response.body)
      end
    end
  end
end

