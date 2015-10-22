require 'fixman'
require 'minitest'

class TestCommandLine < Minitest::Test
  extend Fixman::CommandLine

  @@desired_input_index = 0

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

  def test_start_session_optional
    input = {}
    template = { symbol: :test, prompt: 'Test prompt', label: '', type: :optional }
    change_get_input "test value" do
      assert_output(template[:prompt]) do
        TestCommandLine.send(:start_session, input, template)
      end
    end
    expected_input = { test: 'test value' }
    assert_equal(expected_input, input)

    template = { symbol: :test2, prompt: 'Another prompt', label: ''}
    change_get_input "test value2" do
      assert_output(template[:prompt]) do
        TestCommandLine.send(:start_session, input, template)
      end
    end
    expected_input[:test2] = 'test value2'
    assert_equal(expected_input, input)
  end

  def test_start_session_mandatory
    input = {}
    template = {
      symbol: :test,
      prompt: 'Test prompt',
      label: '',
      type: :mandatory
    }
    change_get_input "TEST value" do
      assert_output(template[:prompt]) do
        TestCommandLine.send(:start_session, input, template)
      end
    end
    expected_input = { test: 'TEST value' }
    assert_equal(expected_input, input)

    input = {}
    change_get_input ['  ', '', 'TEST value'] do
      assert_output(template[:prompt] * 3) do
        TestCommandLine.send(:start_session, input, template)
      end
    end
    expected_input = { test: 'TEST value' }
    assert_equal(expected_input, input)
  end

  def test_start_session_single_choice
    input = {}
    template = {
      symbol: :test,
      prompt: 'Test prompt',
      label: '',
      type: :single_choice,
      choices: %w(1 2 3 4)
    }
    change_get_input "2" do
      assert_output(%r|1/2/3|) do
        TestCommandLine.send(:start_session, input, template)
      end
    end
    expected_input = { test: '2' }
    assert_equal(expected_input, input)

    input = {}
    change_get_input ['  ', '5', '3'] do
      assert_output(%r|1/2/3/4.*1/2/3/4|m) do
        TestCommandLine.send(:start_session, input, template)
      end
    end
    expected_input = { test: '3' }
    assert_equal(expected_input, input)
  end

  def test_start_session_multiple_choice
    input = {}
    template = {
      symbol: :test,
      prompt: 'Test prompt',
      label: '',
      type: :multiple_choice,
      choices: %w(RUby pytHOn elixir)
    }
    change_get_input "pytHOn" do
      assert_output(%r|RUby/pytHOn/elixir|) do
        TestCommandLine.send(:start_session, input, template)
      end
    end
    expected_input = { test: ['pytHOn'] }
    assert_equal(expected_input, input)

    input = {}
    change_get_input ['  ', '5,RUby', 'elixir,pytHOn'] do
      assert_output(%r|RUby.*RUby|m) do
        TestCommandLine.send(:start_session, input, template)
      end
    end
    expected_input = { test: ['elixir', 'pytHOn'] }
    assert_equal(expected_input, input)
  end

  def test_get_params
    extra_templates = [
      { 
        symbol: :notes, 
        prompt: 'Notes', 
        label: 'Notes', 
        type: :optional 
      },
      { 
        symbol: :licence, 
        prompt: 'Licence', 
        label: 'Licence', 
        type: :single_choice, 
        choices: ['MIT', 'Apache'] 
      }
    ]

    inputs = [
      'https://github.com/madgen/fixman', 
      'a , b, c',
      'It is good to take notes',
      'apache'
    ]
    params = []
    expected_sha = 'fake SHA'
    assert_output(/URL.*Notes.*Licence.*Apache/m) do
      params = 
      change_get_input inputs do
        Fixman::Repository.stub(:retrieve_head_sha, expected_sha) do 
          TestCommandLine.get_params extra_templates, %w(d a e b c)
        end
      end
    end

    assert_equal 'fixman', params[:name]
    assert_equal 'madgen', params[:owner]
    assert_equal inputs[0], params[:url]
    assert_equal %w(a b c), params[:groups]
    assert_equal inputs[2], params[:notes]
    assert_equal 'Apache', params[:licence]
    assert_equal expected_sha, params[:sha]

    inputs = [
      'https://bithub.com/madgen/fixman',
      'fixman',
      'madgen',
      'a',
      'It is good to take notes',
      'mit'
    ]
    assert_output(/URL.*Notes.*Licence.*Apache/m) do
      params = 
      change_get_input inputs do
        Fixman::Repository.stub(:retrieve_head_sha, expected_sha) do 
          TestCommandLine.get_params extra_templates, %w(d a e b c)
        end
      end
    end

    assert_equal inputs[0], params[:url]
    assert_equal inputs[1], params[:name]
    assert_equal inputs[2], params[:owner]
    assert_equal ['a'], params[:groups]
    assert_equal inputs[4], params[:notes]
    assert_equal 'MIT', params[:licence]
    assert_equal expected_sha, params[:sha]
  end

  private

  def change_get_input(desired_input)
    TestCommandLine.instance_eval { undef :get_input }
    TestCommandLine.define_singleton_method :get_input do
      result =
      if desired_input.is_a? String
        desired_input
      elsif desired_input.is_a? Array
        desired_input[@@desired_input_index]
      end
      @@desired_input_index += 1
      result
    end

    result = yield

    TestCommandLine.instance_eval do
      undef :get_input
      @@desired_input_index = 0
    end
    TestCommandLine.define_singleton_method :get_input do
      gets.chomp
    end

    result
  end
end
