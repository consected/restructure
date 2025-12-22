# frozen_string_literal: true

module ExceptionExtensions
  def short_string_backtrace
    short_backtrace.join("\n")
  end

  def short_backtrace
    backtrace.select { |m| m.include?(Rails.root.join('app').to_s) || m.include?(Rails.root.join('spec').to_s) }
  end

  def short_string_message
    to_s
  end

  def self.short_string_backtrace(from_caller)
    from_caller.select do |m|
      m.include?(Rails.root.join('app').to_s) || m.include?(Rails.root.join('spec').to_s)
    end.join("\n")
  end
end

class Exception
  include ExceptionExtensions
end
