module ESignatureHelper

  def nl2br stre
    stre.gsub(/(?:\n\r?|\r\n?)/, '<br>')
  end

  def pretty_string stre, options = {}
    return "" if stre.blank?

    start_time = nil
    as_timestamp = nil

    if stre.is_a?(String) && stre.length >= 8
        if !stre.index(/^\d\d\d\d-\d\d-\d\d.*/)
          # Do Nothing

        elsif (stre.index('t')>=0 && stre.index('z')>=0) || (stre.index('T')>=0 && stre.index('Z')>=0)
            start_time = Date.parse(stre)
            as_timestamp = true
        else
            start_time = Date.parse(stre + 'T00:00:00Z')
            as_timestamp = false
        end
    end

    if !start_time
        if options[:return_string]

            if stre.is_a? Hash
                if stre.length > 0
                  return stre
                else
                  return
                end
            end

            if stre.is_a? String
              if options[:capitalize]
                  if !stre || stre.length < 30
                      return stre.capitalize;
                  else
                      return nl2br(stre);
                  end
              else
                  return nl2br(stre);
              end
            end
        else
            return
        end
    end

    if as_timestamp
        return as_timestamp.new_offset(0)
    else
        return stre.to_s
    end
    return stre
  end
end
