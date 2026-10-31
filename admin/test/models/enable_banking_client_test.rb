require "test_helper"

class EnableBankingClientTest < ActiveSupport::TestCase
  KEY = OpenSSL::PKey::RSA.new(2048)
  ENV_VARS = { "ENABLE_BANKING_APPLICATION_ID" => "app-fictive", "ENABLE_BANKING_PRIVATE_KEY" => KEY.to_pem.gsub("\n", "\\n") }.freeze

  class PagedClient < EnableBanking::Client
    attr_reader :paths

    def get(path)
      (@paths ||= []) << path
      path.include?("continuation_key") ? { "transactions" => [ { "entry_reference" => "2" } ] } : { "transactions" => [ { "entry_reference" => "1" } ], "continuation_key" => "next" }
    end
  end

  test "signs a JWT with the application key" do
    header, claims, signature = EnableBanking::Client.new(env: ENV_VARS).token(now: Time.at(1_800_000_000)).split(".")
    assert_equal({ "typ" => "JWT", "alg" => "RS256", "kid" => "app-fictive" }, JSON.parse(Base64.urlsafe_decode64(header)))
    assert_equal({ "iss" => "enablebanking.com", "aud" => "api.enablebanking.com", "iat" => 1_800_000_000, "exp" => 1_800_003_600 }, JSON.parse(Base64.urlsafe_decode64(claims)))
    assert KEY.public_key.verify(OpenSSL::Digest::SHA256.new, Base64.urlsafe_decode64(signature), "#{header}.#{claims}")
  end

  test "follows the pages of transactions" do
    client = PagedClient.new(env: ENV_VARS)
    assert_equal %w[ 1 2 ], client.transactions("acc-1", date_from: Date.new(2026, 8, 1)).map { |transaction| transaction["entry_reference"] }
    assert_includes client.paths.first, "date_from=2026-08-01"
    assert_includes client.paths.last, "continuation_key=next"
  end

  test "is configured by its two variables" do
    assert EnableBanking::Client.configured?(ENV_VARS)
    assert_not EnableBanking::Client.configured?({})
  end
end
