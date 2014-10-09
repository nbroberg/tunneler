module Tunneler
  class Ssh

    SSH_READY_TIMEOUT = 70
    SSH_CONNECTIVITY_TIMEOUT = 15
    ACCEPTABLE_CONNECTIVITY_ERRORS = [Errno::ECONNREFUSED]

    SSH_COMMAND_TIMEOUT = 300

    SCP_OPTIONS = { :recursive => true, :compression => "zlib" }

    def initialize(user, host, options={})
      @user = user
      @host = host
      @options = self.class.merge_options(options)
    end

    def self.default_options
      {
        :paranoid => false,
        :keys => [DEFAULT_SSH_KEY_PATH],
        :timeout => self::SSH_COMMAND_TIMEOUT,
      }
    end

    def self.merge_options(options={})
      if options.empty?
        Ssh.default_options
      else
        Ssh.default_options.merge(options)
      end
    end

    def wait_for_ssh_access
      Timer.timeout("#{@host}: SSH test",self.class::SSH_READY_TIMEOUT) do
        until sshable? do
          Tunneler.log "Waiting between connection attempts", :debug
          sleep 5
        end
      end
    end

    def sshable?
      begin
        return test_connectivity
      rescue Exception => e
        if ACCEPTABLE_CONNECTIVITY_ERRORS.include?(e.class)
          Tunneler.log "Connectivity error: #{e.class} - #{e.message}", :debug
          return false
        else
          raise e
        end
      end
    end

    def test_connectivity
      options_override = @options.clone
      options_override[:timeout] = self.class::SSH_CONNECTIVITY_TIMEOUT
      options_override[:verbose] = :debug if Tunneler.debug
      if ssh("whoami", options_override).strip == @user
        return true
      end
    end

    def ssh(command, options_override={})
      if options_override.empty?
        options = @options
      else
        options = options_override
      end
      output = ""
      Net::SSH.start(@host, @user, @options) do |ssh|
        output = ssh.exec!(command)
      end
      output
    end

    def scp(local_path, remote_path)
      Net::SSH.start(@host, @user, @options) do |ssh|
        ssh.scp.upload!(local_path, remote_path, SCP_OPTIONS)
      end
    end

  end
end
