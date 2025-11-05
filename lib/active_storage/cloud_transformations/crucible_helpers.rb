module ActiveStorage
  module CloudTransformations
    module CrucibleHelpers
      private

      def resolve_crucible_endpoint
        if blob.attachments.any?
          record = blob.attachments.first.record
          if record.respond_to?(:crucible_endpoint)
            endpoint = record.crucible_endpoint
            return endpoint if endpoint.present?
          end
        end

        ActiveStorage::CloudTransformations.config.crucible_endpoint
      end

      def blob_url_for(blob, method)
        config = ActiveStorage::CloudTransformations.config

        if config.use_presigned_urls
          expiration = config.presigned_url_expiration

          case method
          when :get
            blob.url(expires_in: expiration)
          when :put
            generate_presigned_put_url(blob, expiration)
          end
        else
          blob.url.split("?").first
        end
      end

      def generate_presigned_put_url(blob, expires_in)
        service = blob.service

        if service.respond_to?(:bucket)
          object = service.send(:object_for, blob.key)
          object.presigned_url(:put, expires_in: expires_in)
        else
          raise NotImplementedError, "Presigned PUT URLs not supported for #{service.class}"
        end
      end
    end
  end
end
