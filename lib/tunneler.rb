require "net/scp"
require "net/ssh/gateway"
require "trollop"
require "singleton"
require "time"

module Tunneler

  APPLICATION_ROOT = File.expand_path("..",File.dirname(__FILE__))

  def self.debug
    Config.instance.debug
  end

  def self.debug=(boolean)
    require "debugger" if boolean
    Config.instance.debug = boolean
  end

  def self.log(message, level=:info)
    Logger.log(message, level)
  end

  Gem.find_files("tunneler/**/*.rb").each { |path| require path }
  
end
