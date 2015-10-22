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

    CONDITION_OR_CLEANUP_SCHEMA = [
      {
        type: CH::G.enum(:ruby),
        action: ->(v) {
          v.is_a?(String) && eval(v).is_a?(Proc) ||
          'Action is not a valid Proc object'
        }
      },
      {
        type: CH::G.enum(:shell),
        action: String,
        exit_status: 0..255
      }
    ]

    REPO_INFO_SCHEMA = {
      symbol: Symbol,
      prompt: String,
      label: String,
      type: Symbol,
      choices: [:optional, [String]]
    }

    TASK_SCHEMA = {
      name: String ,
      target_placeholder: [:optional, String],
      command: {
        action: String,
        exit_status: [:optional, 0..255]
      },
      condition: [:optional, CONDITION_OR_CLEANUP_SCHEMA],
      cleanup: [:optional, CONDITION_OR_CLEANUP_SCHEMA],
      groups: [:optional, [ String ]]
    }

    CONF_SCHEMA = {
      fixtures_base: String,
      fixtures_ledger: [:optional, String],
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
      groups: [:optional, [ String ]],
      extra_repo_info: [:optional, [ REPO_INFO_SCHEMA ]]
    }

    include Fixman::Utilities

    attr_reader :fixtures_base, :fixture_ledger, :raw_tasks, :extra_repo_info

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

    def extract_repo_input_condition(extra_repo_info)
      opt = extra_repo_info[:optional]
      cho = extra_repo_info[:choices]

      if opt && cho
        ->(input) { (cho + [:'']).include? input }
      elsif opt && !cho
        proc { true }
      elsif !opt && cho
        ->(input) { cho.include? input }
      elsif !opt && !cho
        ->(input) { !(input =~ /^\s+$/) }
      end
    end

    def refine_extra_repo_info(extra_repo_info)
      extra_repo_info.map do |info|
        {
          symbol: info[:symbol],
          prompt: info[:prompt],
          label: info[:label],
          condition: extract_repo_input_condition(extra_repo_info)
        }
      end
    end

    class << self
      def read(path_to_conf)
        conf_yaml = YAML.load IO.read(path_to_conf)

        ClasyHash.validate conf_yaml, CONF_SCHEMA
        initialize_defaults conf_yaml

        raw_tasks = conf_yaml[:tasks].map do |task|
          RawTask.new task
        end

        extra_repo_info = refine_extra_repo_info conf_yaml[:extra_repo_info]

        Configuration.new conf_yaml[:fixtures_base],
                          raw_tasks,
                          extra_repo_info,
                          conf_yaml[:groups]
                          conf_yaml[:fixture_ledger]
      end

      def initialize_defaults(conf_hash)
        conf_hash[:tasks].each do |task|
          command = task[:command]
          command[:exit_status] = 0 unless command[:exit_status]

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
      end
    end
  end
end
