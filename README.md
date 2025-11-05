# ActiveStorage::CloudTransformations

A Rails gem that extends ActiveStorage to generate image variants and video previews via external cloud services (like AWS Lambda) instead of processing them locally on your server.

## Features

- **Offload image and video processing** to cloud services, reducing server load
- **Support for variants** - Transform images with custom dimensions, formats, and rotations
- **Support for previews** - Generate preview images from video files
- **Flexible configuration** - Easily point to your own cloud transformation service
- **Per-instance endpoints** - Route different requests to different endpoints based on your model logic
- **Presigned URLs** - Remove the need for your cloud service to have direct S3 access
- **Non-blocking** - Processing happens asynchronously without blocking request handling
- **Rails 7.2+** - Works with modern Rails and ActiveStorage

## Why Cloud Transformations?

Processing large images and videos locally consumes significant CPU resources. This gem lets you delegate that work to dedicated cloud services, allowing your Rails application to focus on what it does best. You get:

- Reduced server CPU usage
- Faster request handling
- Scalable processing as your media grows

## Configuration

### Global Configuration

Create an initializer at `config/initializers/active_storage_cloud_transformations.rb`:

```ruby
ActiveStorage::CloudTransformations.configure do |config|
  # The cloud service endpoint (default: "https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod")
  config.crucible_endpoint = ENV.fetch("CRUCIBLE_ENDPOINT", "https://crucible.example.com/prod")

  # Use presigned URLs instead of S3 paths (default: false)
  # When enabled, your cloud service doesn't need direct S3 access
  config.use_presigned_urls = true

  # Presigned URL expiration in seconds (default: 3600)
  config.presigned_url_expiration = 7200
end
```

### Per-Instance Endpoint Configuration

You can configure different endpoints for different model instances by defining a `crucible_endpoint` method on your model:

```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  def crucible_endpoint
    # Route premium users to a different endpoint
    if premium?
      "https://premium.crucible.example.com/prod"
    elsif region == "eu"
      "https://eu.crucible.example.com/prod"
    else
      # Return nil to use the global config
      nil
    end
  end
end
```

When processing attachments, the gem will:
1. Check if the model defines a `crucible_endpoint` method
2. Use that endpoint if it returns a non-nil value
3. Fall back to the global `config.crucible_endpoint` otherwise

## Usage

### Image Variants

Generate image variants just like you normally would with ActiveStorage. The cloud service will handle the transformation:

```ruby
@user = User.find(1)

# Generate a variant (will be processed by cloud service)
@user.avatar.variant(resize_to_limit: [100, 100]).processed
```

### Video Previews

Generate preview images from video files:

```ruby
@video = Video.find(1)

# Generate a preview image from the video
@video.file.preview(resize_to_limit: [160, 160]).processed

# Access the generated preview image
image_url = @video.file.preview_image.url
```

### Supported Transformations

The cloud service receives the following information via HTTP POST:

**For image variants:**
- `blob_url` - URL to the source image (presigned GET URL or S3 path)
- `dimensions` - Target dimensions (e.g., "100x100")
- `rotation` - Rotation angle in degrees
- `variant_url` - Where to upload the processed variant (presigned PUT URL or S3 path)
- `format` - Output format (e.g., "webp", "jpeg")

**For video previews:**
- `blob_url` - URL to the source video (presigned GET URL or S3 path)
- `dimensions` - Dimensions for the preview image
- `rotation` - Rotation angle in degrees
- `preview_image_url` - Where to upload the generated preview image (presigned PUT URL or S3 path)
- `preview_image_variant_url` - Where to upload the preview image variant (presigned PUT URL or S3 path)

**Note:** When `use_presigned_urls` is enabled, all URLs include AWS signature query parameters. When disabled, URLs are S3 paths without query parameters, requiring your cloud service to have S3 credentials.

## How It Works

1. When you request a variant or preview, ActiveStorage creates blob records
2. This gem intercepts the process and makes an HTTP POST request to your cloud service
3. The request includes:
   - Source media URL (presigned GET URL or S3 path)
   - Destination URL for the processed file (presigned PUT URL or S3 path)
   - Transformation parameters (dimensions, format, rotation, etc.)
4. Your cloud service performs the transformation:
   - **With presigned URLs:** Downloads from the GET URL, transforms, uploads to the PUT URL
   - **Without presigned URLs:** Accesses S3 directly using its own credentials
5. The gem receives a 201 confirmation and marks the variant as processed
6. Future requests for the same variant are served from the cache (already in S3)

### Presigned URLs vs S3 Paths

**Presigned URLs (recommended):**
- Your cloud service doesn't need S3 credentials
- More secure - temporary, scoped access
- Works with any HTTP client
- Enable with `config.use_presigned_urls = true`

**S3 Paths (legacy):**
- Your cloud service needs AWS credentials with S3 access
- URLs are simple paths like `s3://bucket/key`
- Default behavior for backward compatibility

## Storage Requirements

This gem requires **S3 as the storage service** for your Rails application. It does _not_ work with the local disk service.

**For your Rails application:**
- Configure ActiveStorage to use S3
- Needs S3 credentials to generate presigned URLs (when enabled) or direct S3 access

**For your cloud transformation service:**
- **With presigned URLs enabled:** No S3 credentials needed - the service uses presigned URLs
- **Without presigned URLs:** Requires AWS credentials with S3 read/write access

## Development

### Running Tests Locally

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your S3 credentials:
   ```bash
   AWS_S3_URI=s3://YOUR_ACCESS_KEY_ID:YOUR_SECRET_ACCESS_KEY@YOUR_REGION.amazonaws.com/YOUR_BUCKET
   ```

3. Run the tests:
   ```bash
   bundle exec rspec
   ```

By default, requests are mocked in tests. Set `CRUCIBLE_ENDPOINT` in your `.env` file to point to a real service for full integration testing.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/botandrose/active_storage-cloud_transformations](https://github.com/botandrose/active_storage-cloud_transformations).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
