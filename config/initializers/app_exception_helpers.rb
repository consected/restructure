module ExceptionExtensions
  def short_string_backtrace
    backtrace
      .select { |m| m.include?(Rails.root.to_s) }
      .join("\n")
  end

  def short_string_message
    to_s
      .split("\n")
      .select { |m| m.include?(Rails.root.to_s) }
      .join("\n")
  end
end

class Exception
  include ExceptionExtensions
end
