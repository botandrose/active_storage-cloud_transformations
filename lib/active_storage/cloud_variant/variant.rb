require "active_storage/variant_with_record"
require "transloadit"

module ActiveStorage
  module CloudVariant
    class Variant < ActiveStorage::VariantWithRecord
      def process wait: true
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
            start_transloadit_job(blob, output_blob, wait: wait)
          end
        end
      end

      private

      def start_transloadit_job input_blob, output_blob, wait:
        import = transloadit.step "import", "/s3/import",
          key: s3_credentials[:access_key_id],
          secret: s3_credentials[:secret_access_key],
          bucket: s3_credentials[:bucket],
          bucket_region: s3_credentials[:region],
          path: blob.key

        width, height = variation.transformations.fetch(:resize_to_limit)
        resize = transloadit.step "resize", "/image/resize",
          width: width,
          height: height,
          format: variation.transformations.fetch(:format, "jpg"),
          quality: variation.transformations.fetch(:quality, 92)

        store = transloadit.step "store", "/s3/store",
          key: s3_credentials[:access_key_id],
          secret: s3_credentials[:secret_access_key],
          bucket: s3_credentials[:bucket],
          bucket_region: s3_credentials[:region],
          path: output_blob.key
        assembly = transloadit.assembly(steps: [import, resize, store])

        response = assembly.create!
        return true unless wait

        response.reload_until_finished!
        !response.error?
      end

      def transloadit
        @transloadit ||= Transloadit.new(transloadit_credentials)
      end

      def s3_credentials
        ::Rails.configuration.active_storage.service_configurations["amazon"].symbolize_keys
      end

      def transloadit_credentials
        ::Rails.configuration.active_storage.service_configurations["transloadit"].symbolize_keys
      end
    end
  end
end

