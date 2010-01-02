require 'pathname'
require 'yaml'
require 'logger'

current_dir = Pathname(File.dirname(__FILE__))
$LOAD_PATH.unshift(current_dir.expand_path.to_s)
require current_dir.join("..", "vendor", "gems", "environment")
require 'active_support'

module Chainsaw
  class << self
    
    VERSION = [2, 0, 0, 0]
    
    def version(inc_patch = (VERSION.last != 0))
      VERSION[0, inc_patch ? 4 : 3].join(".")
    end
    
    def root
      @root ||= Pathname(__FILE__).dirname.dirname.expand_path
    end
    
    def env
      @env ||= ActiveSupport::StringInquirer.new(ENV['RACK_ENV'] || 'development')
    end
  
    def env=(environment)
      @env = ActiveSupport::StringInquirer.new(environment.to_s)
    end
    
    def logger
      @logger ||= nil
    end
    
    def logger=(logger)
      @logger = logger
    end
    
    def publisher
      @publisher ||= begin
        config = YAML.load(File.read(root.join("config", "spinderella.yml")))[env]
        Chainsaw::StreamPublisher.new(config)
      end
    end
    
    def boot!
      require_env
      configure_logger
      configure_friendly
      require_models
      require 'chainsaw/web_app'
      require 'chainsaw/stream_publisher'
      true
    end
    
    def configure_friendly
      config = YAML.load(File.read(root.join("config", "database.yml")))[env]
      Friendly.configure(config)
    end
    
    def configure_logger
      self.logger = Logger.new(root.join("log", "#{env}.log").to_s)
    end
    
    def require_env
      # ActiveSupport has annoying warnings due to json issues.
      silence_warnings { Bundler.require_env(self.env) }
      true
    end
    
    def require_models
      require 'chainsaw/stream'
      require 'chainsaw/event'
    end
  
  end
end