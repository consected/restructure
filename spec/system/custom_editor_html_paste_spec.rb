# frozen_string_literal: true

require 'rails_helper'

# This system spec tests the custom editor (rich text/wysiwyg) in a real browser.
# It exercises:
# - The JavaScript html_to_markdown conversion with various HTML inputs
# - Direct interaction with the custom editor field (typing, pasting, formatting)
# - Toolbar button functionality including links and images
describe 'custom editor', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport
  include CustomEditorSupport

  before(:all) do
    puts "start #{Time.now} custom editor setup"
    SetupHelper.feature_setup

    @admin, = create_admin

    # Create seed data and master records
    seed_database
    create_data_set_outside_tx no_seed: true

    @user, @good_password = create_user nil, '', create_master: true
    @good_email = @user.email

    # Enable markdown editor for notes fields by setting the app configuration
    app_type = @user.app_type

    # Delete any existing config and create fresh one to ensure value is set
    app_type.app_configurations.where(name: 'notes field format').update_all(disabled: true)
    Admin::AppConfiguration.create!(
      name: 'notes field format',
      value: 'markdown',
      app_type: app_type,
      current_admin: @admin
    )

    # Set up access controls for player_infos
    setup_access :player_infos
    setup_access :player_infos, user: @user

    puts "end #{Time.now} custom editor setup"
  end

  after(:all) do
    # Reset the notes field format (set to empty to restore default)
    app_type = Admin::AppType.active.where(name: 'zeus').first
    if app_type
      ac = app_type.app_configurations.active.where(name: 'notes field format').first
      ac&.update!(disabled: true, current_admin: @admin)
    end
  end

  #############################################################################
  # Tests: Direct JavaScript Conversion (html_to_markdown function)
  #############################################################################

  describe 'html_to_markdown JavaScript function' do
    before do
      login_as(@user, scope: :user)
      visit '/masters/search'
      finish_page_loading
      expect(page.evaluate_script('typeof _fpa !== "undefined" && typeof _fpa.utils !== "undefined"')).to be true
    end

    describe 'basic text preservation' do
      it 'preserves plain text content' do
        result = convert_html_to_markdown('<p>Simple text content</p>')
        expect(result['markdown']).to include('Simple text content')
        expect(result['error']).to be_nil
      end

      it 'preserves text with basic formatting' do
        html = '<p>This is <strong>bold</strong> and <em>italic</em> text.</p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('bold')
        expect(result['markdown']).to include('italic')
        expect(result['markdown']).to include('This is')
        expect(result['markdown']).to include('text.')
      end

      it 'preserves multiple paragraphs' do
        html = '<p>First paragraph.</p><p>Second paragraph.</p><p>Third paragraph.</p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('First paragraph')
        expect(result['markdown']).to include('Second paragraph')
        expect(result['markdown']).to include('Third paragraph')
      end
    end

    describe 'list handling' do
      it 'preserves unordered list content' do
        html = '<ul><li>Item one</li><li>Item two</li><li>Item three</li></ul>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Item one')
        expect(result['markdown']).to include('Item two')
        expect(result['markdown']).to include('Item three')
      end

      it 'preserves ordered list content' do
        html = '<ol><li>First</li><li>Second</li><li>Third</li></ol>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('First')
        expect(result['markdown']).to include('Second')
        expect(result['markdown']).to include('Third')
      end

      it 'preserves nested list content' do
        html = '<ul><li>Parent item<ul><li>Child item</li></ul></li></ul>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Parent item')
        expect(result['markdown']).to include('Child item')
      end
    end

    describe 'Microsoft Office HTML handling' do
      it 'preserves text with MsoNormal class paragraphs' do
        html = '<p class="MsoNormal">This is a paragraph with Office formatting.</p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('This is a paragraph with Office formatting')
        expect(result['error']).to be_nil
      end

      it 'handles Office o:p tags without losing text' do
        html = '<p class="MsoNormal">Text before<o:p></o:p> text after</p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Text before')
        expect(result['markdown']).to include('text after')
      end

      it 'handles multiple Office namespace elements' do
        html = '<p class="MsoNormal"><o:p>&nbsp;</o:p>First part<o:p></o:p> middle<o:p>&nbsp;</o:p>last</p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('First part')
        expect(result['markdown']).to include('middle')
        expect(result['markdown']).to include('last')
      end

      it 'handles Word w:* namespace elements' do
        html = '<p class="MsoNormal"><w:sdt>Content</w:sdt></p>'
        result = convert_html_to_markdown(html)
        expect(result['error']).to be_nil
      end

      it 'preserves content from complex Word paste' do
        html = <<~HTML
          <p class="MsoNormal" style="margin-bottom:0in;line-height:normal">
            <span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif">
              Important document text with
              <b>bold emphasis</b>
              and
              <i>italicized words</i>.
            </span>
            <o:p></o:p>
          </p>
        HTML
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Important document text')
        expect(result['markdown']).to include('bold emphasis')
        expect(result['markdown']).to include('italicized words')
      end

      it 'handles empty underline tags from Word' do
        html = '<p class="MsoNormal"><u></u><u></u>Real text here</p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Real text here')
        expect(result['error']).to be_nil
      end

      it 'processes complex Word HTML without losing any text' do
        html = <<~HTML
          <p class="MsoNormal" style="margin-bottom:0in;line-height:normal">
            <u></u><u></u><span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif">
              <o:p></o:p>
            </span>
          </p>
          <p class="MsoNormal" style="margin-bottom:0in;line-height:normal">
            <span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif">
              <b><u>Test </u></b>
              <o:p></o:p>
            </span>
          </p>
          <p class="MsoNormal" style="margin-bottom:0in;line-height:normal">
            <b><span style="font-size:12.0pt;font-family:&quot;Times New Roman&quot;,serif">
              <u>Please retain this text exactly:</u>
            </span></b>
            <o:p></o:p>
          </p>
        HTML
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Test')
        expect(result['markdown']).to include('Please retain this text exactly')
        expect(result['error']).to be_nil
      end
    end

    describe 'table handling' do
      it 'preserves table content' do
        html = '<table><tr><td>Header 1</td><td>Header 2</td></tr><tr><td>Cell 1</td><td>Cell 2</td></tr></table>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Header 1')
        expect(result['markdown']).to include('Header 2')
        expect(result['markdown']).to include('Cell 1')
        expect(result['markdown']).to include('Cell 2')
      end

      it 'preserves table content with proper thead structure' do
        html = '<table><thead><tr><th>Header A</th><th>Header B</th></tr></thead><tbody><tr><td>Data 1</td><td>Data 2</td></tr></tbody></table>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Header A')
        expect(result['markdown']).to include('Header B')
        expect(result['markdown']).to include('Data 1')
        expect(result['markdown']).to include('Data 2')
      end
    end

    describe 'dangerous element removal' do
      it 'removes script tags but preserves surrounding text' do
        html = '<p>Before script</p><script>alert("bad")</script><p>After script</p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Before script')
        expect(result['markdown']).to include('After script')
        expect(result['markdown']).not_to include('alert')
        expect(result['cleanedHtml']).not_to include('<script')
      end

      it 'removes style tags but preserves surrounding text' do
        html = '<p>Before style</p><style>.bad { color: red; }</style><p>After style</p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Before style')
        expect(result['markdown']).to include('After style')
        expect(result['cleanedHtml']).not_to include('<style')
      end
    end

    describe 'empty element handling' do
      it 'removes empty paragraphs but preserves ones with content' do
        html = '<p></p><p>Content paragraph</p><p></p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Content paragraph')
      end

      it 'removes empty divs but preserves ones with content' do
        html = '<div></div><div>Content div</div><div></div>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Content div')
      end

      it 'preserves paragraphs with only whitespace markers like nbsp' do
        html = '<p>&nbsp;</p><p>Real content</p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Real content')
      end
    end

    describe 'link handling' do
      it 'preserves link text and URL' do
        html = '<p>Check out <a href="https://example.com">this link</a> for more.</p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('this link')
        expect(result['markdown']).to include('example.com')
        expect(result['markdown']).to include('Check out')
        expect(result['markdown']).to include('for more')
      end
    end

    describe 'heading handling' do
      it 'preserves heading content' do
        html = '<h1>Main Title</h1><h2>Subtitle</h2><p>Body text</p>'
        result = convert_html_to_markdown(html)
        expect(result['markdown']).to include('Main Title')
        expect(result['markdown']).to include('Subtitle')
        expect(result['markdown']).to include('Body text')
      end
    end
  end

  #############################################################################
  # Tests: Custom Editor Field Interaction (actual UI testing)
  #############################################################################

  describe 'custom editor field interaction' do
    before do
      login_as(@user, scope: :user)

      # Use the master/player_info created by seed_database / create_data_set_outside_tx
      expect(@full_master_record).not_to be_nil, 'Expected @full_master_record from create_data_set_outside_tx'
      expect(@full_player_info).not_to be_nil, 'Expected @full_player_info from create_data_set_outside_tx'

      # Navigate to the master record using the search page with nav_q_id
      visit "/masters/search?nav_q_id=#{@full_master_record.id}"
      finish_page_loading

      # Wait for search results to appear
      expect(page).to have_css('.master-expander', wait: 10)

      # Look for the player info panel and expand it (use master_id since names are capitalized in UI)
      expand_master_record(master_id: @full_master_record.id)
      finish_page_loading
    end

    describe 'editor initialization' do
      it 'renders the custom editor container for notes field' do
        # Find and click edit on the player info
        player_info_block = find('.player-info-item', match: :first)
        within player_info_block do
          edit_link = find('.edit-entity', match: :first)
          scroll_into_view(edit_link)
          edit_link.click
        end
        finish_page_loading

        # Verify the custom editor is rendered (container and editor should exist, toolbar may be hidden)
        expect(page).to have_css('.custom-editor-container', wait: 10)
        expect(page).to have_css('.custom-editor', wait: 10)
        # The toolbar exists but may be hidden until focused
        expect(page).to have_css('.btn-toolbar[data-role="editor-toolbar"]', visible: :all, wait: 10)
      end

      it 'shows the toolbar when editor is focused' do
        player_info_block = find('.player-info-item', match: :first)
        within player_info_block do
          edit_link = find('.edit-entity', match: :first)
          scroll_into_view(edit_link)
          edit_link.click
        end
        finish_page_loading

        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.5

        # Toolbar should be visible
        toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first, visible: true)
        expect(toolbar).to be_visible
      end
    end

    describe 'typing and basic editing' do
      before do
        player_info_block = find('.player-info-item', match: :first)
        within player_info_block do
          edit_link = find('.edit-entity', match: :first)
          scroll_into_view(edit_link)
          edit_link.click
        end
        finish_page_loading
      end

      it 'accepts text input' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        editor.send_keys('Hello, this is a test note.')
        sleep 0.6

        html = editor['innerHTML']
        expect(html).to include('Hello, this is a test note')
      end

      it 'updates the hidden textarea with markdown' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        editor.send_keys('Test markdown content')
        sleep 0.6

        # Blur the editor to trigger update
        find('body').click
        sleep 0.6

        # Find the hidden textarea
        textarea = find('textarea.text-notes', visible: :all, match: :first)
        expect(textarea.value).to include('Test markdown content')
      end
    end

    describe 'paste handling' do
      before do
        player_info_block = find('.player-info-item', match: :first)
        within player_info_block do
          edit_link = find('.edit-entity', match: :first)
          scroll_into_view(edit_link)
          edit_link.click
        end
        finish_page_loading
      end

      it 'handles pasted plain text' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        # Set content and trigger paste event
        page.execute_script(<<~JS)
          var editor = document.querySelector('.custom-editor');
          editor.innerHTML = '<p>Pasted plain text content</p>';
          var pasteEvent = new Event('paste', { bubbles: true, cancelable: true });
          editor.dispatchEvent(pasteEvent);
        JS
        sleep 0.6

        html = editor['innerHTML']
        expect(html).to include('Pasted plain text content')
      end

      it 'handles pasted Microsoft Word HTML' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        word_html = '<p class="MsoNormal">Word document text<o:p></o:p></p>'
        page.execute_script(<<~JS, word_html)
          var editor = document.querySelector('.custom-editor');
          editor.innerHTML = arguments[0];
          var pasteEvent = new Event('paste', { bubbles: true, cancelable: true });
          editor.dispatchEvent(pasteEvent);
        JS
        sleep 0.6

        # Blur to trigger markdown conversion
        find('body').click
        sleep 0.6

        textarea = find('textarea.text-notes', visible: :all, match: :first)
        expect(textarea.value).to include('Word document text')
      end

      it 'handles complex Office HTML without losing text' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        complex_html = <<~HTML
          <p class="MsoNormal" style="margin-bottom:0in">
            <span style="font-size:12.0pt;font-family:'Times New Roman',serif">
              <b><u>Important heading</u></b>
              <o:p></o:p>
            </span>
          </p>
          <p class="MsoNormal">
            Regular paragraph text here.<o:p></o:p>
          </p>
        HTML

        page.execute_script(<<~JS, complex_html)
          var editor = document.querySelector('.custom-editor');
          editor.innerHTML = arguments[0];
          var pasteEvent = new Event('paste', { bubbles: true, cancelable: true });
          editor.dispatchEvent(pasteEvent);
        JS
        sleep 0.6

        find('body').click
        sleep 0.6

        textarea = find('textarea.text-notes', visible: :all, match: :first)
        expect(textarea.value).to include('Important heading')
        expect(textarea.value).to include('Regular paragraph text here')
      end
    end

    describe 'toolbar formatting buttons' do
      before do
        player_info_block = find('.player-info-item', match: :first)
        within player_info_block do
          edit_link = find('.edit-entity', match: :first)
          scroll_into_view(edit_link)
          edit_link.click
        end
        finish_page_loading
      end

      it 'applies bold formatting' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        # Type some text
        editor.send_keys('Bold text test')
        sleep 0.3

        # Select all and apply bold
        editor.send_keys([:control, 'a'])
        sleep 0.2

        toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
        bold_button = toolbar.find("[data-edit='bold']")
        bold_button.click
        sleep 0.3

        html = editor['innerHTML']
        expect(html).to match(%r{<b>.*Bold text test.*</b>}i).or match(%r{<strong>.*Bold text test.*</strong>}i)
      end

      it 'applies italic formatting' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        editor.send_keys('Italic text test')
        sleep 0.3

        editor.send_keys([:control, 'a'])
        sleep 0.2

        toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
        italic_button = toolbar.find("[data-edit='italic']")
        italic_button.click
        sleep 0.3

        html = editor['innerHTML']
        expect(html).to match(%r{<i>.*Italic text test.*</i>}i).or match(%r{<em>.*Italic text test.*</em>}i)
      end

      it 'creates bullet list' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        expect(page).to have_css('.btn-toolbar[data-role="editor-toolbar"]', visible: true, wait: 10)
        toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
        bullet_button = toolbar.find("[data-edit='insertunorderedlist']")
        bullet_button.click
        sleep 0.2

        editor.send_keys('List item one')
        editor.send_keys(:enter)
        editor.send_keys('List item two')
        sleep 0.3

        html = editor['innerHTML']
        expect(html).to include('<ul>')
        expect(html).to include('<li>')
        expect(html).to include('List item one')
        expect(html).to include('List item two')
      end

      it 'creates numbered list' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        expect(page).to have_css('.btn-toolbar[data-role="editor-toolbar"]', visible: true, wait: 10)
        toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
        number_button = toolbar.find("[data-edit='insertorderedlist']")
        number_button.click
        sleep 0.2

        editor.send_keys('First item')
        editor.send_keys(:enter)
        editor.send_keys('Second item')
        sleep 0.3

        html = editor['innerHTML']
        expect(html).to include('<ol>')
        expect(html).to include('<li>')
        expect(html).to include('First item')
        expect(html).to include('Second item')
      end

      it 'applies heading formatting' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        editor.send_keys('This is a heading')
        sleep 0.3

        editor.send_keys([:control, 'a'])
        sleep 0.2

        toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
        h1_button = toolbar.find("[data-edit='formatBlock <h1>']")
        h1_button.click
        sleep 0.3

        html = editor['innerHTML']
        expect(html).to include('<h1>')
        expect(html).to include('This is a heading')
      end

      it 'applies underline formatting' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        editor.send_keys('Underlined text')
        sleep 0.3

        editor.send_keys([:control, 'a'])
        sleep 0.2

        toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
        underline_button = toolbar.find("[data-edit='underline']")
        underline_button.click
        sleep 0.3

        html = editor['innerHTML']
        expect(html).to include('<u>')
        expect(html).to include('Underlined text')
      end

      it 'applies strikethrough formatting' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        editor.send_keys('Strikethrough text')
        sleep 0.3

        editor.send_keys([:control, 'a'])
        sleep 0.2

        toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
        strike_button = toolbar.find("[data-edit='strikethrough']")
        strike_button.click
        sleep 0.3

        html = editor['innerHTML']
        expect(html).to include('<strike>')
        expect(html).to include('Strikethrough text')
      end

      it 'applies subscript formatting' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        editor.send_keys('H2O')
        sleep 0.3

        # Select just the "2"
        page.execute_script(<<~JS)
          var editor = document.querySelector('.custom-editor');
          var range = document.createRange();
          var textNode = editor.firstChild;
          while (textNode && textNode.nodeType !== 3 && textNode.firstChild) {
            textNode = textNode.firstChild;
          }
          range.setStart(textNode, 1);
          range.setEnd(textNode, 2);
          var selection = window.getSelection();
          selection.removeAllRanges();
          selection.addRange(range);
        JS
        sleep 0.2

        toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
        sub_button = toolbar.find("[data-edit='subscript']")
        sub_button.click
        sleep 0.3

        html = editor['innerHTML']
        expect(html).to include('<sub>')
      end

      it 'applies superscript formatting' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        editor.send_keys('X2')
        sleep 0.3

        # Select just the "2"
        page.execute_script(<<~JS)
          var editor = document.querySelector('.custom-editor');
          var range = document.createRange();
          var textNode = editor.firstChild;
          while (textNode && textNode.nodeType !== 3 && textNode.firstChild) {
            textNode = textNode.firstChild;
          }
          range.setStart(textNode, 1);
          range.setEnd(textNode, 2);
          var selection = window.getSelection();
          selection.removeAllRanges();
          selection.addRange(range);
        JS
        sleep 0.2

        toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
        sup_button = toolbar.find("[data-edit='superscript']")
        sup_button.click
        sleep 0.3

        html = editor['innerHTML']
        expect(html).to include('<sup>')
      end

      it 'inserts horizontal rule' do
        editor = find('.custom-editor', match: :first)
        scroll_into_view(editor)
        editor.click
        sleep 0.3

        editor.send_keys('Before rule')
        sleep 0.2

        toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
        hr_button = toolbar.find("[data-edit='inserthorizontalrule']")
        hr_button.click
        sleep 0.3

        editor.send_keys('After rule')
        sleep 0.3

        html = editor['innerHTML']
        expect(html).to include('<hr')
        expect(html).to include('Before rule')
        expect(html).to include('After rule')
      end
    end
  end

  #############################################################################
  # Tests: Advanced toolbar features (links and images) - using dynamic model
  #############################################################################

  describe 'advanced toolbar features with dynamic model' do
    # NOTE: Link and image dropdowns are only available in 'advanced' toolbar mode
    # This requires setting toolbar_type: advanced in the field configuration
    # We create a dynamic model specifically configured for this purpose

    before(:all) do
      # The outer before(:all) should have run first, setting up @user and @full_master_record
      @dm_table_name = 'test_editor_advanced_notes'

      # Create the table if it doesn't exist
      unless ActiveRecord::Base.connection.table_exists?(@dm_table_name)
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TABLE #{@dm_table_name} (
            id SERIAL PRIMARY KEY,
            master_id INTEGER REFERENCES masters(id),
            title VARCHAR(255),
            notes TEXT,
            user_id INTEGER,
            created_at TIMESTAMP,
            updated_at TIMESTAMP
          )
        SQL
      end

      dm_options = <<~YAML
        _configurations: {}

        default:
          fields:
            - title
            - notes

          field_options:
            title:
              no_downcase: true
            notes:
              config:
                toolbar_type: advanced

          view_options:
            data_attribute: title
      YAML

      # Find or create the DynamicModel - don't try to delete (FK constraints on history)
      @advanced_dm = DynamicModel.find_or_initialize_by(table_name: @dm_table_name)
      @advanced_dm.assign_attributes(
        current_admin: @admin,
        name: 'Test Editor Advanced Notes',
        schema_name: 'ml_app',
        category: :details,
        field_list: 'title notes',
        options: dm_options,
        primary_key_name: 'id',
        foreign_key_name: 'master_id',
        disabled: false
      )
      @advanced_dm.save!
      @advanced_dm.current_admin = @admin
      @advanced_dm.update_tracker_events

      # Set up access
      setup_access :"dynamic_model__#{@dm_table_name}", user: @user

      # Force routes reload
      DynamicModel.routes_reload

      # Create a test record - master needs current_user set
      @full_master_record.current_user = @user
      @dm_impl_class = @advanced_dm.implementation_class
      @dm_record = @dm_impl_class.find_or_create_by!(master: @full_master_record) do |r|
        r.title = 'Test Advanced Editor Record'
        r.notes = 'Initial notes content'
      end
    end

    after(:all) do
      # Clean up - disable the dynamic model
      @advanced_dm&.update_columns(disabled: true) if @advanced_dm
    end

    before do
      login_as(@user, scope: :user)
    end

    it 'shows advanced toolbar with link and image buttons' do
      # First, visit the master search to get the full page assets loaded
      visit "/masters/search?nav_q_id=#{@full_master_record.id}"
      finish_page_loading

      # Wait for master expander and expand
      expect(page).to have_css('.master-expander', wait: 10)
      expand_master_record(master_id: @full_master_record.id)
      finish_page_loading

      # Now click on the "new" button for the dynamic model to get the editor form
      new_button = find("a[href*='/dynamic_model/test_editor_advanced_notes/new']", wait: 10)
      scroll_into_view(new_button)
      new_button.click
      finish_page_loading

      # Click on the custom editor to show the toolbar
      editor = find('.custom-editor', match: :first, wait: 10)
      scroll_into_view(editor)
      editor.click
      sleep 0.5

      # Verify advanced toolbar buttons exist (link and image dropdowns)
      toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
      expect(toolbar).to have_css("[data-edit='createLink']", visible: :all)
      expect(toolbar).to have_css("[data-edit='insertImage']", visible: :all)

      # Verify the dropdown toggles have proper dimensions (CSS loaded correctly)
      link_toggle = toolbar.find('a.dropdown-toggle:has(.glyphicon-link)', visible: :all)
      bounding_box = page.evaluate_script('arguments[0].getBoundingClientRect().toJSON()', link_toggle)
      expect(bounding_box['height']).to be > 0, 'Link toggle should have height > 0'
      expect(bounding_box['width']).to be > 0, 'Link toggle should have width > 0'
    end

    it 'can add a link using the toolbar dropdown' do
      # First, visit the master search to get the full page assets loaded
      visit "/masters/search?nav_q_id=#{@full_master_record.id}"
      finish_page_loading

      # Wait for master expander and expand
      expect(page).to have_css('.master-expander', wait: 10)
      expand_master_record(master_id: @full_master_record.id)
      finish_page_loading

      # Click on the "new" button for the dynamic model to get the editor form
      new_button = find("a[href*='/dynamic_model/test_editor_advanced_notes/new']", wait: 10)
      scroll_into_view(new_button)
      new_button.click
      finish_page_loading

      # Click on the custom editor to focus it
      editor = find('.custom-editor', match: :first, wait: 10)
      scroll_into_view(editor)
      editor.click
      sleep 0.5

      # Use JavaScript to set content
      page.execute_script("arguments[0].innerHTML = '<p>Visit our website</p>';", editor)
      sleep 0.3

      # Select all text using JavaScript
      page.execute_script(<<~JS, editor)
        var editor = arguments[0];
        var range = document.createRange();
        range.selectNodeContents(editor);
        var sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
      JS
      sleep 0.2

      # Find the toolbar
      toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)

      # Find and click the dropdown toggle that contains the link glyphicon
      link_toggle = toolbar.find('a.dropdown-toggle:has(.glyphicon-link)')
      scroll_into_view(link_toggle)
      link_toggle.click
      sleep 0.3

      # Fill in the URL in the dropdown menu
      link_input = toolbar.find("input[data-edit='createLink']", visible: true)
      link_input.set('https://example.com')

      # Click Add button
      add_button = link_input.sibling('button', text: 'Add')
      add_button.click
      sleep 0.5

      # Re-find editor and verify the link was added
      editor = find('.custom-editor', match: :first)
      html = editor['innerHTML']
      expect(html).to include('href')
      expect(html).to include('example.com')
    end

    it 'can add an image using the toolbar dropdown' do
      # First, visit the master search to get the full page assets loaded
      visit "/masters/search?nav_q_id=#{@full_master_record.id}"
      finish_page_loading

      # Wait for master expander and expand
      expect(page).to have_css('.master-expander', wait: 10)
      expand_master_record(master_id: @full_master_record.id)
      finish_page_loading

      # Click on the "new" button for the dynamic model to get the editor form
      new_button = find("a[href*='/dynamic_model/test_editor_advanced_notes/new']", wait: 10)
      scroll_into_view(new_button)
      new_button.click
      finish_page_loading

      # Click on the custom editor to focus it
      editor = find('.custom-editor', match: :first, wait: 10)
      scroll_into_view(editor)
      editor.click
      sleep 0.5

      # Find and click the image dropdown toggle - it has the picture glyphicon
      toolbar = find('.btn-toolbar[data-role="editor-toolbar"]', match: :first)
      image_toggle = toolbar.find('a.dropdown-toggle:has(.glyphicon-picture)')
      scroll_into_view(image_toggle)
      image_toggle.click
      sleep 0.3

      # Fill in the image URL in the dropdown menu
      image_input = toolbar.find("input[data-edit='insertImage']", visible: true)
      image_input.set('https://example.com/image.png')

      # Click the Add Image button
      add_button = toolbar.find('button.btn-editor-add-image', visible: true)
      add_button.click
      sleep 0.5

      # Re-find editor and verify the image was added
      editor = find('.custom-editor', match: :first)
      html = editor['innerHTML']
      expect(html).to include('<img')
      expect(html).to include('example.com/image.png')
    end
  end
end
