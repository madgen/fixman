module Fixman
  class TaskParseError < Exception
    def initialize message, task_index
      @message = message
      @task_index = task_index
    end

    def message
      "Task##{@task_index + 1}: #{@message}"
    end
  end
end
