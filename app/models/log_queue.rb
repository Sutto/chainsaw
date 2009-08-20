class LogQueue < Ohm::Model

  MAX_LOG_SIZE = 25
  
  attribute :name
  list      :messages
  list      :recent_messages
  
  index     :name
  
  def validate
    assert_present :name
    assert_unique  :name
  end
  
  def add_message(message)
    messages << message
    recent_messages.shift while recent_messages.size > MAX_LOG_SIZE
    recent_messages << message
  end
  
  def recent
    recent_messages.all
  end
  
  def self.named(name)
    find(:name, name).first || create(:name => name)
  end
  
end