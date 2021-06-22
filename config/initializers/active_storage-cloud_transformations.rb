Rails.application.reloader.to_prepare do
  require "active_storage/cloud_transformations/preview"
  require "active_storage/cloud_transformations/variant"

  # Overwrite original methods to replace Rails' variant implementation with our own

  ActiveStorage::Blob.prepend Module.new {
    def representation(transformations)
      case
      when previewable?(transformations)
        preview transformations
      when variable?
        variant transformations
      else
        raise ActiveStorage::UnrepresentableError
      end
    end

    def previewable? transformations=nil
      if transformations.nil?
        super()
      else
        variation = ActiveStorage::Variation.wrap(transformations)
        video? && MimeMagic.by_extension(variation.format).image?
      end
    end

    def preview(transformations)
      if video? && service.class.to_s == "ActiveStorage::Service::S3Service"
        ActiveStorage::CloudTransformations::Preview.new(self, transformations)
      else
        super
      end
    end

    def default_variant_format
      if video?
        :mp4
      else
        super
      end
    end

    def variable?
      # # Original method implementation documented here as of ActiveStorage 6.1:
      # ActiveStorage.variable_content_types.include?(content_type)

      content_type =~ /^(image|video)\//
    end

    private

    def variant_class
      # # Original method implementation documented here as of ActiveStorage 6.1:
      # ActiveStorage.track_variants ? ActiveStorage::VariantWithRecord : ActiveStorage::Variant

      if service.class.to_s == "ActiveStorage::Service::S3Service"
        ActiveStorage::CloudTransformations::Variant
      else
        super
      end
    end
  }
end

