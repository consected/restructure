# frozen_string_literal: true

module HelpHelper
  #
  # Read and process a help document for display
  # @param [String] library
  # @param [String] section
  # @param [String] subsection
  # @return [String]
  def formatted_doc(library, section, subsection)
    subsection = clean_path(subsection)
    where = [
      'docs',
      clean_path(library.to_s),
      clean_path(section.to_s),
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

    text = embed_defs(text)

    text = Formatter::Substitution.text_to_html(text).html_safe

    # It is necessary to fix the image source before the page is rendered,
    # since the browser will immediately attempt to load images with broken paths
    # before they can be fixed in Javascript processors
    ipath = help_doc_path(library, section)
    text = text.gsub(' src="images/', " src=\"#{ipath}/images/")

    Formatter::Substitution.substitute(text, data: current_admin || current_user).html_safe
  end

  def embed_defs(text)
    text.scan(/!defs\((.+\.yaml)\)/).each do |item|
      defsw = [
        'app',
        'models',
        'admin',
        'defs',
        clean_path(item[0]).gsub('_yaml', '.yaml')
      ]
      path = Rails.root.join(*defsw)

      if File.exist?(path)
        File.read(path)
      else
        '# embed definition not found'
      end

      defs_content = ''
      YAML.safe_load(File.read(path)).each do |k, v|
        if v.is_a? Hash
          v = v.map do |i|
            <<~END_TEXT
              #### #{i.first}

              #{i.last}
            END_TEXT
          end.join("\n\n")
        end

        defs_content = <<~END_TEXT
          #{defs_content}
          ### #{k}

          #{v}
        END_TEXT
      end

      text = text.gsub("!defs(#{item[0]})", defs_content)
    end

    text
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
      clean_path(library.to_s),
      clean_path(section.to_s)
    ]
    File.join(*where)
  end

  #
  # Clean path components to avoid directory traversal
  def clean_path(component)
    component.to_s.gsub(/[^a-zA-Z0-9\-_]/, '_')
  end
end
