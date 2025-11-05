RSpec.configure do |config|
  config.before(:all) do
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

    silence_stream(STDOUT) do
      ActiveRecord::Base.include GlobalID::Identification
      ActiveRecord::Schema.define do
        create_table :active_storage_blobs do |t|
          t.string   :key,          null: false
          t.string   :filename,     null: false
          t.string   :content_type
          t.text     :metadata
          t.string   :service_name, null: false
          t.bigint   :byte_size,    null: false
          t.string   :checksum,     null: false
          t.datetime :created_at,   null: false

          t.index [ :key ], unique: true
        end

        create_table :active_storage_attachments do |t|
          t.string     :name,     null: false
          t.references :record,   null: false, polymorphic: true, index: false
          t.references :blob,     null: false

          t.datetime :created_at, null: false

          t.index [ :record_type, :record_id, :name, :blob_id ], name: "index_active_storage_attachments_uniqueness", unique: true
          t.foreign_key :active_storage_blobs, column: :blob_id
        end

        create_table :active_storage_variant_records do |t|
          t.belongs_to :blob, null: false, index: false
          t.string :variation_digest, null: false

          t.index %i[ blob_id variation_digest ], name: "index_active_storage_variant_records_uniqueness", unique: true
          t.foreign_key :active_storage_blobs, column: :blob_id
        end

        create_table :users do |t|
          t.string :endpoint
          t.timestamps
        end
      end
    end

    class User < ActiveRecord::Base
      has_one_attached :avatar

      def crucible_endpoint
        endpoint if endpoint.present?
      end
    end
  end

  config.after do
    %w[active_storage_variant_records active_storage_attachments active_storage_blobs users sqlite_sequence].each do |table_name|
      ActiveRecord::Base.connection.execute "DELETE FROM #{table_name}"
    end
  end
end

def silence_stream(stream)
  old_stream = stream.dup
  stream.reopen "/dev/null"
  stream.sync = true
  yield
ensure
  stream.reopen(old_stream)
  old_stream.close
end

