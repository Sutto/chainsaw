module Chainsaw
  class StreamPublisher
    
    def initialize(options = {})
      @options = options
      @host    = (options[:host] || "localhost")
      @port    = (options[:port] || 42341).to_i
      @connection = nil
    end
    
    def publish(event)
      channel_name = "chainsaw/#{event.stream_identifier}".to_json
      connection.write_message("broadcast", {
        "message" => event.message,
        "type"    => "channel",
        "channel" => channel_name
      })
    end
    
    def connection
      if @connection.nil? || !@connection.alive?
        # Create a protocol connection with a keep alive of 10 seconds.
        @connection = Perennial::Protocols::PureRuby::JSONTransport.new(@host, @port, 10.0)
      end
      @connection
    end
    
  end
end