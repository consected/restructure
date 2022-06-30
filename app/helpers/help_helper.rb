# frozen_string_literal: true

module HelpHelper
  def view_doc(library, section, subsection)
    <<~END_HTML
      #{view_doc_in_wrapper(formatted_doc(library, section, subsection), library, section)}
    END_HTML
      .html_safe
  end

  def view_doc_in_wrapper(doc, library, section)
    <<~END_HTML
      <div id="help-doc-content" class="md-formatted-block" data-doc-path="#{help_doc_path(library, section)}" data-doc-library="#{library}">
        #{doc.html_safe}
      </div>
    END_HTML
      .html_safe
  end

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
             raise 'page not found'
           end

    text = embed_defs(text)

    text = Formatter::Substitution.text_to_html(text).html_safe

    # It is necessary to fix the image source before the page is rendered,
    # since the browser will immediately attempt to load images with broken paths
    # before they can be fixed in Javascript processors
    ipath = help_doc_path(library, section)
    text = text.gsub(' src="images/', " src=\"#{ipath}/images/")

    Formatter::Substitution.substitute(text, data: (current_admin || current_user), ignore_missing: :show_tag).html_safe
  end

  #
  # Embed a config definition from app/models/admin/defs/<item>_def.yaml into
  # a help page where we have the marker:
  #    !defs(<item>)
  # @param [String] text - scan this text
  # @return [String] duplicate of text with substitutions made
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
        defs_yaml = File.read(path)

        content = if defs_yaml.index(/^#+/)
                    defs_yaml
                  else
                    begin
                      defs_content(defs_yaml)
                    rescue StandardError => e
                      "\`substitution Error (#{item.join('/')}): #{e}\`\n"
                    end

                  end

        content = embed_defs(content)
      else
        content = "\`embed definition not found (#{item})\`"
      end

      text = text.gsub("!defs(#{item[0]})", content)
    end

    text
  end

  #
  # Convert config definition YAML into Markdown, for embedding
  # @param [String] defs_yaml - YAML content to convert
  # @return [String]
  def defs_content(defs_yaml)
    defs_content = ''
    data = YAML.safe_load(defs_yaml)

    data.each do |k, v|
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

    defs_content
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

  def main_section
    (section == HelpController::IndexSection ? HelpController::IndexSubsection : HelpController::IntroductionDocument)
  end

  #
  # Clean path components to avoid directory traversal
  def clean_path(component)
    component.to_s.gsub(/[^a-zA-Z0-9\-_]/, '_')
  end
end
