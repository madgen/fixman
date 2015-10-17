require 'fixman'
require 'minitest'

class TestRepository < Minitest::Test
  def test_extract_name_owner
    url = 'http://www.github.com/madgen/fixman'
    owner, name = Fixman::Repository.extract_owner_and_name(url)
    assert_equal 'madgen', owner
    assert_equal 'fixman', name

    url = 'http://www.github.com/matz/ruby.git'
    owner, name = Fixman::Repository.extract_owner_and_name(url)
    assert_equal 'matz', owner
    assert_equal 'ruby', name

    url = 'http://www.hithub.com/matz/ruby.git'
    owner, name = Fixman::Repository.extract_owner_and_name(url)
    assert_equal nil, owner
    assert_equal nil, name
  end
end
