module Fixman
  module Utilities
    def error message, exit_code = 1
      STDERR.puts message
      exit exit_code
    end
  end
end
