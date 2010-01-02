module Chainsaw
  class StreamPublisher
    
    def initialize(options = {})
      @options = options.symbolize_keys
      @host    = (options[:host] || "localhost")
      @port    = (options[:port] || 42341).to_i
      @connection = nil
      @authenticated = false
    end
    
    def publish(event)
      return false if !authenticated?
      channel_name = "chainsaw/#{event.stream_identifier}".to_json
      connection.write_message("broadcast", {
        "message" => event.message,
        "type"    => "channel",
        "channel" => channel_name
      })
      true
    end
    
    def authenticated?
      connection && @authenticated
    end
    
    def connection
      if @connection.nil? || !@connection.alive?
        # Create a protocol connection with a keep alive of 10 seconds.
        @connection = Perennial::Protocols::PureRuby::JSONTransport.new(@host, @port, 10.0)
        @authenticated = false
        if @options[:password]
          @connection.write_message(:authenticate, :token => @options[:password])
          action, payload = @connection.read_message
          @authenticated = action == "authenticated"
        end
      end
      @connection
    end
    
  end
end