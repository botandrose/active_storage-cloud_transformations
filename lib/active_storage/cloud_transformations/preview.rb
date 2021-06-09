module ActiveStorage
  module CloudTransformations
    class Preview < ActiveStorage::Preview
      def process wait: true
        if image.attached?
          if image.variant(variation).processed?
            variant
          else
            create_blob_preview_image_variant(wait: wait)
          end
        else
          create_blob_preview_image_and_blob_preview_image_variant(wait: wait)
        end
        self
      end

      def processed?
        image.variant(variation)&.processed?
      end

      private

      def create_blob_preview_image_variant wait:
        input_blob = blob.preview_image.blob

        variant_record = blob.preview_image.variant_records.create!(variation_digest: variation.digest)
        variant_blob = ActiveStorage::Blob.create_before_direct_upload!({
          filename: "#{blob.filename.base}.#{variation.format}",
          content_type: variation.content_type,
          service_name: blob.service_name,
          byte_size: 0, # we don"t know this yet, can we get it from the results?
          checksum: 0, # we don"t know this yet, can we get it from the results?
        })
        variant_record.image.attach(variant_blob)

        import = transloadit.step "import", "/s3/import",
          key: s3_credentials[:access_key_id],
          secret: s3_credentials[:secret_access_key],
          bucket: s3_credentials[:bucket],
          bucket_region: s3_credentials[:region],
          path: input_blob.key

        width, height = variation.transformations.fetch(:resize_to_limit)
        resize = transloadit.step "resize", "/image/resize",
          width: width,
          height: height,
          resize_strategy: "fit"

        store = transloadit.step "store", "/s3/store",
          key: s3_credentials[:access_key_id],
          secret: s3_credentials[:secret_access_key],
          bucket: s3_credentials[:bucket],
          bucket_region: s3_credentials[:region],
          path: variant_blob.key

        assembly = transloadit.assembly(steps: [import, resize, store])

        response = assembly.create!
        return true unless wait

        response.reload_until_finished!
        !response.error? || (raise response.to_s)
      end

      def create_blob_preview_image_and_blob_preview_image_variant wait:
        preview_image_blob = ActiveStorage::Blob.create_before_direct_upload!({
          filename: "#{blob.filename.base}.#{variation.format}",
          content_type: variation.content_type,
          service_name: blob.service_name,
          byte_size: 0, # we don"t know this yet, can we get it from the results?
          checksum: 0, # we don"t know this yet, can we get it from the results?
        })
        blob.preview_image.attach(preview_image_blob)

        variant_variation = variation.default_to(preview_image_blob.send(:default_variant_transformations))
        variant_record = blob.preview_image.variant_records.create!(variation_digest: variant_variation.digest)
        variant_blob = ActiveStorage::Blob.create_before_direct_upload!({
          filename: "#{blob.filename.base}.#{variant_variation.format}",
          content_type: variant_variation.content_type,
          service_name: blob.service_name,
          byte_size: 0, # we don"t know this yet, can we get it from the results?
          checksum: 0, # we don"t know this yet, can we get it from the results?
        })
        variant_record.image.attach(variant_blob)

        import = transloadit.step "import", "/s3/import",
          key: s3_credentials[:access_key_id],
          secret: s3_credentials[:secret_access_key],
          bucket: s3_credentials[:bucket],
          bucket_region: s3_credentials[:region],
          path: blob.key

        extract = transloadit.step "extract", "/video/thumbs",
          offsets: [1],
          ffmpeg_stack: "v4.3.1"

        width, height = variation.transformations.fetch(:resize_to_limit)
        resize = transloadit.step "resize", "/image/resize",
          width: width,
          height: height,
          resize_strategy: "fit"

        store_preview_image = transloadit.step "store_preview_image", "/s3/store",
          use: "extract",
          key: s3_credentials[:access_key_id],
          secret: s3_credentials[:secret_access_key],
          bucket: s3_credentials[:bucket],
          bucket_region: s3_credentials[:region],
          path: preview_image_blob.key

        store_variant = transloadit.step "store_variant", "/s3/store",
          use: "resize",
          key: s3_credentials[:access_key_id],
          secret: s3_credentials[:secret_access_key],
          bucket: s3_credentials[:bucket],
          bucket_region: s3_credentials[:region],
          path: variant_blob.key

        assembly = transloadit.assembly(steps: [import, extract, resize, store_preview_image, store_variant])

        response = assembly.create!
        return true unless wait

        response.reload_until_finished!
        !response.error? || (raise response.to_s)
      end

      def transloadit
        @transloadit ||= Transloadit.new(service_credentials(:transloadit))
      end

      def s3_credentials
        @s3_credentials ||= service_credentials(ActiveStorage::Blob.service.name)
      end

      def service_credentials key
        ::Rails.configuration.active_storage.service_configurations[key.to_s].symbolize_keys
      end
    end
  end
end

