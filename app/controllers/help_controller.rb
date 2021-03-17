# frozen_string_literal: true

class HelpController < ApplicationController
  before_action :authenticate_user_or_admin!

  AcceptableImageFormats = %w[png jpg jpeg svg gif].freeze

  def index
    return not_authorized unless current_user || current_admin

    @library = if current_admin
                 :admin_reference
               elsif current_user
                 :user_reference
               else
                 :guest_reference
               end

    @section = 'main'
    @subsection = 'README'

    redirect_to help_page_path(library: @library,
                               section: @section,
                               subsection: @subsection,
                               display_as: display_as)
  end

  # Show the requested help page
  def show
    @library ||= params[:library]
    @section ||= params[:section]
    @subsection ||= params[:subsection] || params[:id]

    redirect_to '/help/' if @library.blank? || @section.blank? || @subsection.blank?

    @library = clean_path @library
    @section = clean_path @section
    @subsection = clean_path @subsection

    if display_as == 'embedded'
      render partial: 'help/show_embedded'
    else
      render 'help/show'
    end
  end

  #
  # Handle image requests.
  # @return [<Type>] <description>
  def image
    @library ||= params[:library]
    @section ||= params[:section]
    @image_name ||= params[:image_name] || params[:id]
    @image_format ||= params[:format]

    unless @image_format&.in? AcceptableImageFormats
      raise FphsException, "unacceptable image format requested: #{@image_format}"
    end

    return not_found if @library.blank? | @section.blank?

    @library = clean_path @library
    @section = clean_path @section
    @image_name = clean_path @image_name

    @image_file_name = "#{@image_name}.#{@image_format}"

    where = ['docs', @library, @section, 'images', @image_file_name]
    path = Rails.root.join(*where)
    return not_found unless File.exist?(path)

    send_file path, filename: @image_file_name
  end

  private

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

  def display_as
    params[:display_as]
  end
end
