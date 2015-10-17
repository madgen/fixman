module Fixman
  class Task
    attr_reader :name, :condition

    def initialize(name, condition, command, cleanup)
      @name = name
      @condition = condition
      @command = command
      @cleanup = cleanup
    end

    def run target
      success = @command.call(target)
      @cleanup.call(target)

      success
    end
  end
end
