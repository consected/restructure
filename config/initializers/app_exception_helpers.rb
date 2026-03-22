# frozen_string_literal: true

module ExceptionExtensions
  #
  # Converts the short backtrace to a string with newlines.
  def short_string_backtrace
    short_backtrace.join("\n")
  end

  #
  # Returns a filtered backtrace containing only lines from the app and spec directories,
  # or the full backtrace if none found.
  def short_backtrace
    res = backtrace.select { |m| m.include?(Rails.root.join('app').to_s) || m.include?(Rails.root.join('spec').to_s) }
    res = backtrace if res.empty?
    res
  end

  #
  # Returns the exception message as a string.
  def short_string_message
    to_s
  end

  #
  # Returns a filtered backtrace for a specified caller,
  # containing only lines from the app and spec directories,
  # or the full backtrace if none found.
  # Converts the result to a string with newlines.
  def self.short_string_backtrace(from_caller)
    res = from_caller.select do |m|
      m.include?(Rails.root.join('app').to_s) || m.include?(Rails.root.join('spec').to_s)
    end
    res = from_caller if res.empty?
    res.join("\n")
  end
end

Exception.include ExceptionExtensions
