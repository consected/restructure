# frozen_string_literal: true

module HelpHelper
  #
  # Read and process a help document for display
  # @param [String] library
  # @param [String] section
  # @param [String] subsection
  # @return [String]
  def formatted_doc(library, section, subsection)
    where = [
      'docs',
      library.to_s,
      section.to_s,
      "#{subsection}.md"
    ]

    raise FphsException, "invalid help library: #{library}" unless library&.to_s.in? HelpController::ValidLibraries

    path = Rails.root.join(*where)
    raise FphsException, 'invalid request' if path.to_s.include?('..')

    text = if File.exist?(path)
             File.read(path)
           else
             '# page not found'
           end
    text = Formatter::Substitution.text_to_html(text).html_safe

    # It is necessary to fix the image source before the page is rendered,
    # since the browser will immediately attempt to load images with broken paths
    # before they can be fixed in Javascript processors
    ipath = help_doc_path(library, section)
    text = text.gsub(' src="images/', " src=\"#{ipath}/images/")

    Formatter::Substitution.substitute(text, data: current_admin || current_user).html_safe
  end

  #
  # The "full" path to the document, allowing it to
  # prefix markdown supplied relative paths so that they are
  # not treated as relative to the parent page when embedded
  # @param [String] library
  # @param [String] section
  # @return [String]
  def help_doc_path(library, section)
    where = [
      '',
      'help',
      library.to_s,
      section.to_s
    ]
    File.join(*where)
  end
end
