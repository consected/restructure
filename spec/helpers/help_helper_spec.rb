# frozen_string_literal: true

# HelpHelper Spec
#
# Tests helper methods used by the Help system for documentation rendering and navigation.
#
# Test Coverage:
# - #main_section: Returns the appropriate navigation target for the "back to main section" link
#   - Returns IndexSubsection when viewing the index section
#   - When viewing the shared `general` section:
#     - Returns the validated back_path param so users are returned to the
#       detailed_options page that linked them here (passed as a URL param by the JS)
#     - Rejects back_path values that don't conform to /help/<segment>/<segment>[/<segment>]
#     - Falls back to IntroductionDocument when no valid back_path is present
#   - Returns IntroductionDocument for all other sections
# - #display_embedded?: Returns true when display_as param is 'embedded', false otherwise
#   - Defined in HelpHelper (not just HelpController) so it is available in any view context,
#     including views rendered by PageLayoutsController (fixes issue #1134)
# - #formatted_doc: Reads a markdown doc file and renders it as HTML
#   - The substitutions.md doc must be rendered as HTML (not raw markdown text)
#   - Even when the markdown source contains HTML-like tags in code examples (e.g. <br>),
#     the page should still be rendered through the Kramdown markdown processor
#   - The rendered page must include documentation for {{#is ...}} conditional processing

require 'rails_helper'

