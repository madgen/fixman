require 'English'
require 'yaml'
require 'pathname'
require 'fixman/utilities'
require 'fixman/task_parse_error'
require 'classy_hash'

module Fixman
  class Configuration
    DEFAULT_LEDGER_FILE = '.fixman_ledger.yaml'
    DEFAULT_CONF_FILE = '.fixman_conf.yaml'

    CONDITION_OR_CLEANUP_SCHEMA = ->(h) {
      return ':type is mising' unless h.has_key? :type
      unless [:ruby, :shell].include? h[:type]
        return ':type must be one of :ruby or :shell'
      end
      return ':action is mising' unless h.has_key? :action
      return ':action should be a String' unless h[:action].is_a? String

      if h[:type] == :ruby 
        begin
          # Here a misformed Ruby source would also throw an ArgumentError
          raise ArgumentError unless eval(h[:action]).is_a? Proc
        rescue ArgumentError
          return ':action should evaluate to a Proc object'
        end
      elsif h[:type] == :shell && h[:exit_status]
        es = h[:exit_status]
        unless es.is_a?(Integer) && (0..255).include?(es)
          return ':exit_status should be an integer in 0..255 range'
        end
      end

      true
    }

    REPO_INFO_SCHEMA = {
      symbol: Symbol,
      prompt: String,
      label: String,
      type: Symbol,
      choices: [ :optional, [[String]] ]
    }

    TASK_SCHEMA = {
      name: String,
      target_placeholder: [ :optional, String ],
      command: {
        action: String,
        exit_status: [ :optional, 0..255 ]
      },
      condition: [ :optional, CONDITION_OR_CLEANUP_SCHEMA ],
      cleanup: [ :optional, CONDITION_OR_CLEANUP_SCHEMA ],
      groups: [ :optional, [[ String ]] ]
    }

    CONF_SCHEMA = {
      fixtures_base: String,
      fixtures_ledger: [ :optional, String ],
      tasks: ->(tasks) {
        if tasks.is_a?(Array) && tasks.size > 0
          begin
            tasks.all? do |task|
              begin
                CH.validate task, TASK_SCHEMA
              rescue => e
                index = tasks.find_index task
                raise Fixman::TaskParseError.new(e, index)
              end
              true
            end
          rescue Fixman::TaskParseError => e
            e.message
          end
        else
          "a non-empty array"
        end
      },
      groups: [ :optional, [[ String ]] ],
      extra_repo_info: [ :optional, [[ REPO_INFO_SCHEMA ]] ]
    }

    include Fixman::Utilities

    attr_reader :fixtures_base, :fixture_ledger, :raw_tasks, :extra_repo_info, :groups

    def initialize(fixtures_base,
                   fixture_ledger,
                   raw_tasks,
                   groups,
                   extra_repo_info)
      @fixtures_base = Pathname.new(fixtures_base)
      @fixture_ledger = Pathname.new(fixture_ledger)
      @raw_tasks = raw_tasks
      @extra_repo_info = extra_repo_info
      @groups = groups
    end

    class << self
      def read(path_to_conf)
        conf_yaml = YAML.load IO.read(path_to_conf)

        ClassyHash.validate conf_yaml, CONF_SCHEMA
        initialize_defaults conf_yaml

        raw_tasks = conf_yaml[:tasks].map do |task|
          RawTask.new task
        end

        Configuration.new(conf_yaml[:fixtures_base],
                          conf_yaml[:fixture_ledger],
                          raw_tasks,
                          conf_yaml[:groups],
                          conf_yaml[:extra_repo_info])
      end

      def initialize_defaults(conf_hash)
        conf_hash[:tasks].each do |task|
          command = task[:command]
          command[:exit_status] = 0 unless command[:exit_status]
          unless task[:target_placeholder]
            task[:target_placeholder] = 'TARGET'
          end

          condition = task[:condition]
          if !condition
            task[:condition] = {
              type: :ruby,
              action: 'proc { true }'
            }
          elsif condition[:type] == :shell && !condition[:exit_status]
            condition[:exit_status] = 0
          end

          cleanup = task[:cleanup]
          if !cleanup
            task[:cleanup] = {
              type: :ruby,
              action: 'proc { true }'
            }
          end

          task[:variables] = [] unless task[:variables]
        end

        unless conf_hash[:fixture_ledger]
          conf_hash[:fixture_ledger] = DEFAULT_LEDGER_FILE
        end

        [:groups, :extra_repo_info].each do |key|
          conf_hash[key] = [] unless conf_hash[key]
        end

        conf_hash[:extra_repo_info].each do |repo_info|
          repo_info[:prompt] << ' '
        end
      end
    end
  end
end
