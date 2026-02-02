# frozen_string_literal: true

# UI action helpers for NFS Store filestore system specs.
# Provides methods to interact with the filestore browser UI including
# file upload, rename, move, download, and send to trash operations.
#
# This module provides helper methods for common filestore operations:
# - File upload (single and multiple)
# - File selection and menu interactions
# - File rename, move, and trash operations
# - File and folder downloads
# - Folder navigation and expansion
module FilestoreUiActions
  include FeatureHelper

  # Create a new supporting documents activity log entry
  def add_supporting_documents_activity
    # Find and click the add button for supporting documents
    add_btn = find('a.add-item-button', text: /Supporting Documents/i, wait: 10)
    scroll_into_view(add_btn)
    add_btn.click
    finish_page_loading
    finish_form_formatting
  end

  # Save the current activity log form
  def save_supporting_documents_form
    # Find and click the save button
    save_btn = find('button[type="submit"], input[type="submit"]', text: /save/i, wait: 10)
    scroll_into_view(save_btn)
    save_btn.click
    finish_page_loading
  end

  # Wait for the filestore container to be visible
  def wait_for_filestore_container
    # Wait for the container browser outer div which contains the filestore UI
    expect(page).to have_css('.container-browser-outer', wait: 15)
    finish_page_loading
  end

  # Upload a file using the filestore uploader
  # @param file_path [String] path to the file to upload
  # @param wait_for_processing [Boolean] wait for file to appear in the list
  def upload_file_to_filestore(file_path, wait_for_processing: true)
    # Find the file input - it's a visible file input with class nfs-store-fileupload
    file_input = find('input.nfs-store-fileupload[type="file"]', visible: :all, wait: 10)

    # Attach the file
    file_input.attach_file(file_path, make_visible: true)

    return unless wait_for_processing

    # Wait for the upload to complete and file to appear
    filename = File.basename(file_path)
    expect(page).to have_css('.container-browser .container-entry', text: filename, wait: 30)
    finish_page_loading
  end

  # Upload multiple files to the filestore in a single request
  # @param file_paths [Array<String>] array of paths to files to upload
  # @param wait_for_processing [Boolean] wait for all files to appear in the list
  def upload_multiple_files_to_filestore(file_paths, wait_for_processing: true)
    # Find the file input - it supports multiple file selection
    file_input = find('input.nfs-store-fileupload[type="file"]', visible: :all, wait: 10)

    # Attach all files at once
    file_input.attach_file(file_paths, make_visible: true)

    return unless wait_for_processing

    # Wait for all uploads to complete
    file_paths.each do |file_path|
      filename = File.basename(file_path)
      expect(page).to have_css('.container-browser .container-entry', text: filename, wait: 30)
    end
    finish_page_loading
  end

  # Create a temporary test file for upload
  # @param filename [String] name for the file
  # @param content [String] content to put in the file
  # @return [String] path to the created file
  def create_temp_test_file(filename: 'test-document.txt', content: nil)
    content ||= "Test file content - #{SecureRandom.hex}"
    temp_dir = Rails.root.join('tmp', 'test_files')
    FileUtils.mkdir_p(temp_dir)
    file_path = temp_dir.join(filename)
    File.write(file_path, content)
    file_path.to_s
  end

  # Select a file in the filestore browser by clicking its checkbox
  # @param filename [String] name of the file to select
  def select_file_in_browser(filename)
    file_row = find('.container-browser .container-entry', text: filename, wait: 10)
    checkbox = file_row.find('input[type="checkbox"]', visible: :all)
    scroll_into_view(file_row)
    # Use JavaScript to check the checkbox since it may be hidden
    page.execute_script('arguments[0].click();', checkbox)
    sleep 0.5
  end

  # Open the hamburger menu in the filestore browser
  def open_filestore_menu
    hamburger_btn = find('.nfs-store-container-block button.hamburger', wait: 10)
    scroll_into_view(hamburger_btn)
    hamburger_btn.click
    sleep 0.5
    expect(page).to have_css('.dropdown-menu', visible: true)
  end

  # Click "Rename file" in the hamburger menu
  def click_rename_file_menu_item
    rename_link = find('.dropdown-menu a.container-browse-rename-file', text: /Rename file/i, wait: 5)
    rename_link.click
    finish_page_loading
    # Wait for the modal to appear
    expect(page).to have_css('#primary-modal', visible: true, wait: 10)
  end

  # Enter a new name in the rename dialog and submit
  # @param new_name [String] the new filename
  def rename_file_to(new_name)
    within '#primary-modal' do
      # Fill in the new name
      new_name_input = find('input[name="new_name"]', wait: 10)
      new_name_input.set(new_name)

      # Click the rename button
      rename_btn = find('.container-browse-rename-file-submit', wait: 5)
      rename_btn.click
    end
    finish_page_loading
  end

  # Click "Send to trash" in the hamburger menu
  def click_send_to_trash_menu_item
    trash_link = find('.dropdown-menu a.container-browse-trash-submit', text: /Send to trash/i, wait: 5)
    trash_link.click
    finish_page_loading
  end

  # Click the refresh list button in the filestore browser
  def refresh_filestore_list
    refresh_btn = find('.refresh-container-list', visible: :all, wait: 10)
    scroll_into_view(refresh_btn)
    refresh_btn.click
    finish_page_loading
    sleep 1 # Allow time for the list to refresh
  end

  # Check if a file exists in the filestore browser
  # @param filename [String] name of the file to check
  # @return [Boolean] true if the file exists
  def file_exists_in_browser?(filename)
    has_css?('.container-browser .container-entry', text: filename, wait: 5)
  end

  # Check for error alerts on the page
  # @return [Boolean] true if an error alert is present
  def has_error_alert?
    has_css?('.flash .alert-warning', wait: 2) || has_css?('.flash .alert-danger', wait: 2)
  end

  # Get the text of any error alerts
  # @return [String] the error message text
  def error_alert_text
    if has_css?('.flash .alert-warning', wait: 1)
      find('.flash .alert-warning').text
    elsif has_css?('.flash .alert-danger', wait: 1)
      find('.flash .alert-danger').text
    else
      ''
    end
  end

  # Click "Move Files" in the hamburger menu
  def click_move_files_menu_item
    move_link = find('.dropdown-menu a.container-browse-move-files', text: /Move Files/i, wait: 5)
    move_link.click
    finish_page_loading
    # Wait for the move form to appear
    expect(page).to have_css('#primary-modal', visible: true, wait: 10)
  end

  # Enter a folder name and submit the move files action
  # @param folder_name [String] the destination folder name (can be new or existing)
  def move_files_to_folder(folder_name)
    within '#primary-modal' do
      # Fill in the new folder path
      folder_input = find('input[name="new_path"], input[name="new_folder"]', wait: 10)
      folder_input.set(folder_name)

      # Click the move button
      move_btn = find('.container-browse-move-files-submit', wait: 5)
      move_btn.click
    end
    finish_page_loading

    # Wait for the modal to close
    expect(page).not_to have_css('#primary-modal.in', wait: 10)
    sleep 1 # Allow time for the move to complete
  end

  # Click the download button in the filestore browser
  # Downloads currently selected files - single file downloads directly,
  # multiple files download as a zip archive
  def click_download_button
    download_btn = find('button.container-browse-download', wait: 10)
    scroll_into_view(download_btn)
    download_btn.click
    finish_page_loading
  end

  # Check if a folder exists in the filestore browser
  # @param folder_name [String] name of the folder to check
  # @return [Boolean] true if the folder exists
  def folder_exists_in_browser?(folder_name)
    has_css?('.container-browser .container-folder', text: folder_name, wait: 5)
  end

  # Check if an archive folder exists (extracted archive contents)
  # Archive folders have a special "(extracted archive files)" label
  # @param archive_name [String] base name of the archive file (e.g., "dicoms.zip")
  # @return [Boolean] true if the extracted archive folder exists
  def archive_folder_exists_in_browser?(archive_name)
    # Archive folders contain the archive name and have the special tag
    has_css?('.container-browser .container-folder-is-archive', text: archive_name, wait: 30) ||
      has_css?('.container-browser .container-folder', text: /#{Regexp.escape(archive_name)}.*extracted archive/i, wait: 5)
  end

  # Expand a collapsed folder in the filestore browser
  # @param folder_name [String] name of the folder to expand
  def expand_folder(folder_name)
    folder_row = find('.container-browser .container-folder', text: folder_name, wait: 10)
    folder_icon = folder_row.find('.folder-icon[data-toggle="collapse"]', wait: 5)
    scroll_into_view(folder_icon)
    folder_icon.click
    finish_page_loading
    sleep 0.5 # Allow expansion animation
  end

  # Wait for archive extraction to complete
  # After uploading a zip file, the filestore processes it to extract contents
  # @param archive_name [String] the archive filename (e.g., "dicoms.zip")
  # @param timeout [Integer] max seconds to wait for extraction
  def wait_for_archive_extraction(archive_name, timeout: 60)
    # First wait for the archive file to appear
    expect(page).to have_css('.container-browser .container-entry', text: archive_name, wait: 30)

    # Poll for the extracted folder to appear
    start_time = Time.now
    loop do
      refresh_filestore_list
      break if archive_folder_exists_in_browser?(archive_name)
      break if (Time.now - start_time) > timeout

      sleep 2
    end

    expect(archive_folder_exists_in_browser?(archive_name)).to be(true),
                                                               "Archive '#{archive_name}' was not extracted within #{timeout} seconds"
  end

  # Count files in the filestore browser
  # @return [Integer] number of files visible in the browser
  def count_files_in_browser
    all('.container-browser .container-entry').count
  end

  # Get a list of all filenames in the filestore browser
  # @return [Array<String>] array of filenames
  def list_files_in_browser
    all('.container-browser .container-entry .browse-filename').map(&:text)
  end

  # Select multiple files in the filestore browser
  # @param filenames [Array<String>] array of filenames to select
  def select_multiple_files_in_browser(filenames)
    filenames.each do |filename|
      select_file_in_browser(filename)
    end
  end

  # Get path to a fixture file
  # @param relative_path [String] path relative to spec/fixtures/files/
  # @return [String] absolute path to the fixture file
  def fixture_file_path(relative_path)
    Rails.root.join('spec', 'fixtures', 'files', relative_path).to_s
  end
end
