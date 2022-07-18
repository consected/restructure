# frozen_string_literal: true

class HelpController < ApplicationController
  ValidLibraries = %w[guest_reference admin_reference user_reference app_reference dev_reference].freeze
  AcceptableImageFormats = %w[png jpg jpeg svg gif].freeze
  DocumentsDirectory = 'docs'
  IndexSection = 'main'
  IndexSubsection = 'README'
  ImagesSubdirectory = 'images'
  IntroductionDocument = '0_introduction'

  helper_method :library, :section, :subsection

  include HelpHelper

  #
  # Show the default help page for the current authentication or guest
  def index
    return not_found unless request.format.to_sym.in?(%i[html md]) || !request.path.include?('.')

    redirect_to help_page_path(library: library,
                               section: index_section,
                               subsection: index_subsection,
                               display_as: display_as)
  end

  #
  # Show the requested help page
  def show
    redirect_to help_index_path if library.blank? || section.blank? || subsection.blank?

    return not_found unless request.format.to_sym.in?(%i[html md js]) || !request.path.include?('.')

    begin
      @view_doc = view_doc library,
                           section,
                           subsection
    rescue StandardError => e
      @view_doc = view_doc_in_wrapper('<h1>Page Not Found</h1>', library, section)
      @result_status = 404
      Rails.logger.warn(e)
      Rails.logger.warn(e.backtrace.join("\n"))
    end

    if display_embedded?
      render partial: 'help/show_embedded'
    else
      render 'help/show', status: @result_status
    end
  end

  #
  # Handle image requests.
  def image
    return not_found if library.blank? || section.blank?

    where = [DocumentsDirectory, library, section, ImagesSubdirectory, image_file_name]
    path = Rails.root.join(*where)
    return not_found unless File.exist?(path)

    send_file path, filename: image_file_name
  end

  private

  #
  # Return a library name, overriding with the suggested library
  # if the user is authenticated as an admin or user.
  # If a guest (not authenticated), the suggested library if set, must be guest_reference
  # @param [Symbol | String] suggested
  # @return [String]
  def library
    suggested = params[:library]&.to_s
    res = if current_admin
            clean_path(suggested || 'admin_reference')
          elsif current_user
            @index_section = current_user.app_type&.name&.id_underscore
            @index_subsection = IntroductionDocument
            clean_path(suggested || 'app_reference')
          else
            not_authorized if suggested.present? && suggested != 'guest_reference'

            'guest_reference'
          end

    raise FphsException, "invalid help library: #{res}" unless res&.to_s&.in? ValidLibraries

    res
  end

  def index_section
    @index_section ||= IndexSection
  end

  def index_subsection
    @index_subsection ||= IndexSubsection
  end

  #
  # Return the cleaned section name from the :section param
  # @return [String]
  def section
    clean_path(params[:section])
  end

  #
  # Return the cleaned subsection name from the :subsection param
  # or the :id param
  # @return [String]
  def subsection
    clean_path((params[:subsection] || params[:id]).sub(/\.md$/, ''))
  end

  #
  # The file name to use to retrieve the image.
  # The requested image is based on params:
  # <:image_name|:id>.<:format>
  # @return [<Type>] <description>
  def image_file_name
    image_format ||= params[:format]
    image_name = clean_path(params[:image_name] || params[:id])

    unless image_format&.in? AcceptableImageFormats
      raise FphsException, "unacceptable image format requested: #{image_format}"
    end

    raise FphsException, 'blank image name is not allowed' if image_name.blank?

    "#{image_name}.#{image_format}"
  end

  #
  # Don't record this as an action in the log
  def no_action_log
    true
  end

  #
  # Prevent any characters in path components that could lead to
  # directory traversal.
  # The only characters allowed are alphanumeric (upper or lower case)
  # hyphen (-) and underscore (_).
  # Dot and backslash are prevented by this.
  # @param [String] component
  # @return [String]
  def clean_path(component)
    component.to_s.gsub(/[^a-zA-Z0-9\-_]/, '_')
  end

  #
  # How should the requested page be rendered? The only option is 'embedded'
  # in the :display_as param
  def display_as
    params[:display_as]
  end

  #
  # Was the requested page to be displayed embedded, or as a full page?
  def display_embedded?
    display_as == 'embedded'
  end
end
