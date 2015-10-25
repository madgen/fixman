require 'fixman'
require 'minitest'

class TestController < Minitest::Test
  def test_open
    expected_conf_hash = {}
    mock_conf = MiniTest::Mock.new
    YAML.stub(:load, expected_ledger_hash) do
      Fixman::Controller.open conf
    end
  end
end
