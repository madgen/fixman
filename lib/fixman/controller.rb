require 'fixman/repository'
require 'git'
require 'yaml'

module Fixman
  class Controller
    attr_reader :repos

    def initialize(repos = [])
      @repos = repos
    end

    # Add a new repository to the collection.
    def add(input, fixtures_base, extra_repo_info)
      repo = Repository.new input, fixtures_base, extra_repo_info

      @repos << repo
    end

    # Remove repository from the fixtures list.
    def delete(canonical_name)
      repo = find canonical_name

      if repo
        @repos.delete repo
        repo.destroy
      else
        fail ArgumentError
      end
    end

    # Download repositories belonging to the at least one of the given groups.
    def fetch(groups)
      repos = find_by_groups(groups).reject { |repo| repo.fetched? }
      repos.each do |repo|
        begin
          repo.fetch
        rescue Git::GitExecuteError => error
          STDERR.puts "Warning: Repository #{repo.canonical_name} could not be fetched."
          STDERR.puts error.message
        end
      end
    end

    def update(canonical_name, sha = nil)
      repo = find canonical_name
      fail ArgumentError unless repo

      repo.sha = sha || repo.retrieve_head_sha
    end

    def upgrade(groups)
      repos = find_by_groups(groups) 
      repos.each do |repo| 
        begin
          repo.upgrade
        rescue Git::GitExecuteError => error
          STDERR.puts "Warning: Repisotiry #{repo.canonical_name} could not be \"
            upgraded."
          STDERR.puts error.message
        end
      end
    end

    class << self
      # Controller for the command line interface.
      def open(conf)
        original_ledger = ""

        controller =
        begin
          original_ledger = YAML.load(IO.read conf.fixture_ledger)
          original_ledger.map! { |entry| YAML.load entry } 

          repos = []
          original_ledger.each do |repo_params|
            repos << Repository.new(repo_params,
                                    conf.fixtures_base,
                                    conf.extra_repo_info)
          end

          Controller.new repos
        rescue Errno::ENOENT
          Controller.new
        end

        result = yield controller

        write_ledger controller.repos, original_ledger, conf.fixture_ledger

        result
      rescue Git::GitExecuteError => error
        puts error.message
        exit 1
      end

      private

      def write_ledger(repos, original_ledger, fixture_ledger)
        new_ledger = YAML.dump repos.map(&:to_yaml)
        if new_ledger != original_ledger
          IO.write fixture_ledger, new_ledger
        end
      end
    end

    private

    def find_by_groups(groups)
      if groups.empty?
        @repos
      else
        @repos.select { |repo| !(repo.groups & groups).empty? }
      end
    end

    def find(canonical_name)
      @repos.find { |repo| canonical_name == repo.canonical_name }
    end
  end
end
