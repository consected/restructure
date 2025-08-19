module ExceptionExtensions
  def short_string_backtrace
    backtrace
      .select { |m| m.include?(Rails.root.join('app').to_s) || m.include?(Rails.root.join('spec').to_s) }
      .join("\n")
  end

  def short_string_message
    to_s
  end
end

class Exception
  include ExceptionExtensions
end
