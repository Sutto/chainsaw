require 'digest/sha2'

module Chainsaw
  class Stream
    include Friendly::Document
    
    self.table_name = "streams"
    
    include Validatable
    
    attribute :api_key,       String
    attribute :identifier,    String
    attribute :short_name,    String
    attribute :name,          String
    attribute :domain_prefix, String
    
    indexes :api_key
    indexes :identifier
    indexes :name
    
    #caches_by :id
    
    # Validations
    validates_presence_of :name
    validates_length_of   :name, :within => (5..255)
    validates_length_of   :short_name, :within => (5..25), :if => lambda { short_name.present? }
    validates_format_of   :domain_prefix, :with => /^\w+$/,
      :message => 'is made up of invalid characters', :if => lambda { domain_prefix.present? }
      
    def self.from_hash(params_hash)
      attrs = {}
      [:name, :short_name, :domain_prefix].each do |key|
        attrs[key] = params_hash[key] if params_hash[key].present?
      end
      self.new(attrs)
    end
    
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
    
    def save
      valid? ? super : false
    end
    
    def as_hash(full_details = false)
      base = {
        :short_name    => self.short_name,
        :name          => self.name,
        :domain_prefix => self.domain_prefix
      }
      if valid?
        base.merge!(:identifier => self.identifier)
        base.merge!(:api_key => self.api_key) if full_details
      else
        base.merge!(:errors => errors.errors)
      end
      base
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