require 'fixman'
require 'minitest'
require 'minitest/mock'

class TestController < Minitest::Test

  def test_write_ledger
    original_ledger = ""
    repos = Minitest::Mock.new.expect(:map, ['abc','def'])
    Tempfile.open 'location' do |t|
      Fixman::Controller.send :write_ledger, repos, original_ledger, t.path
      t.rewind
      assert_equal "---\n- abc\n- def\n", t.read
    end
  end
end
