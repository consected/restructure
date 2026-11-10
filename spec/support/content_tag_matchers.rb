# frozen_string_literal: true

# Lightweight matcher for asserting an HTML string (not a rendered page) contains
# a tag whose attributes include a given fragment, e.g. `class="line-number"`.
# Used for helper specs that return raw HTML strings rather than rendered views.
RSpec::Matchers.define :have_content_tag_with do |tag_name, attribute_fragment|
  match do |html|
    html.to_s.match?(/<#{Regexp.escape(tag_name)}[^>]*#{Regexp.escape(attribute_fragment)}[^>]*>/)
  end

  failure_message do |html|
    "expected the HTML to contain a <#{tag_name}> tag with #{attribute_fragment}, but got:\n#{html}"
  end
end
