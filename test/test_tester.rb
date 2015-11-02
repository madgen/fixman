require 'fixman'
require 'minitest'
require 'set'
require 'pry'
require 'pry-byebug'

class TestTester < Minitest::Test
  def setup
    fixtures_base = Pathname.new(Dir.pwd) + 'test' + 'fixtures'
    fixture_ledger = ''
    raw_tasks = []
    extra_repo_info = nil
    groups = nil
    @conf = Fixman::Configuration.new(fixtures_base,
                                      fixture_ledger,
                                      raw_tasks,
                                      groups,
                                      extra_repo_info)
    @condition = proc { |target| target.to_s =~ /\/a.*\.txt/ }
    path_to_repo = Pathname.new(Dir.pwd) + 'test' + 'fixtures' + 'example_repo'
    @expected_targets = ['a123.txt', 'a124.txt', 'a125.txt'].map do |filename|
      path_to_repo + filename
    end
    @expected_targets += ['abc.txt', 'add.txt'].map do |filename|
      path_to_repo + 'sub' + filename
    end
    @cleanup = @command = proc { true }
  end

  def test_collect
    condition = proc { false }
    tester = Fixman::Tester.new @conf
    targets = tester.send(:collect, condition)
    assert_equal [], targets

    tester = Fixman::Tester.new @conf
    targets = tester.send(:collect, @condition)
    assert_equal @expected_targets.to_set, targets.to_set
  end

  def test_test_task_condition_is_applied
    tester = Fixman::Tester.new @conf
    task = Fixman::Task.new 'test_task', @condition, @command, @cleanup
    expected_result = tester.send(:report, 'test_task', @expected_targets, [])
    assert_output(output_for_test_task(task)) do
      assert_equal expected_result, tester.send(:test_task, task)
    end
  end

  def test_test_task_notes_failures
    tester = Fixman::Tester.new @conf
    raw_task = Fixman::RawTask.new({
      name: 'test_task',
      target_placeholder: 'TARGET',
      command: {
        action: 'echo TARGET | sed "s/12//; t suc; q 1; :suc q 0" > /dev/null',
        exit_status: 0
      },
      condition: {
        type: :ruby,
        action: 'proc { true }',
      },
      cleanup: {
        type: :ruby,
        action: 'proc { true }',
      }
    })

    task = raw_task.refine.first
    task.instance_variable_set :@condition, @condition
    assert_output(output_for_test_task(task)) do
      tester.send(:test_task, task)
    end
    failures = @expected_targets.select do |target|
      !(target.to_s =~ /12/)
    end
    expected_result = tester.send(:report, 'test_task', @expected_targets, failures)
    assert_output(output_for_test_task(task)) do
      assert_equal expected_result, tester.send(:test_task, task)
    end
  end

  def output_for_test_task task
    <<-HERE.gsub(/^\s+/, '')
      Collecting targets for #{task.name}...
      Running the #{task.name} on targets...
    HERE
  end
end
