require 'fixman'
require 'minitest'
require 'set'

class TestRawTask < MiniTest::Test
  def setup
    @params = {
      name: 'task',
      target_placeholder: 'TARGET'
    }
  end

  def test_refine
    # Vanilla case
    params = @params.merge({
      command: {
       action: 'true',
       exit_status: 0,
      }
    })
    raw_task = Fixman::RawTask.new params
    tasks = raw_task.refine
    assert_equal 1, tasks.size
  end

  def test_substitute_variables
    params = @params.merge({
      command: {
       action: 'true V1 V2 TARGET',
       exit_status: 0,
      },
      variables: [
        { key: 'V1', values: ['1', '2', '3'] },
        { key: 'V2', values: ['1', '3'] },
      ]
    })
    raw_task = Fixman::RawTask.new params
    expected_actions = Set.new [
      'true 1 1 TARGET',
      'true 1 3 TARGET',
      'true 2 1 TARGET',
      'true 2 3 TARGET',
      'true 3 1 TARGET',
      'true 3 3 TARGET',
    ]
    assert_equal expected_actions, raw_task.send(:substitute_variables).to_set

    params[:variables] = [ { key: 'X', values: ['1', '2', '3'] } ]
    raw_task = Fixman::RawTask.new params
    expected_actions = [ 'true V1 V2 TARGET' ]
    assert_equal expected_actions, raw_task.send(:substitute_variables)

    # TODO test empty values array for an existing variable key
  end

  def test_shell_to_proc
    raw_task = Fixman::RawTask.new @params

    p = raw_task.send(:shell_to_proc, 'true', 0)
    assert_equal true, p.call

    p = raw_task.send(:shell_to_proc, 'true', 200)
    assert_equal false, p.call

    p = raw_task.send(:shell_to_proc, 'false', 0)
    assert_equal false, p.call

    p = raw_task.send(:shell_to_proc, 'false', 1)
    assert_equal true, p.call
  end

  def test_refine_condition
    raw_task = Fixman::RawTask.new @params
    p = raw_task.send(:refine_condition)
    assert_equal Proc, p.class
    assert_equal true, p.call

    params = @params.merge({
      condition: {
        type: :ruby,
        action: 'proc { "test me" }'
      }
    })
    raw_task = Fixman::RawTask.new params
    p = raw_task.send(:refine_condition)
    assert_equal 'test me', p.call

    params[:condition] = {
      type: :shell,
      action: 'false',
      exit_status: 1
    }
    raw_task = Fixman::RawTask.new params
    p = raw_task.send(:refine_condition)
    assert_equal true, p.call
  end
end
