require 'English'
require 'stringio'

module Fixman
  class Tester
    TERMINAL_WIDTH = 80

    def initialize(configuration)
      @conf = configuration
      @target_cache = {}
    end

    def test
      @conf.raw_tasks.each do |raw_task|
        raw_task.refine.each do |task|
          puts(test_task task)
        end
      end
    end

    private

    def test_task task
      puts "Collecting targets for #{task.name}..."
      targets = collect task.condition
      failures = []
      puts "Running the #{task.name} on targets..."
      targets.each do |target|
        failures << target unless task.run target
      end
      report task.name, targets, failures
    end

    def collect(condition)
      if @target_cache[condition]
        @target_cache[condition]
      else
        targets = []
        places_to_search = [@conf.fixtures_base]
        places_to_search.each do |place|
          # exclude symbolic links to avoid cycles
          place.each_child do |child|
            next if child.symlink?
            targets << child if condition.call(child)
            places_to_search << child if child.directory?
          end
        end
        @target_cache[condition] = targets
      end
    end

    def report(name, targets, failures)
      n_of_targets = targets.size
      n_of_successes = n_of_targets - failures.size

      sio = StringIO.new
      sio.puts "#{name} (#{n_of_successes}/#{n_of_targets})"
      sio.puts '-' * TERMINAL_WIDTH
      if n_of_successes == n_of_targets
        sio.puts 'All targets ran as expected.'
      else
        sio.puts "Failing targets:"
        sio.puts failures.sort
      end
      sio.puts
      sio.string
    end
  end
end
