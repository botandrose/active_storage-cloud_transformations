Rails.application.reloader.to_prepare do
  require "active_storage/cloud_transformations/preview"
  require "active_storage/cloud_transformations/variant"

  # Overwrite original methods to replace Rails' variant implementation with our own

  ActiveStorage::Blob.prepend Module.new {
    # def preview(transformations)
    #   if video?
    #     ActiveStorage::CloudTransformations::Preview.new(self, transformations)
    #   else
    #     super
    #   end
    # end

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

      ActiveStorage::CloudTransformations::Variant
    end
  }
end

