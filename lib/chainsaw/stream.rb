require 'digest/sha2'

module Chainsaw
  class Stream
    include Friendly::Document
    
    attribute :api_key,    String
    attribute :identifier, String
    attribute :name,       String
    
    indexes :api_key
    indexes :identifier
    indexes :name
    
    #caches_by :id
    
    def ==(other)
      self.class == other.class && self.identifier == other.identifier
    end
    
    def events(lookup_params = {})
      opts = lookup_params.merge(:stream_identifier => self.identifier, :order! => :created_at.desc)
      Event.all(opts)
    end
    
    def build_event(params = {})
      Event.new(params.merge(:stream_identifier => self.identifier))
    end
    
    def identifier
      @identifier ||= recursive_generate(:identifier) { generate_identifier }
    end
    
    def api_key
      @api_key ||= recursive_generate(:api_key) { generate_api_key }
    end
    
    def valid?
      name.present?
    end
    
    def save
      valid? ? super : false
    end
    
    protected
    
    def generate_identifier(length = 16)
      generate_api_key[0, [64, [length, 16].max].min]
    end
    
    def generate_api_key
      Digest::SHA256.hexdigest(Friendly::UUID.new.to_s)
    end
    
    def recursive_generate(field, &generator)
      # Note: this is only called as a new record.
      # it will be invalid otherwise.
      value = nil
      while value.blank? || (self.class.count(field => value) > 0)
        value = generator.call
      end
      value
    end
    
  end
end