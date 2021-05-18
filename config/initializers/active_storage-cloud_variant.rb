Rails.application.reloader.to_prepare do
  require "active_storage/cloud_variant/variant"

  # Overwrite original method to replace Rails' variant implementation with our own
  ActiveStorage::Blob::Representable.class_eval do
    private def variant_class
      # # Original method implementation documented here as of ActiveStorage 6.1:
      # ActiveStorage.track_variants ? ActiveStorage::VariantWithRecord : ActiveStorage::Variant

      ActiveStorage::CloudVariant::Variant
    end
  end
end

