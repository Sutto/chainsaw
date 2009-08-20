require "rubygems"

begin
  require "ruby-debug"
rescue LoadError
end

require "contest"
require File.dirname(__FILE__) + "/../lib/ohm"

Ohm.connect(:port => 6381)
Ohm.flush
