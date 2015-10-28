require 'fileutils'
require 'fixman/utilities'

module Fixman
  class RawTask
    include Utilities

    def initialize params
      # Common to commands, cleanup, condition
      @name = params[:name]
      @target_placeholder = params[:target_placeholder]

      # Command to execute and check exit status
      @command = params[:command]
      @variables = params[:variables] || []

      # Condition to run the task
      @condition = params[:condition]

      # Clean up
      @cleanup = params[:cleanup]
    end

    def refine
      condition_proc = refine_condition
      cleanup_proc = refine_cleanup
      command_procs = refine_command

      command_procs.map do |command_proc|
        Task.new @name, condition_proc, command_proc, cleanup_proc
      end
    end

    private

    # Defines refine_cleanup and refine_condition methods.
    # ivar is the associated instance variable i.e. @condition and @cleanup
    %w(condition cleanup).each do |ivar_name|
      define_method("refine_#{ivar_name}") do
        ivar = instance_variable_get("@#{ivar_name}")

        return proc { true } unless ivar

        result =
        case ivar[:type]
        when :ruby
          eval ivar[:action]
        when :shell
          shell_to_proc ivar[:action], ivar[:exit_status]
        else
          error "Unknown #{ivar_name} type"
        end

        error 'Invalid action' unless result.class == Proc

        result
      end
    end

    def refine_command
      actions = substitute_variables

      actions.map do |action|
        shell_to_proc action, @command[:exit_status]
      end
    end

    def substitute_variables
      actions = [@command[:action]]

      @variables.each do |variable|
        key_regexp = Regexp.new variable[:key]
        actions.map! do |action|
          if key_regexp =~ action
            variable[:values].map { |value| action.gsub(variable[:key], value) }
          else
            action
          end
        end.flatten!
      end

      actions
    end

    def shell_to_proc(shell_command, exit_status)
      proc do |target|
        final_command_str =
        if target
          shell_command.gsub(@target_placeholder, target.to_s)
        else
          shell_command
        end

        final_command_str << ' &> /dev/null'

        system(final_command_str)
        if exit_status
          $CHILD_STATUS.exitstatus == exit_status
        end
      end
    end
  end
end
