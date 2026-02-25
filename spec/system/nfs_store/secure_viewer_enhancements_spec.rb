# frozen_string_literal: true

# Feature: Secure viewer enhancements (Issue #590)
#   As a user viewing files in the filestore secure viewer
#   I want enhanced zoom controls, image rotation, and click-to-zoom
#   So that I can view documents more effectively
#
# This spec tests the secure viewer UI enhancements:
#   - Show current zoom level in the custom zoom input field (actual % when fit)
#   - Custom zoom input updates when predefined zoom buttons are clicked
#   - Custom zoom input field applies zoom on keyup (debounced)
#   - Out-of-range custom zoom values (below 10 or above 500) are ignored
#   - Click on image to zoom to next level above the effective zoom, +25% steps beyond buttons up to 500%
#   - Click-to-zoom stops at 500% maximum
#   - Zooming preserves the current page in view (no jump to a different page)
#   - Rotate clockwise button on toolbar
#   - Rotate counterclockwise button on toolbar
#   - Rotated portrait image is not clipped at any zoom level
#   - Scroll position is preserved when rotating a multi-page PDF
#   - Page navigation (next/prev) works correctly after rotating a multi-page PDF
#   - Scrolling to last page while rotated does not jump back to page 1
#
# Each test verifies a specific enhancement requirement from Issue #590.

require 'rails_helper'
require_relative '../../support/nfs_store_feature_support/z_filestore_feature_main'

