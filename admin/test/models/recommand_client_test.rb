require "test_helper"

class RecommandClientTest < ActiveSupport::TestCase
  ENV_VARS = { "RECOMMAND_API_KEY" => "key", "RECOMMAND_API_SECRET" => "secret", "RECOMMAND_COMPANY_ID" => "c_1" }.freeze

  test "configured with the documented variable names" do
    assert Recommand::Client.configured?(ENV_VARS)
    assert_empty Recommand::Client.missing_env(ENV_VARS)
  end

  test "accepts RECOMMAND_SECRET as the API secret" do
    env = ENV_VARS.except("RECOMMAND_API_SECRET").merge("RECOMMAND_SECRET" => "secret")

    assert Recommand::Client.configured?(env)
    assert_nothing_raised { Recommand::Client.new(env:) }
  end

  test "names the missing variables" do
    env = ENV_VARS.except("RECOMMAND_API_SECRET").merge("RECOMMAND_COMPANY_ID" => "")

    assert_not Recommand::Client.configured?(env)
    assert_equal %w[ RECOMMAND_API_SECRET RECOMMAND_COMPANY_ID ], Recommand::Client.missing_env(env)
    assert_raises(KeyError) { Recommand::Client.new(env:) }
  end
end
