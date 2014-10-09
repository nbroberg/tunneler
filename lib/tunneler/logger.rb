module Tunneler
  class Logger
    include Singleton
  
    @@session = ""

    LOG_FILE = "#{APPLICATION_ROOT}/log"

    def self.create_log_file
      unless File.exist?(LOG_FILE)
        File.open(LOG_FILE, "w") {}
      end
    end

    def self.log(message, level)
      message = message.to_s
      self.log_to_file(message, level) unless level == :cli
      self.log_to_session(message)
      puts message unless level == :debug && !Tunneler.debug
    end

    def self.log_to_file(message, level)
      self.create_log_file
      @@log ||= File.open(LOG_FILE, "a")
      log_entry = [Time.now.utc.iso8601, level.upcase, message.strip.strip]
      @@log.puts(log_entry.join("\t"))
    end

    def self.log_to_session(message)
      @@session << message + "\n"
    end

    def self.session
      @@session
    end

    def self.truncate_session
      session = @@session
      @@session = ""
      session
    end
  end
end
