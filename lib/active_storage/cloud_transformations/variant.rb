require "active_storage"

module ActiveStorage
  module CloudTransformations
    class Variant < ActiveStorage::VariantWithRecord
      include CrucibleHelpers
      def process
        raise ActiveStorage::InvariableError unless blob.image? || blob.video?

        blob.variant_records.find_or_create_by!(variation_digest: variation.digest) do |record|
          output_blob = ActiveStorage::Blob.create_before_direct_upload!(**{
            filename: "#{blob.filename.base}.#{variation.format}",
            content_type: variation.content_type,
            service_name: blob.service_name,
            byte_size: 0, # we don"t know this yet, can we get it from the results?
            checksum: 0, # we don"t know this yet, can we get it from the results?
          })
          output_blob.metadata[:analyzed] = true
          record.image.attach(output_blob)
          run_crucible_job(blob, output_blob, ignore_timeouts: true)
          ActiveStorage::AnalyzeJob.perform_later(output_blob)
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

        input_url = blob_url_for(input_blob, :get)
        output_url = blob_url_for(output_blob, :put)

        params = {
          blob_url: input_url,
          dimensions: "#{width}x#{height}",
          rotation: rotation,
          variant_url: output_url,
          format: format,
        }
        endpoint = "#{resolve_crucible_endpoint}/#{path}"
        post! endpoint, params, ignore_timeouts: ignore_timeouts
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