RSpec.describe HelpHelper, type: :helper do
  include ModelSupport

  describe '#main_section' do
    # `section` is a HelpController helper_method delegated to the controller,
    # so it is not defined on ActionView::Base. We define it on the singleton class.
    def stub_section(value)
      helper.singleton_class.define_method(:section) { value }
    end

    context 'when viewing the index section' do
      before { stub_section(HelpController::IndexSection) }

      it 'returns the IndexSubsection' do
        expect(helper.main_section).to eq(HelpController::IndexSubsection)
      end
    end

    context 'when viewing the general section' do
      before { stub_section('general') }

      context 'with a valid activity_logs back_path param' do
        before { controller.params[:back_path] = '/help/admin_reference/activity_logs/detailed_options' }

        it 'returns the back_path' do
          expect(helper.main_section).to eq('/help/admin_reference/activity_logs/detailed_options')
        end
      end

      context 'with a valid dynamic_models back_path param' do
        before { controller.params[:back_path] = '/help/admin_reference/dynamic_models/detailed_options' }

        it 'returns the back_path' do
          expect(helper.main_section).to eq('/help/admin_reference/dynamic_models/detailed_options')
        end
      end

      context 'with a two-segment back_path' do
        before { controller.params[:back_path] = '/help/admin_reference/activity_logs' }

        it 'returns the back_path' do
          expect(helper.main_section).to eq('/help/admin_reference/activity_logs')
        end
      end

      context 'with no back_path param' do
        it 'falls back to IntroductionDocument' do
          expect(helper.main_section).to eq(HelpController::IntroductionDocument)
        end
      end

      context 'with a back_path containing path traversal' do
        before { controller.params[:back_path] = '/help/admin_reference/../../../etc/passwd' }

        it 'falls back to IntroductionDocument' do
          expect(helper.main_section).to eq(HelpController::IntroductionDocument)
        end
      end

      context 'with a back_path not starting with /help/' do
        before { controller.params[:back_path] = '/admin/users/1' }

        it 'falls back to IntroductionDocument' do
          expect(helper.main_section).to eq(HelpController::IntroductionDocument)
        end
      end

      context 'with a back_path that has too many segments' do
        before { controller.params[:back_path] = '/help/a/b/c/d/e' }

        it 'falls back to IntroductionDocument' do
          expect(helper.main_section).to eq(HelpController::IntroductionDocument)
        end
      end
    end

    context 'when viewing a non-general, non-index section' do
      before { stub_section('activity_logs') }

      it 'returns IntroductionDocument regardless of params' do
        controller.params[:back_path] = '/help/admin_reference/general/save_trigger'
        expect(helper.main_section).to eq(HelpController::IntroductionDocument)
      end
    end
  end

  describe '#display_embedded?' do
    context 'when display_as param is "embedded"' do
      before { controller.params[:display_as] = 'embedded' }

      it 'returns true' do
        expect(helper.display_embedded?).to be true
      end
    end

    context 'when display_as param is absent' do
      it 'returns false' do
        expect(helper.display_embedded?).to be false
      end
    end

    context 'when display_as param is a different value' do
      before { controller.params[:display_as] = 'full' }

      it 'returns false' do
        expect(helper.display_embedded?).to be false
      end
    end
  end

  describe '#formatted_doc' do
    before do
      allow(helper).to receive(:current_admin).and_return(nil)
      allow(helper).to receive(:current_user).and_return(nil)
    end

    context 'with message template overrides' do
      def create_help_message_template(template:, name: 'general/substitutions', category: 'admin_reference',
                                       message_type: :dialog, template_type: :content, disabled: false)
        @admin ||= create_admin.first
        Admin::MessageTemplate.create!(name:, category:, message_type:, template_type:, template:, disabled:,
                                       current_admin: @admin)
      end

      it 'falls back to the markdown file when no matching template exists' do
        expect(helper.formatted_doc('admin_reference', 'general', 'substitutions')).to include('{{#is')
      end

      it 'uses an active matching dialog content template without reading the markdown file' do
        create_help_message_template(template: 'Help template override marker')
        doc_path = Rails.root.join('docs', 'admin_reference', 'general', 'substitutions.md')

        expect(File).not_to receive(:read).with(doc_path)
        expect(helper.formatted_doc('admin_reference', 'general', 'substitutions'))
          .to include('Help template override marker')
      end

      it 'ignores inactive matching templates' do
        create_help_message_template(template: 'Inactive override marker', disabled: true)

        rendered = helper.formatted_doc('admin_reference', 'general', 'substitutions')

        expect(rendered).to include('{{#is')
        expect(rendered).not_to include('Inactive override marker')
      end

      it 'ignores content templates with a non-dialog message type' do
        create_help_message_template(template: 'Email override marker', message_type: :email)

        rendered = helper.formatted_doc('admin_reference', 'general', 'substitutions')

        expect(rendered).to include('{{#is')
        expect(rendered).not_to include('Email override marker')
      end

      it 'ignores dialog layout templates' do
        create_help_message_template(template: 'Layout override marker', template_type: :layout)

        rendered = helper.formatted_doc('admin_reference', 'general', 'substitutions')

        expect(rendered).to include('{{#is')
        expect(rendered).not_to include('Layout override marker')
      end

      it 'ignores templates in a different category' do
        create_help_message_template(template: 'Other category marker', category: 'guest_reference')

        rendered = helper.formatted_doc('admin_reference', 'general', 'substitutions')

        expect(rendered).to include('{{#is')
        expect(rendered).not_to include('Other category marker')
      end

      it 'falls back to the markdown file when the matching template is blank' do
        create_help_message_template(template: " \n")

        rendered = helper.formatted_doc('admin_reference', 'general', 'substitutions')

        expect(rendered).to include('{{#is')
        expect(rendered).not_to be_blank
      end

      it 'strips a trailing .md from the subsection used for the template name' do
        create_help_message_template(template: 'Normalized subsection override marker')

        expect(helper.formatted_doc('admin_reference', 'general', 'substitutions.md'))
          .to include('Normalized subsection override marker')
      end

      it 'rejects invalid libraries before looking up a message template' do
        expect(Admin::MessageTemplate).not_to receive(:generate_content)

        expect do
          helper.formatted_doc('invalid_library', 'general', 'substitutions')
        end.to raise_error(FphsException, /invalid help library/)
      end
    end

    context 'when rendering the substitutions.md documentation page' do
      subject(:rendered) { helper.formatted_doc('admin_reference', 'general', 'substitutions') }

      it 'renders as HTML with a top-level heading tag, not raw markdown syntax' do
        expect(rendered).to match(/<h1[\s>]/)
        expect(rendered).not_to include('# Substitutions')
      end

      it 'renders list items as HTML list elements, not raw markdown dashes' do
        expect(rendered).to include('<li>')
      end

      it 'includes documentation for the {{#is}} conditional block opener' do
        expect(rendered).to include('{{#is')
      end

      it 'includes documentation for the {{/is}} conditional block closer' do
        expect(rendered).to include('{{/is}}')
      end

      it 'includes documentation for {{else is}} chaining within an is block' do
        expect(rendered).to include('{{else is')
      end

      it 'renders code examples showing substitution tags with double curly braces (not escaped backslashes)' do
        # The \{\{ escape sequences in the source markdown must be converted to {{ for display
        expect(rendered).to include('{{')
        expect(rendered).not_to include('\{\{')
      end
    end
  end
end
