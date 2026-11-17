# frozen_string_literal: true

require 'rails_helper'

# View spec for the admin alert partials that render Admin::ServerInfo#configuration_failed_reason.
#
# The reasons now include exception messages from dynamic definitions that could not be loaded
# (Dynamic::DefinitionLoadIssues), so they can contain markup or quote characters. The status
# indicator builds popover HTML from the reasons inside a data attribute and must escape them; the
# alerts panel prints them with plain ERB output.
#
# Coverage:
# - _admin_status_indicators: reasons are escaped in the popover content and cannot break out of the attribute
# - _admin_alerts_panel: reasons are escaped in the panel list
# - both partials: a dynamic definition load issue line keeps its admin edit link, with its detail escaped
# - _admin_status_indicators: nothing is rendered when the configuration is successful
RSpec.describe 'admin alert partials escape configuration failure reasons', type: :view do
  let(:payload) { %("><img src=x onerror=alert(1)><script>alert("x")</script>) }
  let(:reason) { "Dynamic definitions not loaded - exception parsing options (1): foo (id 1) - #{payload}" }
  let(:edit_path) { '/admin/dynamic_models?filter%5Bid%5D=12&perform_action=edit' }

  def assign_server_info(reasons)
    assign(:server_info, instance_double(Admin::ServerInfo,
                                         configuration_successful: reasons.empty?,
                                         configuration_failed_reason: reasons))
  end

  # A real Dynamic::DefinitionLoadIssues line, with markup in the exception detail
  def linked_reason
    allow(Dynamic::DefinitionLoadIssues).to receive(:grouped).and_return(
      options_parse_exception: [{ definition_class: DynamicModel, id: 12, resource_name: 'dynamic_model__abcs',
                                  admin_path: edit_path, detail: payload }]
    )
    Dynamic::DefinitionLoadIssues.messages.first
  end

  describe 'pages/_admin_status_indicators' do
    it 'escapes the reason in the popover content and keeps it inside the attribute' do
      assign_server_info([reason])

      render partial: 'pages/admin_status_indicators'

      fragment = Nokogiri::HTML.fragment(rendered)
      expect(fragment.css('img, script')).to be_empty
      icon = fragment.at_css('i.error-mark')
      expect(icon.attributes.keys)
        .to contain_exactly('class', 'data-toggle', 'data-trigger', 'data-content', 'data-html')

      popover = Nokogiri::HTML.fragment(icon['data-content'])
      expect(popover.css('img, script')).to be_empty
      expect(popover.at_css('li').text).to eq reason
    end

    it 'keeps the admin edit link of a dynamic definition load issue and escapes its detail' do
      line = linked_reason
      assign_server_info([line, reason])

      render partial: 'pages/admin_status_indicators'

      expect(Nokogiri::HTML.fragment(rendered).css('img, script')).to be_empty
      popover = Nokogiri::HTML.fragment(Nokogiri::HTML.fragment(rendered).at_css('i.error-mark')['data-content'])
      expect(popover.css('img, script')).to be_empty
      expect(popover.css('li a').map { |a| [a.text, a['href']] }).to eq [['dynamic_model__abcs', edit_path]]
      expect(popover.css('li').map(&:text)).to eq [Nokogiri::HTML.fragment(line).text, reason]
      expect(popover.css('li').first.text).to end_with(payload)
    end

    it 'renders nothing when the configuration is successful' do
      assign_server_info([])

      render partial: 'pages/admin_status_indicators'

      expect(rendered).not_to include('error-mark')
    end
  end

  describe 'pages/_admin_alerts_panel' do
    before do
      allow(view).to receive(:current_admin).and_return(instance_double(Admin, can_admin?: false))
    end

    it 'escapes the reason in the alerts list' do
      assign_server_info([reason])

      render partial: 'pages/admin_alerts_panel'

      fragment = Nokogiri::HTML.fragment(rendered)
      expect(fragment.css('img, script')).to be_empty
      expect(fragment.at_css('.admin-alerts-list__message').text).to eq reason
    end

    it 'keeps the admin edit link of a dynamic definition load issue and escapes its detail' do
      assign_server_info([linked_reason])

      render partial: 'pages/admin_alerts_panel'

      fragment = Nokogiri::HTML.fragment(rendered)
      expect(fragment.css('img, script')).to be_empty
      message = fragment.at_css('.admin-alerts-list__message')
      expect(message.css('a').map { |a| [a.text, a['href']] }).to eq [['dynamic_model__abcs', edit_path]]
      expect(message.text).to end_with("dynamic_model__abcs (id 12) - #{payload}")
    end
  end
end
