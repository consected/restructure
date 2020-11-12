class DoNothingLogger < ::Logger
  
  def initialize(*args)
    # super
    @formatter = NoneFormatter.new
    # after_initialize if respond_to? :after_initialize
  end

  def add(severity, message = nil, progname = nil, &block)
    true
  end

  def none?                # def debug?
    ::Logger::NONE >= 'fatal'           #   DEBUG >= level
  end                                      # end

  # Simple formatter which only displays the message.
  class NoneFormatter < ::Logger::Formatter
    # This method is invoked when a log event occurs
    def call(severity, timestamp, progname, msg)
      ""
    end
  end
end
