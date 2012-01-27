require 'net/github-upload'
require 'releasy/deployers/deployer'

module Releasy
  module Deployers
    # Deploys to a Github project's downloads page.
    #
    # @attr description [String] Description of file (defaults to: "#{project.description")
    # @attr login [String] Github user name that has write access to {#repository} (defaults to: `git config github.user` or user name in `git config remote.origin.url`).
    # @attr repository [String] Name of Github repository (defaults to: the repository name in `git config remote.origin.url` or _project.underscored_name_).
    # @attr token [String] Github token associated with {#login} - a 32-digit hexadecimal string - DO NOT COMMIT A FILE CONTAINING YOUR GITHUB TOKEN (defaults to: `git config github.token`)
    class Github < Deployer
      TYPE = :github

      Deployers.register self

      def repository
        @repository || project.underscored_name
      end
      def repository=(repository)
        raise TypeError, "repository must be a String, but received #{repository.class}" unless repository.is_a? String
        @repository = repository
      end

      attr_reader :user
      def user=(user)
        raise TypeError, "user must be a String, but received #{user.class}" unless user.is_a? String
        @user = user
      end

      attr_reader :token
      def token=(token)
        raise TypeError, "token must be a String, but received #{token.class}" unless token.is_a? String
        raise ArgumentError, "token invalid (expected 32-character hex string)" unless token =~ /^[0-9a-f]{32}$/i
        @token = token
      end

      def description
        @description || project.description
      end
      def description=(description)
        raise TypeError, "description must be a String, but received #{description.class}" unless description.is_a? String
        @description = description
      end

      # Force replacement of existing uploaded files.
      def replace!
        @force_replace = true
      end

      protected
      def setup
        @force_replace = false
        @description = nil

        # Get username from github.user, otherwise use the name taken from the git_url.
        @user = from_config 'github.user'
        @token = from_config 'github.token'

        # Try to guess the repository name from git config.
        git_url = from_config 'remote.origin.url'
        if git_url and git_url =~ %r<^git@github.com:(.+)/([^/]+)\.git$>
          @user ||= $1 # May have already been set from github.user
          @repository = $2
        else
          @repository = nil
        end
      end

      protected
      # Get a value from git config.
      #
      # @param key [String] Name of setting in git config.
      # @return [String, nil] Value of setting, else nil if it isn't defined.
      def from_config(key)
        `git config #{key}`.chomp rescue nil
      end

      protected
      # @param file [String] Path to file to deploy.
      # @return [String] A link to download the file.
      # @raise SystemError If file fails to upload.
      def deploy(file)
        raise ConfigError, "#user must be set manually if it is not configured on the system" unless user
        raise ConfigError, "#token must be set manually if it is not configured on the system" unless token

        uploader = Net::GitHub::Upload.new(:login => user, :token => token)

        heading "Deploying #{file} (#{(File.size(file).fdiv 1024).ceil}k) to Github"

        t = Time.now

        begin
          uploader.upload(:repos => repository, :file => file, :description => description, :replace => @force_replace)
        rescue => ex
          # Probably failed to overwrite an existing file.
          error "Error uploading file #{file}: #{ex.message}"
          exit 1 # This is bad. Lets just die, die, die at this point.
        end

        link = "https://github.com/downloads/#{user}/#{repository}/#{File.basename(file)}"
        heading %[Successfully uploaded to "#{link}" in #{(Time.now - t).ceil}s]

        link
      end
    end
  end
end