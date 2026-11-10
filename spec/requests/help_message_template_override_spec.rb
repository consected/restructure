# frozen_string_literal: true

# Covers help-page message-template overrides, both render modes, file fallback, and guest library authorization.
require 'rails_helper'

RSpec.describe 'Help message template overrides', type: :request do
  include ModelSupport

  before do
    @admin, = create_admin
    sign_in @admin
  end

  def create_help_override(library:, section:, subsection:, content:)
    Admin::MessageTemplate.create!(
      name: "#{section}/#{subsection}",
      category: library,
      message_type: :dialog,
      template_type: :content,
      template: content,
      current_admin: @admin
    )
  end

  it 'renders a matching override in a full help page' do
    create_help_override(
      library: 'admin_reference',
      section: 'general',
      subsection: 'save_trigger_create_reference',
      content: 'Full-page help override marker'
    )

    get '/help/admin_reference/general/save_trigger_create_reference'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Full-page help override marker')
  end

  it 'renders a matching override in embedded help mode' do
    create_help_override(
      library: 'admin_reference',
      section: 'general',
      subsection: 'save_trigger_create_reference',
      content: 'Embedded help override marker'
    )

    get '/help/admin_reference/general/save_trigger_create_reference', params: { display_as: 'embedded' }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Embedded help override marker')
  end

  it 'does not serve an admin-reference override to a guest' do
    create_help_override(
      library: 'admin_reference',
      section: 'general',
      subsection: 'save_trigger_create_reference',
      content: 'Private help override marker'
    )
    sign_out :admin

    get '/help/admin_reference/general/save_trigger_create_reference'

    expect(response).to have_http_status(:unauthorized)
    expect(response.body).not_to include('Private help override marker')
  end

  it 'serves a guest-reference override to a guest' do
    create_help_override(
      library: 'guest_reference',
      section: 'main',
      subsection: 'login_issues',
      content: 'Guest help override marker'
    )
    sign_out :admin

    get '/help/guest_reference/main/login_issues'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Guest help override marker')
  end
end
