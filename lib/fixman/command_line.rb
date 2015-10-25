require 'optparse'
require 'pathname'
require 'fixman/utilities'
require 'fixman/configuration'

module Fixman
  module CommandLine

    URL_TEMPLATE = {
      symbol: :url,
      prompt: 'Remote repository URL',
      label: 'URL',
      type: :mandatory
    }

    NAME_TEMPLATE = {
      symbol: :name,
      prompt: 'Repository name',
      label: 'Name',
      type: :mandatory
    }

    OWNER_TEMPLATE = {
      symbol: :owner,
      prompt: 'Owner',
      label: 'Owner',
      type: :mandatory
    }

    GROUPS_TEMPLATE = {
      symbol: :groups,
      prompt: 'Groups',
      label: 'Groups',
      type: :multiple_choice
    }

    include Utilities

    def parse_options!(args)
      options = {}
      options[:conf_path] =
        Pathname.new Fixman::Configuration::DEFAULT_CONF_FILE

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

    def get_params extra_templates, groups
      input = {}
      start_session input, URL_TEMPLATE

      input[:owner], input[:name] =
        Fixman::Repository.extract_owner_and_name input[:url]
      unless input[:owner] && input[:name]
        start_session input, NAME_TEMPLATE
        start_session input, OWNER_TEMPLATE
      end

      unless groups.empty?
        GROUPS_TEMPLATE[:choices] = groups
        start_session input, GROUPS_TEMPLATE
      end

      extra_templates.each do |template|
        start_session input, template
      end

      input[:sha] = Repository.retrieve_head_sha input[:url]

      input
    end

    def usage
      #TODO
    end

    private

    def start_session input, template
      raw_input = nil
      case template[:type]
      when :mandatory
        loop do
          print template[:prompt]
          raw_input = get_input
          break unless raw_input =~ /^\s*$/
        end
      when :optional, nil # nil in the case type is not specified
        print template[:prompt]
        raw_input = get_input
      when :single_choice
        loop do
          puts template[:prompt]
          print "Choose one from #{template[:choices].join('/')}"
          raw_input = get_input
          choice_index =
            template[:choices].map(&:downcase).find_index raw_input.strip.downcase
          if choice_index
            raw_input = template[:choices][choice_index]
            break
          end
        end
      when :multiple_choice
        choices = template[:choices].map(&:strip)
        downcase_choices = choices.map(&:downcase)
        loop do
          puts template[:prompt]
          print "Comma separated multiple choice #{template[:choices].join('/')}"
          raw_input = get_input.split(',').map(&:strip)
          raw_choices = raw_input.map(&:downcase).to_set

          if raw_choices.subset? downcase_choices.to_set
            raw_input =
            raw_choices.inject([]) do |acc, choice|
              i = downcase_choices.find_index choice
              acc << choices[i]
            end
            break
          end
        end
      else
        # TODO error behaviour
      end

      input[template[:symbol]] = raw_input
    end

    def get_input
      gets.chomp
    end
  end
end
