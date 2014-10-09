module Tunneler
  class CommandLine

    def run
      setup_options
      subcommand = process_sub_command
      if @strict_host_checking
        @strict_host_checking_options = ""
      else
        @strict_host_checking_options = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
      end

      Tunneler.debug = @debug

      if subcommand == "ssh"
        ssh
      elsif subcommand == "scp"
        local_file_path = ARGV.shift
        destination_file_path = ARGV.shift
        if local_file_path && destination_file_path
          scp(local_file_path, destination_file_path)
        end
      elsif subcommand == "execute"
        if command = ARGV.shift
          execute(command)
        end
      end
    end

    def execute(command)
      tunnel = SshTunnel.new(@bastion_user, @bastion_host, {:keys => [@bastion_key]})
      destination_host_connection = tunnel.remote(@destination_user, @destination_host, {:keys => [@destination_key]})
      Tunneler.log "Executing remote command '#{command}' on '#{@destination_host}' via '#{@bastion_host}'..."
      Tunneler.log destination_host_connection.ssh(command)
    end

    def scp(local_file_path, destination_file_path)
      tunnel = SshTunnel.new(@bastion_user, @bastion_host, {:keys => [@bastion_key]})
      destination_host_connection = tunnel.remote(@destination_user, @destination_host, {:keys => [@destination_key]})
      Tunneler.log "Uploading '#{local_file_path}' to '#{destination_file_path}' on '#{@destination_host}' via '#{@bastion_host}'..."
      destination_host_connection.scp(local_file_path, destination_file_path)
    end

    def ssh
      destination_key_filename = Pathname.new(@destination_key).basename
      commands = [
        "scp -i #{@bastion_key} #{@destination_key} #{@bastion_user}@#{@bastion_host}:",
        "ssh -i #{@bastion_key} #{@strict_host_checking_options} -A -t -l #{@bastion_user} #{@bastion_host} -L #{DEFAULT_LOCAL_TUNNEL_PORT}:localhost:#{DEFAULT_LOCAL_TUNNEL_PORT} ssh #{@strict_host_checking_options} -A -t -i /home/#{@bastion_user}/#{destination_key_filename} -l #{@destination_user} #{@destination_host} -L #{DEFAULT_LOCAL_TUNNEL_PORT}:localhost:#{DEFAULT_LOCAL_TUNNEL_PORT}",
      ]
      print "Opening ssh connection to '#{@destination_host}' via '#{@bastion_host}'"
      open_terminal(commands.join(" ; "))
      # remove the key as soon as authentication has occurred
      # system "ssh -i #{@bastion_key} #{@strict_host_checking_options} -A -t -l #{@bastion_user} #{@bastion_host} -e 'rm /home/#{@bastion_user}/#{destination_private_key_filename}'"
    end

    def open_terminal(command)
      os = RbConfig::CONFIG['host_os']
      case os
      when /darwin|mac os/
        terminal = ENV['TERM_PROGRAM']
        if terminal =~ /iTerm/
          local_command = "osascript -e 'tell application \"System Events\" to keystroke \"t\" using command down' -e 'tell application \"iTerm\" to tell session -1 of current terminal to write text \"#{command}\"'"
        elsif terminal =~ /Terminal/
          local_command = "osascript -e 'tell application \"Terminal\" to activate' -e 'tell application \"System Events\" to tell process \"Terminal\" to keystroke \"t\" using command down' -e 'tell application \"Terminal\" to do script \"#{command}\" in selected tab of the front window'"
        else
          Tunneler.log "Terminal '#{terminal}' not supported", :cli
          exit
        end
      when /linux/
        local_command = "gnome-terminal -e '#{command}'"
      else
        Tunneler.log "SSH option not available in #{os.inspect}", :warn
        return
      end
      system(local_command)
    end

    def setup_options
      help = self.class.help + "\nParameters:"
      sub_commands = self.class.sub_commands
      options = Trollop::options(ARGV) do
        banner help
        opt :bastion_host, "Tunneler host", :type => :string, :required => true
        opt :bastion_user, "Tunneler SSH user", :type => :string, :default => DEFAULT_SSH_USER
        opt :bastion_key, "Tunneler SSH key path", :type => :string, :default => DEFAULT_SSH_KEY_PATH
        opt :destination_host, "Destination host", :type => :string, :required => true
        opt :destination_user, "Destination SSH user", :type => :string, :default => DEFAULT_SSH_USER
        opt :destination_key, "Destination SSH key path", :type => :string, :default => DEFAULT_SSH_KEY_PATH
        opt :strict_host_checking, "Enable SSH Strict Host Checking", :default => false
        opt :debug, "Enable debug mode"
        stop_on sub_commands
      end
      options.each { |name, value| instance_variable_set("@#{name}", value) }
    end

    def self.help
      "Tunneler CLI - ssh or scp through bastion host tunnel\n\n" +
      "Available subcommands: #{self.sub_commands.join(', ')}\n\n" +
      "Command syntax: tunneler <parameters> <subcommand>\n" + 
      "Examples:       tunneler -b 120.1.2.3 -d 121.2.3.4 ssh\n" +
      "                tunneler -b 120.1.2.3 -d 121.2.3.4 scp local_file destination_file\n" +
      "                tunneler -b 120.1.2.3 -d 121.2.3.4 execute whoami\n"
    end

    def self.sub_commands
      ["ssh", "scp", "execute"]
    end

    def process_sub_command
      sub_command = ARGV.shift
      unless self.class.sub_commands.include?(sub_command)
        if sub_command
          Tunneler.log "Invalid subcommand '#{sub_command}'", :cli
        else
          Tunneler.log "Please specify --help for command information", :cli
        end
        exit
      end
      sub_command
    end

  end
end
