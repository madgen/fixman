require 'optparse'
require 'pathname'
require 'fixman/utilities'

module Fixman
  module CommandLine
    DEFAULT_CONF_FILE = '.fixman_conf.yaml'

    include Utilities

    def parse_options!(args)
      options = {}
      options[:conf_path] =  Pathname.new DEFAULT_CONF_FILE

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{NAME} [option]"

        opts.on_tail('-h', '--help', 'Display this message') do
          puts 'help' # TODO
          exit 0
        end

        opts.on('-v', '--version', 'Display the version') do
          puts VERSION
          exit 0
        end

        opts.on('-c', '--configuration-file PATH') do |path|
          options[:conf_path] = Pathname.new path
        end
      end

      begin
        parser.parse! args
      rescue OptionParser::InvalidaOption
        error usage
      end

      options
    end

    # Options are parsed prior to the positional arguments allowing
    # optional trailing positional arguments.
    def parse_positional_arguments!(raw_args)
      # Error if there are no commands
      error usage if raw_args.size < 1

      command = raw_args.shift.downcase.to_sym
      args = {}

      case command
      when :test, :list, :shortlist, :add
        error usage unless raw_args.size == 0
      when :delete
        error usage unless raw_args.size == 1
        args[:canonical_name] = raw_args.shift
      when :fetch, :upgrade
        args[:groups] = raw_args.map { |group| group.downcase.to_sym }
        raw_args.delete_if {true}
      when :update
        error usage unless [1, 2].include? raw_args.size
        args[:canonical_name], args[:sha] = raw_args.shift 2
      else
        error usage
      end

      [command, args]
    end

    def get_input_interactively(info_defs)
      input_hash = {}
      info_defs.each do |info|
        input_hash[info[:symbol]] =
        if info[:condition]
          get_required_input info[:prompt], info[:condition]
        else
          get_optional_input info[:prompt]
        end
      end
      input_hash
    end

    def usage
      #TODO
    end

    private

    def get_required_input(message, condition)
      loop do
        print message
        input = gets.chomp
        break if condition.call input
      end
      input
    end

    def get_optional_input(message)
      print message
      gets.chomp
    end
  end
end
