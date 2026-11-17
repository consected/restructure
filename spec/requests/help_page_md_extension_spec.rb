# frozen_string_literal: true

# Regression test for a bug where requesting a help doc page with an explicit
# ".md" extension (as used by relative markdown links between doc pages, e.g.
# "[references](references.md)") failed with:
#   "Missing template help/show ... formats: [:md] ..."
# Rails treats the ".md" suffix in the URL as the response *format*, but only
# an .html.erb template exists for help/show - so request.format ended up as
# :md even though HelpController#show's guard clause explicitly allows it.
# Fixed by forcing `formats: [:html]` on the render calls in HelpController#show,
# regardless of the format Rails inferred from the URL.
require 'rails_helper'

describe 'GET /help/:library/:section/:id.md' do
  include ModelSupport

  before(:each) do
    create_admin
    sign_in @admin
  end

  it 'renders the html help page when the id has a .md extension' do
    get '/help/admin_reference/general/save_trigger_create_reference.md'

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include('text/html')
    expect(response.body).to include('create_reference')
  end

  it 'renders the same page without the .md extension' do
    get '/help/admin_reference/general/save_trigger_create_reference'

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include('text/html')
    expect(response.body).to include('create_reference')
  end
end
