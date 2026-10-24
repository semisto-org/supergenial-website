require "rubygems/package"

# Nightly off-site backup: a consistent snapshot of the main SQLite database plus the stored files
# (Active Storage), in one gzipped tar, encrypted, sent to an S3-compatible bucket (e.g. Infomaniak Swiss Backup).
#
# Runtime variables (Coolify): BACKUP_S3_ENDPOINT, BACKUP_S3_BUCKET, BACKUP_S3_ACCESS_KEY_ID,
# BACKUP_S3_SECRET_ACCESS_KEY, BACKUP_S3_REGION (optional), BACKUP_ENCRYPTION_KEY, BACKUP_RETENTION_DAYS (default 90).
class Backup
  PREFIX = "supergenial-admin/"
  MAGIC = "SGB1"
  REQUIRED_ENV = %w[ BACKUP_S3_ENDPOINT BACKUP_S3_BUCKET BACKUP_S3_ACCESS_KEY_ID BACKUP_S3_SECRET_ACCESS_KEY BACKUP_ENCRYPTION_KEY ].freeze

  def self.configured?(env = ENV) = REQUIRED_ENV.all? { |name| env[name].present? }

  def self.cipher_key(passphrase) = ActiveSupport::KeyGenerator.new(passphrase, iterations: 100_000).generate_key("supergenial-admin backup", 32)

  def self.encrypt(data, passphrase)
    cipher = OpenSSL::Cipher.new("aes-256-gcm").encrypt
    cipher.key = cipher_key(passphrase)
    iv = cipher.random_iv
    encrypted = cipher.update(data) + cipher.final
    MAGIC + iv + cipher.auth_tag + encrypted
  end

  def self.decrypt(data, passphrase)
    raise ArgumentError, "Not a Super Génial backup" unless data.start_with?(MAGIC)
    iv, tag, encrypted = data.byteslice(4, 12), data.byteslice(16, 16), data.byteslice(32..)
    cipher = OpenSSL::Cipher.new("aes-256-gcm").decrypt
    cipher.key = cipher_key(passphrase)
    cipher.iv = iv
    cipher.auth_tag = tag
    cipher.update(encrypted) + cipher.final
  end

  def initialize(client: nil, env: ENV, storage_root: Rails.root.join("storage"), now: Time.current)
    @env, @storage_root, @now = env, Pathname(storage_root), now
    @client = client
  end

  # Returns the object key that was written.
  def run
    key = "#{PREFIX}#{@now.utc.strftime('%Y-%m-%d-%H%M%S')}.tar.gz.enc"
    client.put_object(bucket:, key:, body: self.class.encrypt(archive, @env.fetch("BACKUP_ENCRYPTION_KEY")))
    prune
    key
  end

  def archive
    Dir.mktmpdir do |dir|
      snapshot = File.join(dir, "database.sqlite3")
      # A separate connection: VACUUM cannot run inside the transaction a job or test may hold.
      SQLite3::Database.new(ActiveRecord::Base.connection_db_config.database) { |db| db.execute("VACUUM INTO ?", [ snapshot ]) }

      gzipped = StringIO.new
      Zlib::GzipWriter.wrap(gzipped) do |gzip|
        Gem::Package::TarWriter.new(gzip) do |tar|
          add_file(tar, "database.sqlite3", snapshot)
          stored_files.each { |path| add_file(tar, "storage/#{path.relative_path_from(@storage_root)}", path) }
        end
      end
      gzipped.string
    end
  end

  private
    def client
      @client ||= begin
        require "aws-sdk-s3"
        Aws::S3::Client.new(endpoint: @env.fetch("BACKUP_S3_ENDPOINT"), region: @env.fetch("BACKUP_S3_REGION", "us-east-1"),
                            access_key_id: @env.fetch("BACKUP_S3_ACCESS_KEY_ID"), secret_access_key: @env.fetch("BACKUP_S3_SECRET_ACCESS_KEY"),
                            force_path_style: true)
      end
    end

    def bucket = @env.fetch("BACKUP_S3_BUCKET")

    # Active Storage files: everything in storage/ except the SQLite databases themselves.
    def stored_files
      return [] unless @storage_root.directory?
      @storage_root.glob("**/*").select(&:file?).reject { |path| path.basename.to_s.match?(/\.sqlite3(-\w+)?\z/) }
    end

    def add_file(tar, name, path)
      tar.add_file_simple(name, 0o600, File.size(path)) { |io| File.open(path, "rb") { |file| IO.copy_stream(file, io) } }
    end

    def prune
      cutoff = @now - @env.fetch("BACKUP_RETENTION_DAYS", "90").to_i.days
      old = client.list_objects_v2(bucket:, prefix: PREFIX).contents.select { |object| object.last_modified < cutoff }
      old.each { |object| client.delete_object(bucket:, key: object.key) }
    end
end
