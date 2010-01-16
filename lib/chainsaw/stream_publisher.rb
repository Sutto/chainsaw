require 'active_support'

module Chainsaw
  class StreamPublisher
    
    class Error          < StandardError; end
    class BroadcastError < Error; end
    
    attr_reader :spinderella
    
    def initialize(options = {})
      @options = (options || {}).symbolize_keys
      @spinderella = Spinderella::Client::Broadcaster.new(@options)
    end
    
    def publish(event)
      if authenticated?
        channel_name = "chainsaw/#{event.stream_identifier}"
        @spinderella.broadcast_to_channel(event.message, channel_name)
        true
      end
    end
    
    def authenticated?
      spinderella && spinderella.authenticated?
    end
    
  end
end