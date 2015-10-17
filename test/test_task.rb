require 'fixman'
require 'minitest'

class TestTask < MiniTest::Test
  def setup
    @t_proc = proc { true }
    @f_proc = proc { false }
  end

  def test_vanilla_run
    task = Fixman::Task.new 'Task', @t_proc, @t_proc, @t_proc
    assert_equal true, task.run('vanilla_target')

    task = Fixman::Task.new 'Task', @t_proc, @f_proc, @t_proc
    assert_equal false, task.run('vanilla_target')
  end

  def test_run_with_cleanup
    counter = [0]
    cleanup = proc { |c| c[0] += 2 }

    task = Fixman::Task.new 'Task', @t_proc, @t_proc, cleanup
    task.run counter
    assert_equal 2, counter[0]
    task.run counter
    assert_equal 4, counter[0]
  end
end
