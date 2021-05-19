Rails.application.routes.draw do
  resolve("ActiveStorage::CloudTransformations::Variant") { |variant, options| route_for(ActiveStorage.resolve_model_to_route, variant, options) }
end

