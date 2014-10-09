module Tunneler
  class SshTunnel

    attr_reader :options

    def initialize(user, host, options={})
      @user = user
      @host = host
      @options = Ssh.merge_options(options)
      
      connect
    end

    def connect
      @gateway = Gateway.connect(@host, @user, @options)
    end

    def remote(user, host, options={})
      Remote.new(@gateway, user, host, Ssh.merge_options(options))
    end

    def terminate
      @gateway.shutdown!
    end

    class Gateway < Net::SSH::Gateway

      def initialize(host, user, options={})
        super
        @host = host
        @user = user
        @options = options
      end

      def self.connect(host, user, options={})
        gateway = self.new(host, user, options)
        gateway.open("127.0.0.1", self.random_open_port)
        gateway
      end

      def self.random_open_port
        socket = Socket.new(:INET, :STREAM, 0)
        socket.bind(Addrinfo.tcp("127.0.0.1", 0))
        socket.local_address.ip_port
      end

      def reconnect
        shutdown!
        self.class.connect(@host,@user,@options)
      end

    end

    class Remote < Ssh

      SSH_READY_TIMEOUT = 100
      ACCEPTABLE_CONNECTIVITY_ERRORS = [Net::SSH::Disconnect, IOError]

      def initialize(gateway, user, host, options={})
        @gateway = gateway
        super(user, host, options)
      end

      def sshable?
        begin
          gateway_reconnect
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

      def gateway_reconnect
        @gateway = @gateway.reconnect
      end

      def ssh(command, options_override={})
        if options_override.empty?
          options = @options
        else
          options = options_override
        end
        output = ""
        @gateway.ssh(@host, @user, @options) do |ssh|
          output = ssh.exec!(command)
        end
        output
      end

      def scp(local_path, remote_path)
        @gateway.ssh(@host, @user, @options) do |ssh|
          ssh.scp.upload!(local_path, remote_path, SCP_OPTIONS)
        end
      end
    end

  end
end
