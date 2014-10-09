module Tunneler

  DEFAULT_SSH_USER = ENV['USER']

  DEFAULT_SSH_KEY_PATH = "#{ENV['HOME']}/.ssh/id_rsa"

  DEFAULT_LOCAL_TUNNEL_PORT = 9997

  class Config

    include Singleton

    attr_accessor :debug

    def initialize
      @debug = false
    end

  end

end