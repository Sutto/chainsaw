require 'irb'

module Chainsaw
  class Console
    
    module BaseExtensions

      def logger
        Chainsaw.logger
      end

    end
    
    def initialize(file = $0)
      @file = file
      setup_irb
    end
    
    def setup_irb
      # This is a bit hacky, surely there is a better way?
      # e.g. some way to specify which scope irb runs in.
      eval("include Chainsaw::Console::BaseExtensions", TOPLEVEL_BINDING)
    end
    
    def run
      ARGV.replace []
      IRB.start
    end
    
    def self.run
      self.new.run
    end
    
  end
end