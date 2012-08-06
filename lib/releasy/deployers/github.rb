require 'releasy/deployers/deployer'

module Releasy
  module Deployers
    # Deploys to a Github project's downloads page.
    #
    # @example
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source
    #     add_package :zip
    #     add_deploy :github # Should be enough if git is configured correctly.
    #   end
    #
    # @attr description [String] (project.description) Description of file.
    # @attr user [String] (`git config github.user` or user name in `git config remote.origin.url`) Github user name that has write access to {#repository}
    # @attr repository [String] (repository name in `git config remote.origin.url` or _project.underscored_name_) Name of Github repository.
    # @attr token [String] (`git config github.token`) Github token associated with {#user} - a 32-digit hexadecimal string - DO NOT COMMIT A FILE CONTAINING YOUR GITHUB TOKEN!
    class Github < Deployer
      TYPE = :github
      # Maximum time to allow an upload to continue. An hour to upload a file isn't unreasonable. Better than the default 2 minutes, which uploads about 4MB for me.
      UPLOAD_TIMEOUT = 60 * 60

      Deployers.register self

      def repository; @repository || project.underscored_name; end
      def repository=(repository)
        raise TypeError, "repository must be a String, but received #{repository.class}" unless repository.is_a? String
        @repository = repository
      end

      def user; @user; end
      def user=(user)
        raise TypeError, "user must be a String, but received #{user.class}" unless user.is_a? String
        @user = user
      end

      def token; @token; end
      def token=(token)
        raise TypeError, "token must be a String, but received #{token.class}" unless token.is_a? String
        raise ArgumentError, "token invalid (expected 32-character hex string)" unless token =~ /^[0-9a-f]{32}$/i
        @token = token
      end

      def description; @description || project.description; end
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
        Kernel.`("git config #{key}").chomp rescue nil
      end

      protected
      # @param file [String] Path to file to deploy.
      # @return [nil]
      def deploy(file)
        raise ConfigError, "#user must be set manually if it is not configured on the system" unless user
        raise ConfigError, "#token must be set manually if it is not configured on the system" unless token

        info %[Uploading to: https://github.com/downloads/#{user}/#{repository}/#{File.basename(file)}]

        # libxml-ruby doesn't set path correctly, for no good reason.
        libxml_library_path = File.expand_path "../libs", `gem which libxml`
        ENV['PATH'] = "#{libxml_library_path};#{ENV['PATH']}"
        require 'net/github-upload'

        uploader = Net::GitHub::Upload.new(:login => user, :token => token)

        begin
          uploader.upload :repos => repository, :file => file, :description => description, :replace => @force_replace, :upload_timeout => UPLOAD_TIMEOUT do
            print WORKING_CHARACTER unless log_level == :silent
          end
          info WORKING_CHARACTER
        rescue RuntimeError => ex
          if ex.message =~ /file .* is already uploaded/i
            warn "Skipping '#{File.basename file}' as it is already uploaded. Use #replace! to force uploading"
          else
            raise ex
          end
        end

        nil
      end
    end
  end
end