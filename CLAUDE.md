# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`active_storage-cloud_transformations` is a Ruby gem that extends Rails' ActiveStorage to delegate image variant and video preview generation to external cloud services (via AWS Lambda API endpoints) rather than processing on-server. This enables more efficient handling of resource-intensive image/video transformations.

**Key Components:**
- `Variant` class: Handles image and video variant generation via cloud processing
- `Preview` class: Generates preview images for video files via cloud service
- Test suite uses a dummy Rails application to test the gem in a realistic environment

## Development Setup

**Ruby version:** 3.3.4 (specified in .ruby-version)

**Install dependencies:**
```bash
bundle install
bin/setup
```

## Common Commands

**Run all tests:**
```bash
bundle exec rake spec
```

**Run a specific test file:**
```bash
bundle exec rspec spec/active_storage-cloud_transformations_spec.rb
```

**Run a specific test:**
```bash
bundle exec rspec spec/active_storage-cloud_transformations_spec.rb:5
```

**Interactive console:**
```bash
bin/console
```

**Install gem locally for testing:**
```bash
bundle exec rake install
```

**Run linter/formatter (if configured):**
Uses RSpec configuration in `.rspec` with documentation format and color output enabled.

## Architecture Notes

### Cloud API Integration

Both `Variant` and `Preview` classes post transformation requests to an AWS Lambda API endpoint at `https://huuabwxpqf.execute-api.us-west-2.amazonaws.com/prod/`. They expect:
- Image variants: POST to `/image/variant`
- Video variants: POST to `/video/variant`
- Video previews: POST to `/video/preview`
- Expected response: HTTP 201 (or 504 for timeouts when `ignore_timeouts: true`)

### Key Processing Patterns

1. **Variant Processing** (`Variant#process`):
   - Creates an output blob with placeholder byte_size and checksum
   - Sets `metadata[:analyzed] = true` to suppress automatic analysis
   - Calls the cloud service via `run_crucible_job`
   - Schedules `ActiveStorage::AnalyzeJob` for post-processing
   - Handles race conditions with retry on `RecordNotUnique`

2. **Variant Reprocessing** (`Variant#reprocess`):
   - Reprocesses an existing variant record using the cloud service
   - Useful when original blob changes or service needs re-execution

3. **Preview Processing** (`Preview#process` and `Preview#reprocess`):
   - Creates both a preview image blob and a variant of that image
   - Sets `metadata[:analyzed] = true` on both blobs
   - Calls cloud service to generate the preview
   - Schedules analysis jobs for both generated blobs

### Test Configuration & Strategy

**Default Test Mode (Mocked Services):**
- Uses WebMock to mock the Lambda API - all POST requests to the Crucible service return 201
- S3 calls are allowed through to real AWS (will fail gracefully with test credentials)
- Requires actual AWS credentials but they can be dummy values: `AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test`

**Full Integration Tests (Real S3 + Real Lambda):**
- To run against real S3 and Lambda services, set environment variable: `DISABLE_CRUCIBLE_MOCKS=true`
- Requires valid AWS credentials: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_S3_BUCKET`
- Use this for CI/CD pipelines or periodic integration testing

**Test Fixtures & Helpers:**
- Uses RSpec with `focus` filter enabled (set `focus: true` on examples to isolate)
- Requires a dummy Rails application in `spec/dummy/`
- Test storage service configurations loaded from `spec/storage.yml` (S3 service)
- ActiveStorage verifier and current host set in `spec_helper.rb`
- Custom matchers available in `spec/support/time_duration_matchers.rb`
- Mock helpers in `spec/support/crucible_mocks.rb`:
  - `mock_crucible_api` - stubs Lambda endpoints to return 201 (default)
  - `mock_crucible_api_timeout` - stubs Lambda to return 504 Gateway Timeout
  - `mock_crucible_api_failure` - stubs Lambda to return 500 errors

## Important Implementation Details

- Transformation parameters are extracted from `variation.transformations`, specifically `resize_to_limit`, `rotation`, and `format`
- Output blobs are created with placeholder checksum (0) since cloud service calculates the actual value
- The gem suppresses ActiveStorage's automatic blob analysis by pre-setting `metadata[:analyzed]`
- HTTP requests use `Net::HTTP` directly for cloud API communication
- The gem extends `ActiveStorage::VariantWithRecord` and `ActiveStorage::Preview`

## Dependencies

Key dependencies (see `Gemfile`):
- `rails`: Rails framework with ActiveStorage
- `rspec`: Testing framework
- `aws-sdk-s3`: For S3 storage service support
- `appraisal`: For testing against multiple Rails versions (see `Appraisals` file)
- `sqlite3`: Test database

## Git Workflow

The main branch is `master`. Work on feature branches and create pull requests for review.
