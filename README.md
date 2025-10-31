# ActiveStorage::CloudTransformations

A Rails gem that extends ActiveStorage to generate image variants and video previews via external cloud services (like AWS Lambda) instead of processing them locally on your server.

## Features

- **Offload image and video processing** to cloud services, reducing server load
- **Support for variants** - Transform images with custom dimensions, formats, and rotations
- **Support for previews** - Generate preview images from video files
- **Flexible configuration** - Easily point to your own cloud transformation service
- **Non-blocking** - Processing happens asynchronously without blocking request handling
- **Rails 6.1+** - Works with modern ActiveStorage

## Why Cloud Transformations?

Processing large images and videos locally consumes significant CPU resources. This gem lets you delegate that work to dedicated cloud services, allowing your Rails application to focus on what it does best. You get:

- Reduced server CPU usage
- Faster request handling
- Scalable processing as your media grows

## Configuration

### Cloud Transformation Service Endpoint

Create an initializer at `config/initializers/active_storage_cloud_transformations.rb` to customize the cloud service endpoint:

```ruby
ActiveStorage::CloudTransformations.configure do |config|
  config.crucible_endpoint = ENV.fetch("CRUCIBLE_ENDPOINT", "https://crucible.example.com/prod")
end
```

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

The cloud service receives the following information:

**For image variants:**
- `blob_url` - URL to the source image
- `dimensions` - Target dimensions (e.g., "100x100")
- `rotation` - Rotation angle in degrees
- `variant_url` - Where to upload the processed variant
- `format` - Output format (e.g., "webp", "jpeg")

**For video previews:**
- `blob_url` - URL to the source video
- `dimensions` - Dimensions for the preview image
- `rotation` - Rotation angle in degrees
- `preview_image_url` - Where to upload the generated preview image
- `preview_image_variant_url` - Where to upload the preview image variant

## How It Works

1. When you request a variant or preview, ActiveStorage creates blob records
2. This gem intercepts the process and makes an HTTP POST request to your cloud service
3. The cloud service URL includes:
   - Source media URL (in S3 or your configured storage)
   - Destination URL for the processed file
   - Transformation parameters (dimensions, format, rotation, etc.)
4. Your cloud service performs the transformation and uploads the result to the destination URL
5. The gem receives a 201 confirmation and marks the variant as processed
6. Future requests for the same variant are served from the cache (already in S3)

## Storage Requirements

This gem requires **S3 as the storage service**. It does _not_ work with the local disk service. Configure ActiveStorage to use S3.

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
