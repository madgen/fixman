require 'English'
require 'yaml'
require 'pathname'
require 'fixman/utilities'
require 'classy_hash'

module Fixman
  class Configuration
    DEFAULT_LEDGER_FILE = '.fixman_ledger.yaml'

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
    }]

    REPO_INFO_SCHEMA = {
      symbol: Symbol,
      prompt: String,
      label: String,
      condition: Symbol,
    }

    TASK_SCHEMA = {
      name: String ,
      command: {
        action: String,
        exit_status: 0..255
      },
      condition: [:optional, CONDITION_OR_CLEANUP_SCHEMA],
      cleanup: [:optional, CONDITION_OR_CLEANUP_SCHEMA],
      groups: [:optional, [ String ]]
    }

    CONF_SCHEMA = {
      fixtures_base: String,
      tasks: [[ TASK_SCHEMA ]],
      groups: [:optional, [ String ]],
      extra_repo_info: [:optional, [ REPO_INFO_SCHEMA ]],
    }

    include Fixman::Utilities

    attr_reader :fixtures_base, :fixture_ledger, :raw_tasks, :extra_repo_info

    def initialize(fixtures_base,
                   fixture_ledger,
                   raw_tasks,
                   groups,
                   extra_repo_info)
      @fixtures_base = Pathname.new fixtures_base
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
              type: :ruby
            }
          elsif condition[:type] == :shell && !condition[:exit_status]
            condition[:exit_status] = 0
          end
        end

        conf_hash[:fixture_ledger] = DEFAULT_LEDGER_FILE unless conf_hash[:fixture_ledger]

        [:groups, :extra_repo_info].each do |key|
          conf_hash[key] = [] unless conf_hash[key]
        end
      end
    end
  end
end
