module Chainsaw
  class StreamPublisher
    
    def publish(event)
      channel_name = "chainsaw:#{event.stream_identifier}"
    end
    
  end
end