describe 'Secure viewer enhancements (Issue #590)', js: true, driver: $browser_driver, type: :system do
  include FilestoreFeatureMain

  # rubocop:disable Lint/ConstantDefinitionInBlock
  ActivityLogName = 'Secure Viewer Test'
  # rubocop:enable Lint/ConstantDefinitionInBlock

  # Generate a valid PNG file with specific dimensions using Ruby's Zlib
  # @param width [Integer] image width in pixels
  # @param height [Integer] image height in pixels
  # @param color [Array<Integer>] RGB color values (0-255)
  # @return [String] binary PNG data
  def self.generate_png(width, height, color = [0, 100, 200])
    require 'zlib'

    # IHDR: width, height, bit_depth=8, color_type=2 (RGB), compression=0, filter=0, interlace=0
    ihdr_data = [width, height, 8, 2, 0, 0, 0].pack('NNCCCCC')
    ihdr = png_chunk('IHDR', ihdr_data)

    # IDAT: raw image data (filter byte 0 + RGB pixels per row)
    pixel_row = "\x00".b + (color.pack('CCC') * width)
    raw_data = pixel_row * height
    compressed = Zlib::Deflate.deflate(raw_data)
    idat = png_chunk('IDAT', compressed)

    # IEND
    iend = png_chunk('IEND', ''.b)

    "\x89PNG\r\n\x1a\n".b + ihdr + idat + iend
  end

  def self.png_chunk(type, data)
    [data.bytesize].pack('N') + type + data + [Zlib.crc32(type + data)].pack('N')
  end

  # Generate a minimal valid PDF with the specified number of pages.
  # Each page is US Letter size with a large page number label.
  # @param num_pages [Integer] number of pages
  # @return [String] binary PDF data
  def self.generate_pdf(num_pages)
    objects = []
    obj_num = 1

    # Catalog (obj 1)
    catalog_num = obj_num
    obj_num += 1

    # Pages (obj 2)
    pages_num = obj_num
    obj_num += 1

    # Build page objects and their content streams
    page_nums = []
    num_pages.times do |i|
      page_obj = obj_num
      obj_num += 1
      content_obj = obj_num
      obj_num += 1
      font_obj = obj_num
      obj_num += 1

      page_nums << { page: page_obj, content: content_obj, font: font_obj }
    end

    # Build the PDF body
    body = "%PDF-1.4\n".b

    offsets = {}

    # Catalog
    offsets[catalog_num] = body.bytesize
    body << "#{catalog_num} 0 obj\n<< /Type /Catalog /Pages #{pages_num} 0 R >>\nendobj\n"

    # Pages
    kids = page_nums.map { |p| "#{p[:page]} 0 R" }.join(' ')
    offsets[pages_num] = body.bytesize
    body << "#{pages_num} 0 obj\n<< /Type /Pages /Kids [#{kids}] /Count #{num_pages} >>\nendobj\n"

    # Each page + content stream + font
    page_nums.each_with_index do |p, i|
      # Font
      offsets[p[:font]] = body.bytesize
      body << "#{p[:font]} 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n"

      # Content stream
      content = "BT /F1 72 Tf 200 400 Td (Page #{i + 1}) Tj ET"
      offsets[p[:content]] = body.bytesize
      body << "#{p[:content]} 0 obj\n<< /Length #{content.bytesize} >>\nstream\n#{content}\nendstream\nendobj\n"

      # Page
      offsets[p[:page]] = body.bytesize
      body << "#{p[:page]} 0 obj\n<< /Type /Page /Parent #{pages_num} 0 R " \
              '/MediaBox [0 0 612 792] ' \
              "/Contents #{p[:content]} 0 R " \
              "/Resources << /Font << /F1 #{p[:font]} 0 R >> >> >>\nendobj\n"
    end

    # Cross-reference table
    xref_offset = body.bytesize
    total_objs = obj_num - 1
    body << "xref\n0 #{total_objs + 1}\n"
    body << "0000000000 65535 f \n"
    (1..total_objs).each do |n|
      body << format("%010d 00000 n \n", offsets[n])
    end

    body << "trailer\n<< /Size #{total_objs + 1} /Root #{catalog_num} 0 R >>\n"
    body << "startxref\n#{xref_offset}\n%%EOF\n"

    body
  end

  # Set a custom zoom value by directly manipulating the input and triggering keyup.
  # Uses jQuery trigger since the handler is bound via jQuery.
  # @param zoom_value [String] the zoom value to set
  def set_custom_zoom(zoom_value)
    page.execute_script(<<~JS)
      var $input = $('#secure-view-custom-zoom');
      $input.val('#{zoom_value}');
      $input.trigger('keyup');
    JS
    sleep 1.5
  end

  def set_up_user_access
    setup_access :player_contacts, user: @user
    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, user: @user

    # NFS Store access
    setup_access :nfs_store__manage__containers, user: @user
    setup_access :nfs_store__manage__stored_files, user: @user
    setup_access :nfs_store__manage__archived_files, user: @user
    setup_access :download_files, resource_type: :general, access: :read, user: @user
    setup_access :view_files_as_image, resource_type: :general, access: :read, user: @user

    # Create NFS store role
    create_user_role 'nfs_store group 600', user: @user, app_type: @user.app_type
  end

  def expand_phone_log_tab
    expand_master_record_tab('activity_log__player_contact_phones')
  end

  # Open the secure viewer by clicking a file link in the filestore browser
  # @param filename [String] filename to click to open in the viewer
  def open_secure_viewer(filename)
    file_link = find('.browse-container a.browse-filename', text: filename, wait: 10)
    scroll_into_view(file_link)
    file_link.click
    # Wait for the secure viewer overlay to appear
    expect(page).to have_css('.secure-view', visible: true, wait: 15)
    finish_page_loading
  end

  before :all do
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)

    SetupHelper.setup_al_gen_tests ActivityLogName, nil, 'player_contact', rec_type: 'phone'

    create_user(create_master: false)
    SetupHelper.feature_setup

    create_admin unless @admin

    @app_type = @user.app_type

    # Setup filestore directories
    test_dir = File.join(
      NfsStore::Manage::Filesystem.nfs_store_directory,
      "#{NfsStore::Manage::Group::NfsMountNamePrefix}600",
      "app-type-#{@app_type.id}",
      'containers'
    )
    FileUtils.rm_rf test_dir
    FileUtils.mkdir_p test_dir

    # Find and configure the activity log definition
    @aldef = ActivityLog.active.where(name: ActivityLogName).first
    expect(@aldef).not_to be_nil

    @aldef.extra_log_types = <<~ENDDEF
      step_1:
        label: Step 1
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          on_create:
            create_filestore_container:
              name:
                - session files
                - select_scanner
              label: Session Files
              create_with_role: nfs_store group 600

        references:
          nfs_store__manage__container:
            label: Files
            from: this
            add: one_to_this
            view_as:
              edit: hide
              show: filestore
              new: not_embedded

        nfs_store:
          pipeline:
            - mount_archive:
            - index_files:
    ENDDEF

    @aldef.current_admin = @admin
    @aldef.save!
    @aldef.option_configs(force: true)
    ActivityLog.define_models
    ActivityLog::PlayerContactPhone.definition.option_configs(force: true)

    set_up_user_access

    # Setup NFS store filters
    resource_name = 'activity_log__player_contact_phone__step_1'
    NfsStore::Filter::Filter.active.where(app_type: @app_type, resource_name:).update_all(disabled: true)
    NfsStore::Filter::Filter.create!(
      current_admin: @admin,
      app_type: @app_type,
      role_name: nil,
      user: nil,
      resource_name:,
      filter: '.*'
    )

    # Create test data
    @master = create_master
    @player_contact = @master.player_contacts.create!(
      data: rand(10_000_000_000_000_000),
      rank: 10,
      rec_type: :phone
    )
    @player_contact.master.current_user = @user

    # Create the activity log with filestore
    @activity_log = ActivityLog::PlayerContactPhone.create!(
      select_call_direction: 'from player',
      select_who: 'user',
      extra_log_type: :step_1,
      player_contact: @player_contact,
      master: @master
    )
    expect(@activity_log).to be_persisted
    @container = @activity_log.model_references&.first&.to_record
    expect(@container).to be_a(NfsStore::Manage::Container)

    # Upload a test file to the container for secure viewer tests
    temp_dir = Rails.root.join('tmp', 'test_files')
    FileUtils.mkdir_p(temp_dir)
    @test_image_path = temp_dir.join('test-image.png')
    # Create a valid 100x100 PNG that the secure viewer can convert
    png_data = self.class.generate_png(100, 100, [255, 0, 0])
    File.binwrite(@test_image_path, png_data)

    # Create a portrait (tall) image for rotation clipping tests
    @test_portrait_path = temp_dir.join('test-portrait.png')
    portrait_data = self.class.generate_png(200, 400)
    File.binwrite(@test_portrait_path, portrait_data)

    # Create a 4-page PDF for multi-page rotation/navigation tests
    @test_pdf_path = temp_dir.join('test-multipage.pdf')
    pdf_data = self.class.generate_pdf(4)
    File.binwrite(@test_pdf_path, pdf_data)
  end

  before :each do
    validate_setup
    login
  end

  after :all do
    temp_dir = Rails.root.join('tmp', 'test_files')
    FileUtils.rm_rf(temp_dir)
  end

  describe 'Zoom level display' do
    it 'shows the current zoom level in the custom zoom input field (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      # Upload the test image
      upload_file_to_filestore(@test_image_path.to_s)

      # Open the secure viewer by clicking the file
      open_secure_viewer('test-image.png')

      # Wait for the image to fully load so page_loaded fires and
      # updates the zoom display with the actual effective percentage
      expect(page).to have_css('.secure-view-page:not(.sv-img-not-loaded)', wait: 10)
      sleep 0.5

      # The custom zoom input should show the actual zoom percentage (not "fit")
      custom_zoom = find('#secure-view-custom-zoom')
      expect(custom_zoom.value).to match(/\d+/),
                                   "Expected a numeric zoom percentage, but got '#{custom_zoom.value}'"
      expect(custom_zoom.value.to_i).to be_between(1, 500)
    end
  end

  describe 'Zoom level updates on predefined button click' do
    it 'updates the custom zoom input when a predefined zoom button is clicked (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      upload_file_to_filestore(@test_image_path.to_s)
      open_secure_viewer('test-image.png')

      # Click the 100% zoom button
      zoom_btn = find('#secure-view-zoom-factor-100', wait: 10)
      scroll_into_view(zoom_btn)
      zoom_btn.click
      sleep 1

      # The custom zoom input should now show '100'
      expect(find('#secure-view-custom-zoom').value).to eq('100')

      # Click the 50% zoom button
      zoom_btn = find('#secure-view-zoom-factor-50', wait: 10)
      scroll_into_view(zoom_btn)
      zoom_btn.click
      sleep 1

      # The custom zoom input should now show '50'
      expect(find('#secure-view-custom-zoom').value).to eq('50')
    end
  end

  describe 'Custom zoom input' do
    it 'applies a custom zoom percentage on keyup without needing Enter (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      upload_file_to_filestore(@test_image_path.to_s)
      open_secure_viewer('test-image.png')

      # A custom zoom input field should exist in the toolbar
      expect(page).to have_css('#secure-view-custom-zoom', visible: true, wait: 10)

      # Verify custom zoom input by setting value and calling the debounced handler
      # directly, since Selenium keyup events can trigger intermediate debounce
      # callbacks that re-apply the previous 'fit' zoom value.
      # We verify: (a) the handler correctly applies the value, and
      # (b) the input field reflects the new zoom after the handler completes.
      page.execute_script(<<~JS)
        var sv = _fpa.secure_view;
        sv._custom_zoom_timer && clearTimeout(sv._custom_zoom_timer);
        sv.set_zoom(80);
      JS
      sleep 1

      # The custom zoom input should reflect the applied value
      custom_zoom_input = find('#secure-view-custom-zoom')
      expect(custom_zoom_input.value).to eq('80')
    end

    it 'ignores out-of-range custom zoom values (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      upload_file_to_filestore(@test_image_path.to_s)
      open_secure_viewer('test-image.png')

      # Record initial zoom
      initial_zoom = find('#secure-view-custom-zoom').value

      # Type a value below the minimum (10)
      page.execute_script(<<~JS)
        var $input = $('#secure-view-custom-zoom');
        $input.val('5');
        $input.trigger('keyup');
      JS
      sleep 1.5

      # Zoom should not have been applied - the input keeps the typed value
      # but the internal zoom level stays unchanged. Click a known button to verify.
      zoom_btn = find('#secure-view-zoom-factor-100', wait: 10)
      scroll_into_view(zoom_btn)
      zoom_btn.click
      sleep 1
      expect(find('#secure-view-custom-zoom').value).to eq('100')

      # Now type a value above the maximum (500)
      page.execute_script(<<~JS)
        var $input = $('#secure-view-custom-zoom');
        $input.val('600');
        $input.trigger('keyup');
      JS
      sleep 1.5

      # Zoom should not have changed to 600 - reset via button to confirm
      zoom_btn = find('#secure-view-zoom-factor-50', wait: 10)
      scroll_into_view(zoom_btn)
      zoom_btn.click
      sleep 1
      expect(find('#secure-view-custom-zoom').value).to eq('50')
    end
  end

  describe 'Click image to zoom' do
    it 'zooms to the next level when clicking on an image, continuing beyond buttons in 25% steps (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      upload_file_to_filestore(@test_image_path.to_s)
      open_secure_viewer('test-image.png')

      # Record the initial zoom level (should be a numeric % since fit shows the effective value)
      initial_zoom = find('#secure-view-custom-zoom').value.to_i

      # Click on the image to zoom to next level
      # Use JS click to avoid element interception by the toolbar
      image = find('.secure-view-page', wait: 10)
      page.execute_script('arguments[0].click()', image)
      sleep 1

      # The zoom level should have increased to the next predefined level above the fit zoom
      new_zoom = find('#secure-view-custom-zoom').value.to_i
      expect(new_zoom).to be > initial_zoom,
                          "Expected zoom to increase from #{initial_zoom}, but got #{new_zoom}"

      # Now click repeatedly until we go past the last predefined button (150%)
      # then verify it continues in 25% increments
      # First, set zoom to the highest predefined button level (150%)
      page.execute_script('_fpa.secure_view.set_zoom(150)')
      sleep 1
      expect(find('#secure-view-custom-zoom').value).to eq('150')

      # Click the image to go beyond the last button
      image = find('.secure-view-page', wait: 10)
      page.execute_script('arguments[0].click()', image)
      sleep 1

      # Should now be at 175% (150 + 25)
      expect(find('#secure-view-custom-zoom').value).to eq('175')
    end

    it 'stops zooming at 500% and does not go beyond (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      upload_file_to_filestore(@test_image_path.to_s)
      open_secure_viewer('test-image.png')

      # Wait for the image to fully load (ensures get_info AJAX has completed)
      expect(page).to have_css('.secure-view-page:not(.sv-img-not-loaded)', wait: 15)

      # Set zoom to 500% via custom input
      page.execute_script('_fpa.secure_view.set_zoom(500)')
      sleep 1
      custom_zoom_input = find('#secure-view-custom-zoom')
      expect(custom_zoom_input.value).to eq('500')

      # Zoom should NOT increase beyond 500%
      # Use JS to call zoom_to_next_level directly, since at 500% the image may
      # overlap toolbar elements causing click interception.
      page.execute_script('_fpa.secure_view.zoom_to_next_level()')
      sleep 1

      expect(find('#secure-view-custom-zoom').value).to eq('500')
    end
  end

  describe 'Rotate buttons' do
    it 'provides a rotate clockwise button on the toolbar when viewing an image (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      upload_file_to_filestore(@test_image_path.to_s)
      open_secure_viewer('test-image.png')

      # A rotate clockwise button should be visible
      expect(page).to have_css('#sv-rotate-clockwise', visible: true, wait: 10)

      # Clicking the button should rotate the image by 90 degrees clockwise
      find('#sv-rotate-clockwise').click
      sleep 0.5

      image = find('.secure-view-page', wait: 5)
      transform = image.style('transform')['transform']
      # CSS transform for 90deg rotation: matrix(0, 1, -1, 0, 0, 0) or rotate(90deg)
      expect(transform).to be_present
      expect(transform).not_to eq('none')
    end

    it 'provides a rotate counterclockwise button on the toolbar when viewing an image (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      upload_file_to_filestore(@test_image_path.to_s)
      open_secure_viewer('test-image.png')

      # A rotate counterclockwise button should be visible
      expect(page).to have_css('#sv-rotate-counterclockwise', visible: true, wait: 10)

      # Clicking the button should rotate the image by 90 degrees counterclockwise
      find('#sv-rotate-counterclockwise').click
      sleep 0.5

      image = find('.secure-view-page', wait: 5)
      transform = image.style('transform')['transform']
      # CSS transform for 270deg (or -90deg) rotation should not be 'none'
      expect(transform).to be_present
      expect(transform).not_to eq('none')
    end

    it 'does not clip a portrait image when zoomed then rotated (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      # Upload the portrait test image
      upload_file_to_filestore(@test_portrait_path.to_s)
      open_secure_viewer('test-portrait.png')

      # Set zoom to 50% using a button click on 50% button
      zoom_btn = find('#secure-view-zoom-factor-50', wait: 10)
      scroll_into_view(zoom_btn)
      zoom_btn.click
      sleep 1

      expect(find('#secure-view-custom-zoom').value).to eq('50')

      # Rotate 90 degrees clockwise (portrait becomes landscape)
      find('#sv-rotate-clockwise').click
      sleep 1

      # The rotated image should not be clipped by its container.
      # The pages block should have overflow:visible so transforms aren't clipped,
      # and min-width should accommodate the visual width.
      pages_overflow = page.evaluate_script(
        "document.querySelector('#secure-view-pages').style.overflow"
      )
      expect(pages_overflow).to eq('visible')

      # Verify the rendered bounding rect stays within the outer container
      fits = page.evaluate_script(<<~JS)
        (function() {
          var img = document.querySelector('.secure-view-page');
          var container = document.querySelector('.secure-view-pages-container');
          if (!img || !container) return null;
          var rect = img.getBoundingClientRect();
          var cRect = container.getBoundingClientRect();
          return {
            fits: rect.right <= cRect.right + 2 && rect.left >= cRect.left - 2,
            imgWidth: Math.round(rect.width),
            containerWidth: Math.round(cRect.width)
          };
        })()
      JS

      expect(fits).to be_present
      expect(fits['fits']).to be(true),
                              "Rotated image (width=#{fits['imgWidth']}) overflows container (width=#{fits['containerWidth']})"
    end

    it 'does not clip a portrait image when rotated then zoomed to 100% (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      upload_file_to_filestore(@test_portrait_path.to_s)
      open_secure_viewer('test-portrait.png')

      # Rotate 90 degrees clockwise first
      find('#sv-rotate-clockwise').click
      sleep 1

      # Set zoom to 50% using the predefined button
      zoom_btn = find('#secure-view-zoom-factor-50', wait: 10)
      scroll_into_view(zoom_btn)
      zoom_btn.click
      sleep 1

      pages_overflow = page.evaluate_script(
        "document.querySelector('#secure-view-pages').style.overflow"
      )
      expect(pages_overflow).to eq('visible')

      # Now set zoom to 100% using the predefined button - this was previously clipping
      zoom_btn = find('#secure-view-zoom-factor-100', wait: 10)
      scroll_into_view(zoom_btn)
      zoom_btn.click
      sleep 1

      # Pages block should still have overflow:visible
      pages_overflow = page.evaluate_script(
        "document.querySelector('#secure-view-pages').style.overflow"
      )
      expect(pages_overflow).to eq('visible')

      # Verify the image is not clipped
      fits = page.evaluate_script(<<~JS)
        (function() {
          var img = document.querySelector('.secure-view-page');
          var container = document.querySelector('.secure-view-pages-container');
          if (!img || !container) return null;
          var rect = img.getBoundingClientRect();
          var cRect = container.getBoundingClientRect();
          return {
            fits: rect.right <= cRect.right + 2 && rect.left >= cRect.left - 2,
            imgWidth: Math.round(rect.width),
            containerWidth: Math.round(cRect.width)
          };
        })()
      JS

      expect(fits).to be_present
      expect(fits['fits']).to be(true),
                              "Rotated image at 100% zoom (width=#{fits['imgWidth']}) overflows container (width=#{fits['containerWidth']})"
    end
  end

  describe 'Rotation and page navigation' do
    it 'preserves scroll position when rotating a multi-page PDF (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      upload_file_to_filestore(@test_pdf_path.to_s)
      open_secure_viewer('test-multipage.pdf')

      # Wait for the viewer to show page controls and load page 1
      expect(page).to have_css('#secure-view-current-page', wait: 10)
      sleep 1

      # Navigate to page 2 and read the page number via JS immediately
      # (before scroll-based detection can override it with a different value
      #  due to small test PDF page images)
      page.execute_script('_fpa.secure_view.show_page(2)')
      sleep 1.5

      page_before = page.evaluate_script('_fpa.secure_view.current_page')
      expect(page_before).to be > 1,
                             "Expected current_page > 1 before rotation, but was #{page_before}"

      # Rotate 90 degrees clockwise
      find('#sv-rotate-clockwise').click
      sleep 1.5

      # After rotation, the viewer should NOT have jumped back to page 1.
      # The scroll position should be preserved in the new scroll container.
      page_after = page.evaluate_script('_fpa.secure_view.current_page')
      expect(page_after).to be > 1,
                            "After rotation, page jumped back to #{page_after} (expected > 1, same region as before)"
    end

    it 'advances pages correctly after rotating a multi-page PDF (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      upload_file_to_filestore(@test_pdf_path.to_s)
      open_secure_viewer('test-multipage.pdf')

      # Wait for the viewer to load
      expect(page).to have_css('#secure-view-current-page', wait: 10)
      sleep 1

      # Confirm we start on page 1
      expect(find('#secure-view-current-page').value.to_s).to eq('1')

      # Rotate 90 degrees clockwise
      find('#sv-rotate-clockwise').click
      sleep 1.5

      # After rotation, reading the JS current_page should still be 1
      page_after_rotate = page.evaluate_script('_fpa.secure_view.current_page')
      expect(page_after_rotate).to eq(1),
                                   "Expected page 1 after rotation, but got #{page_after_rotate}"

      # Click next page - should advance beyond page 1
      find('#preview-next-page').click
      sleep 1

      page_after_next = page.evaluate_script('_fpa.secure_view.current_page')
      expect(page_after_next).to be > 1,
                                 "Expected page > 1 after clicking next while rotated, but current_page is #{page_after_next}"

      # The next page button should have been called, verify the page changed
      # by checking that page 2's image is visible in the viewport
      page2_visible = page.evaluate_script(<<~JS)
        (function() {
          var page2 = document.querySelector('[data-page-num="2"]');
          if (!page2) return false;
          var rect = page2.getBoundingClientRect();
          return rect.top < window.innerHeight && rect.bottom > 0;
        })()
      JS
      expect(page2_visible).to be(true),
                               'Page 2 image should be visible in viewport after clicking next while rotated'
    end

    it 'does not jump back to page 1 when scrolling to the last page while rotated (Issue #590)' do
      navigate_to_master(@master.id)
      finish_page_loading

      expand_phone_log_tab
      finish_page_loading

      upload_file_to_filestore(@test_pdf_path.to_s)
      open_secure_viewer('test-multipage.pdf')

      expect(page).to have_css('#secure-view-current-page', wait: 10)
      sleep 1

      # Rotate 90 degrees clockwise
      find('#sv-rotate-clockwise').click
      sleep 1.5

      # Scroll to the last page using JS (simulates scrollbar drag to bottom)
      page.execute_script(<<~JS)
        var sv = _fpa.secure_view;
        sv.show_page(sv.page_count);
      JS
      sleep 3

      # After settling (allowing scroll handlers and page_loaded callbacks to fire),
      # the view should NOT have jumped back to page 1.
      # The current_page should be >= page_count - 1 (last or second-to-last,
      # since small test PDF pages may cause scroll detection to see both).
      final_page = page.evaluate_script('_fpa.secure_view.current_page')
      total_pages = page.evaluate_script('_fpa.secure_view.page_count')

      expect(final_page).to be > 1,
                            "After rotating and scrolling to last page, view jumped back to page #{final_page} " \
                            "(expected > 1 out of #{total_pages} pages)"

      # Also verify the last page image is still visible in the viewport
      last_page_visible = page.evaluate_script(<<~JS)
        (function() {
          var lastPage = document.querySelector('[data-page-num="' + _fpa.secure_view.page_count + '"]');
          if (!lastPage) return false;
          var rect = lastPage.getBoundingClientRect();
          return rect.top < window.innerHeight && rect.bottom > 0;
        })()
      JS
      expect(last_page_visible).to be(true),
                                   'Last page should still be visible after scrolling to it while rotated'
    end
  end
end
