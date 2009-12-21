module Chainsaw
  class Event
    include Friendly::Document
    
    attribute :stream_identifier, String
    attribute :message,           String
    
    indexes :stream_identifier, :created_at
    
    #caches_by :id
    
    def self.recent_for(stream_id, limit = 25)
      return [] if stream_id.blank?
      all(:stream_identifier => stream_id, :limit! => limit, :order! => :created_at.desc)
    end
    
    def ==(other)
      other.class == self.class && self.stream_identifier == other.stream_identifier && self.message == other.message
    end
    
    def stream
      Stream.first(:identifier => self.stream_identifier)
    end
    
    def valid_message?
      message.present? && JSON.parse(self.message).present?
    rescue
      false
    end
    
    def valid?
      stream_identifier.present? && valid_message?
    end
    
    def save
      if valid? && super
        broadcast!
        true
      else
        false
      end
    end
    
    def broadcast!
      # Chainsaw.broadcaster.publish(self)
    end
    
  end
end