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
      # Patch to add an asynchronous version of upload, that also yields every second and takes into account timeout.
      module UploaderUploadAsync
        def upload_async(info)
          unless info[:repos]
            raise "required repository name"
          end
          info[:repos] = @login + '/' + info[:repos] unless info[:repos].include? '/'

          if info[:file]
            file = info[:file]
            unless File.exist?(file) && File.readable?(file)
              raise "file does not exsits or readable"
            end
            info[:name] ||= File.basename(file)
          end
          unless  info[:file] || info[:data]
            raise "required file or data parameter to upload"
          end

          unless info[:name]
            raise "required name parameter for filename with data parameter"
          end

          if info[:replace]
            list_files(info[:repos]).each { |obj|
              next unless obj[:name] == info[:name]
              delete info[:repos], obj[:id]
            }
          elsif list_files(info[:repos]).any?{|obj| obj[:name] == info[:name]}
            raise "file '#{info[:name]}' is already uploaded. please try different name"
          end

          info[:content_type] ||= 'application/octet-stream'
          stat = HTTPClient.post("https://github.com/#{info[:repos]}/downloads", {
              "file_size"    => info[:file] ? File.stat(info[:file]).size : info[:data].size,
              "content_type" => info[:content_type],
              "file_name"    => info[:name],
              "description"  => info[:description] || '',
              "login"        => @login,
              "token"        => @token
          })

          unless stat.code == 200
            raise "Failed to post file info"
          end

          upload_info = JSON.parse(stat.content)
          if info[:file]
            f = File.open(info[:file], 'rb')
          else
            f = Tempfile.open('net-github-upload')
            f << info[:data]
            f.flush
          end

          client = HTTPClient.new
          client.send_timeout = info[:upload_timeout] if info[:upload_timeout]

          res = begin
            connection = client.post_async("http://github.s3.amazonaws.com/", [
                ['Filename', info[:name]],
                ['policy', upload_info['policy']],
                ['success_action_status', 201],
                ['key', upload_info['path']],
                ['AWSAccessKeyId', upload_info['accesskeyid']],
                ['Content-Type', upload_info['content_type'] || 'application/octet-stream'],
                ['signature', upload_info['signature']],
                ['acl', upload_info['acl']],
                ['file', f]
            ])

            until connection.finished?
              yield if block_given?
              sleep info[:yield_interval] || 1
            end

            connection.pop
          ensure
            f.close
          end

          if res.status == 201
            return FasterXmlSimple.xml_in(res.body.read)['PostResponse']['Location']
          else
            raise 'Failed to upload' + extract_error_message(res.body)
          end
        end
      end


      TYPE = :github
      # Maximum time to allow an upload to continue. An hour to upload a file isn't unreasonable. Better than the default 2 minutes, which uploads about 4MB for me.
      UPLOAD_TIMEOUT = 60 * 60

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

        # Hold off requiring this unless needed, so it doesn't slow down creating tasks.
        if require 'net/github-upload'
          Net::GitHub::Upload.send :include, UploaderUploadAsync
        end

        uploader = Net::GitHub::Upload.new(:login => user, :token => token)

        heading "Deploying #{file} (#{(File.size(file).fdiv 1024).ceil}k) to Github"

        t = Time.now

        begin
          uploader.upload_async :repos => repository, :file => file, :description => description, :replace => @force_replace, :upload_timeout => UPLOAD_TIMEOUT do
            print '.'
          end
          puts '.'
        rescue => ex
          # Probably failed to overwrite an existing file.
          error "Error uploading file #{file}: #{ex.message}"
          exit 1 # This is bad. Lets just die, die, die at this point.
        end

        link = "https://github.com/downloads/#{user}/#{repository}/#{File.basename(file)}"
        time = "%d:%02d" % (Time.now - t).ceil.divmod(60)
        heading %[Successfully uploaded to "#{link}" in #{time}]

        link
      end
    end
  end
end