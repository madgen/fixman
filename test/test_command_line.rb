require 'fixman'
require 'minitest'

class TestCommandLine < Minitest::Test
  extend Fixman::CommandLine

  def test_parse_normal_options
    options = TestCommandLine.parse_options! ['-c', 'my_conf.yaml']
    assert_equal Pathname.new('my_conf.yaml'), options[:conf_path]

    options = TestCommandLine.parse_options! []
    assert_equal Pathname.new(Fixman::Configuration::DEFAULT_CONF_FILE),
                 options[:conf_path]
  end

  def test_parse_option_leaves_positional
    args = %w(hey -c mey yey -c key)
    TestCommandLine.parse_options! args
    assert_equal %w(hey yey), args

    args = %w(hey)
    TestCommandLine.parse_options! args
    assert_equal %w(hey), args
  end

  def test_parse_normal_potisional
    args = %w(add)
    command, other_args = TestCommandLine.parse_positional_arguments!(args)
    assert_equal [], args
    assert_equal :add, command
    assert_equal({}, other_args)

    args = %w(update user/name)
    command, other_args = TestCommandLine.parse_positional_arguments!(args)
    assert_equal [], args
    assert_equal :update, command
    assert_equal({canonical_name: 'user/name', sha: nil}, other_args)

    args = %w(uPdaTe uSEr/name someSHA)
    command, other_args = TestCommandLine.parse_positional_arguments!(args)
    assert_equal [], args
    assert_equal :update, command
    assert_equal({canonical_name: 'uSEr/name', sha: 'someSHA'}, other_args)

    args = %w(fetch groupA groupB groupC)
    command, other_args = TestCommandLine.parse_positional_arguments!(args)
    assert_equal [], args
    assert_equal :fetch, command
    assert_equal({groups: [:groupa, :groupb, :groupc]}, other_args)
  end
end
