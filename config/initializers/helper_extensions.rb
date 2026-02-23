module ActionView
  module Helpers # :nodoc:
    # Extend JavaScriptHelper
    module JavaScriptHelper
      # The equivalent to the standard `javascript_tag`, removing the cdata section and forcing the type
      def xhtml_script_tag(content_or_options_with_block = nil, html_options = {}, &)
        content =
          if block_given?
            html_options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
            capture(&)
          else
            content_or_options_with_block
          end

        html_options[:nonce] = content_security_policy_nonce if html_options[:nonce] == true

        html_options[:type] ||= 'x-html'

        content_tag('script', content, html_options)
      end
    end
  end
end
