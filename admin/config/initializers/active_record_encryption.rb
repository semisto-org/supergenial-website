# Active Record encryption (two-factor secrets, later API tokens).
# Keys come from ACTIVE_RECORD_ENCRYPTION_* runtime variables when set, otherwise they are derived
# from secret_key_base, so the app needs no extra credentials file.
Rails.application.config.after_initialize do
  generator = Rails.application.key_generator
  derive = ->(name) { ENV["ACTIVE_RECORD_ENCRYPTION_#{name.upcase}"].presence || generator.generate_key("active_record_encryption/#{name}", 32).unpack1("H*") }

  ActiveRecord::Encryption.configure(
    primary_key: derive.call(:primary_key),
    deterministic_key: derive.call(:deterministic_key),
    key_derivation_salt: derive.call(:key_derivation_salt)
  )
end
