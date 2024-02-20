# frozen_string_literal: true

class DoNothingLogger < ::Logger
  def initialize(*_args)
    # super
    @formatter = NoneFormatter.new
    # after_initialize if respond_to? :after_initialize
  end

  def add(_severity, _message = nil, _progname = nil)
    true
  end

  def none?
    ::Logger::NONE >= 'fatal'
  end

  def silence(&block)
    block.call
  end

  # Simple formatter which only displays the message.
  class NoneFormatter < ::Logger::Formatter
    # This method is invoked when a log event occurs
    def call(_severity, _timestamp, _progname, _msg)
      ''
    end
  end
end
