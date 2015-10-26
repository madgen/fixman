require 'English'
require 'git'
require 'fileutils'
require 'yaml'

module Fixman
  class Repository
    FIELD_LABEL_WIDTH = 20

    GIT_URL_REGEXP = %r{
      (?:github\.com)\/
      (?<owner>(?:\w|-)+)
      \/
      (?<name>(?:\w|-)+)
      (?:\.git)?
      $
    }xi

    attr_accessor :url, :name, :owner, :sha, :groups, :other_fields
    attr_reader :path

    def initialize(repo_params, fixtures_base, extra_repo_info)
      @url = repo_params[:url]
      @name = repo_params[:name]
      @owner = repo_params[:owner]
      @sha = repo_params[:sha]
      @groups = repo_params[:groups]

      [:url, :name, :owner, :sha, :groups].each { |key| repo_params.delete key }
      @other_fields = repo_params

      @extra_repo_info = extra_repo_info
      @path = fixtures_base + canonical_name
    end

    def fetched?
      File.exist? @path
    end

    def fetch
      git = Git.clone @url, @path
      git.reset_hard @sha
    end

    def upgrade
      git = Git.open @path
      git.pull
      git.reset_hard @sha
    end

    def destroy
      FileUtils.rm_rf @path if File.exist? @path
    end

    def canonical_name
      "#{@owner}/#{@name}"
    end

    def summary
      "#{canonical_name}\t#{@sha}"
    end

    def to_s
      str = StringIO.new
      str.puts 'Repository'.ljust(FIELD_LABEL_WIDTH) + canonical_name
      str.puts 'URL'.ljust(FIELD_LABEL_WIDTH) + @url
      str.puts 'Commit SHA'.ljust(FIELD_LABEL_WIDTH) + @sha
      str.puts 'Groups'.ljust(FIELD_LABEL_WIDTH) + @groups.join(', ')
      @extra_repo_info.each do |info|
        str.puts info[:label].ljust(FIELD_LABEL_WIDTH) +
          @other_fields[info[:symbol]]
      end
      str.string
    end

    def to_yaml
      {
        name: @name,
        owner: @owner,
        sha: @sha,
        url: @url,
        access_right: @access_right,
        notes: @notes
      }.merge(@other_fields).to_yaml
    end

    class << self
      def extract_owner_and_name(url)
        match_data = GIT_URL_REGEXP.match url
        [match_data[:owner], match_data[:name]] if match_data
      end

      def retrieve_head_sha url
        ref = Git.ls_remote url
        ref['head'][:sha]
      end
    end
  end
end
