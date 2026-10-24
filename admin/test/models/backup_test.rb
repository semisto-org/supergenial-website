require "test_helper"

class BackupTest < ActiveSupport::TestCase
  ENV_VARS = { "BACKUP_S3_ENDPOINT" => "https://s3.example.test", "BACKUP_S3_BUCKET" => "backups", "BACKUP_S3_ACCESS_KEY_ID" => "id",
               "BACKUP_S3_SECRET_ACCESS_KEY" => "secret", "BACKUP_ENCRYPTION_KEY" => "a fictive passphrase" }.freeze

  test "configured only when every variable is set" do
    assert Backup.configured?(ENV_VARS)
    assert_not Backup.configured?(ENV_VARS.except("BACKUP_ENCRYPTION_KEY"))
  end

  test "encryption round trip" do
    encrypted = Backup.encrypt("données", "passphrase")
    assert_not_includes encrypted, "données".b
    assert_equal "données".b, Backup.decrypt(encrypted, "passphrase")
    assert_raises(OpenSSL::Cipher::CipherError) { Backup.decrypt(encrypted, "wrong") }
  end

  test "uploads an encrypted archive with the database and stored files, then prunes old ones" do
    require "aws-sdk-s3"
    client = Aws::S3::Client.new(stub_responses: true)
    client.stub_responses(:list_objects_v2, contents: [ { key: "supergenial-admin/old.tar.gz.enc", last_modified: 1.year.ago }, { key: "supergenial-admin/new.tar.gz.enc", last_modified: 1.day.ago } ])

    Dir.mktmpdir do |storage|
      FileUtils.mkdir_p(File.join(storage, "ab/cd"))
      File.write(File.join(storage, "ab/cd/blob"), "pièce jointe")
      File.write(File.join(storage, "production.sqlite3"), "ignored")

      key = Backup.new(client:, env: ENV_VARS, storage_root: storage).run
      assert_match %r{\Asupergenial-admin/\d{4}-\d{2}-\d{2}-\d{6}\.tar\.gz\.enc\z}, key

      put = client.api_requests.find { |request| request[:operation_name] == :put_object }
      archive = Backup.decrypt(put[:params][:body], ENV_VARS["BACKUP_ENCRYPTION_KEY"])
      names = []
      Gem::Package::TarReader.new(Zlib::GzipReader.new(StringIO.new(archive))) { |tar| tar.each { |entry| names << entry.full_name } }
      assert_equal [ "database.sqlite3", "storage/ab/cd/blob" ], names.sort

      deletes = client.api_requests.select { |request| request[:operation_name] == :delete_object }
      assert_equal [ "supergenial-admin/old.tar.gz.enc" ], deletes.map { |request| request[:params][:key] }
    end
  end
end
