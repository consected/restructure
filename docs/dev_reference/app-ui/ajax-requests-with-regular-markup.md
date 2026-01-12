# AJAX Requests and Responses Using Regular Markup

## Overview

ReStructure makes it simple to add AJAX functionality using standard Rails helpers with `remote: true`. This approach allows you to create interactive features without writing custom JavaScript code.

## Pattern Components

A complete AJAX implementation requires three components:

1. **View with AJAX link/button** - Triggers the request
2. **Controller action** - Processes the request and renders a partial
3. **Response partials** - Rendered and inserted into the page

## How It Works

1. **User clicks the AJAX link** - The `remote: true` attribute prevents default navigation
2. **Rails sends AJAX request** - POST to `/admin/dynamic_models/:id/run_batch_now`
3. **Controller processes request** - Performs business logic and prepares response data
4. **Controller renders partial** - Returns HTML fragment instead of full page
5. **ReStructure updates DOM** - Finds container with matching `data-subscription` and injects content
6. **User sees result** - Success or error message appears in the container

## Creating Your Own AJAX Feature

Follow this pattern for any AJAX interaction:

### Step 1: Add Route

```ruby
# config/routes.rb
resources :my_resources do
  member do
    post :my_action  # or get, put, patch, delete
  end
end
```

### Step 2: Create View with AJAX Link

```erb
<!-- app/views/my_resources/_form.html.erb -->
<%= link_to my_action_my_resource_path(@resource),
    remote: true,
    class: 'btn btn-primary',
    method: :post,
    data: { disable_with: "Processing..." } do %>
  <span class="glyphicon glyphicon-cog"></span> Perform Action
<% end %>

<div class="my-action-result-container"
  id="my-action-result-container"
  data-subscription="my-action-result">
</div>
```

- **`remote: true`** - Makes the link submit via AJAX
- **`method: :post`** - Specifies HTTP method
- **`data: { disable_with: "..." }`** - Shows loading state during request
- **Container div** - Receives the response content via `data-subscription` attribute

### Step 3: Create Controller Action

```ruby
# app/controllers/my_resources_controller.rb
def my_action
  @resource = MyResource.find(params[:id])
  
  begin
    # Perform your business logic
    result = @resource.do_something
    @success_message = "Action completed successfully: #{result}"
    render partial: 'my_resources/my_action_success'
  rescue StandardError => e
    Rails.logger.error "Action failed: #{e.message}"
    @error_message = "Action failed: #{e.message}"
    render partial: 'my_resources/my_action_error'
  end
end
```

**Key Points:**

- Renders different partials based on success or error (or anything else you want)
- No `respond_to` block needed - Rails handles AJAX automatically

### Step 4: Create Response Partials

```erb
<!-- app/views/my_resources/_my_action_success.html.erb -->
<div class="data-results">
  <div data-result="my-action-result" class="alert alert-success">
    <%= @success_message %>
  </div>
</div>
```

```erb
<!-- app/views/my_resources/_my_action_error.html.erb -->
<div class="data-results">
  <div data-result="my-action-result" class="alert alert-danger">
    <%= @error_message %>
  </div>
</div>
```

**Key Points:**

- Both partials use `data-result="dynamic-model--run-batch-result"` attribute
- This matches the `data-subscription="dynamic-model--run-batch-result"` in the container
- ReStructure automatically injects the rendered content into the matching container

## Important Notes

### Data Attribute Naming

The `data-result` and `data-subscription` attributes must match:

- Container: `data-subscription="my-action-result"`
- Partial: `data-result="my-action-result"`

### Disable Button During Request

Use `data: { disable_with: "..." }` to prevent double-clicking:

```erb
<%= link_to path, remote: true, 
    data: { disable_with: "<span class='glyphicon glyphicon-refresh spinning'></span> Processing..." } do %>
  Click Me
<% end %>
```

### HTTP Method

Specify the appropriate HTTP method:

- **GET** - For retrieving data (default)
- **POST** - For creating or triggering actions
- **PUT/PATCH** - For updates
- **DELETE** - For deletions

```erb
<%= link_to path, remote: true, method: :delete do %>
  Delete
<% end %>
```

### Forms with AJAX

You can also use forms with AJAX:

```erb
<%= form_with model: @resource, remote: true do |f| %>
  <%= f.text_field :name %>
  <%= f.submit "Save", data: { disable_with: "Saving..." } %>
<% end %>

<div data-subscription="form-result"></div>
```

### Multiple Response Types

You can render different partials for different scenarios:

```ruby
def my_action
  if condition_a
    render partial: 'response_a'
  elsif condition_b
    render partial: 'response_b'
  else
    render partial: 'response_default'
  end
end
```

### Testing AJAX Requests

In system specs, helper methods handle AJAX automatically:

```ruby
# The helper waits for AJAX to complete
click_link 'Run Batch Now'
finish_page_loading

expect(page).to have_content('Batch processing completed')
```

## Common Patterns

### Progressive Enhancement

Start with a regular link, then add AJAX:

```erb
<!-- Before: regular link -->
<%= link_to "Do Something", my_action_path(@resource), method: :post %>

<!-- After: AJAX link -->
<%= link_to "Do Something", my_action_path(@resource), 
    remote: true, method: :post %>
```

### Modal with AJAX

Combine with modal for confirmation dialogs:

```erb
<a class="btn btn-primary show-in-modal" 
   data-content-el="#confirm-action" 
   data-title="Confirm Action">
  Do Something
</a>

<div id="confirm-action" class="hidden">
  <h2>Are you sure?</h2>
  <%= link_to "Yes, do it", my_action_path(@resource),
      remote: true, method: :post,
      data: { disable_with: "Processing..." } %>
  <div data-subscription="action-result"></div>
</div>
```

### Polling Updates

For long-running tasks, you can poll for updates:

```javascript
// In your view
<script>
  setInterval(function() {
    $.get('/my_resources/<%= @resource.id %>/status', function(data) {
      $('#status-container').html(data);
    });
  }, 5000); // Poll every 5 seconds
</script>
```

## Troubleshooting

### Response Not Appearing

1. Check that `data-subscription` matches `data-result`
2. Verify the container exists in the DOM when link is clicked
3. Check browser console for JavaScript errors
4. Verify controller is rendering the partial

### Double Form Submission

Add `data: { disable_with: "..." }` to prevent multiple clicks

### AJAX Not Working

1. Verify `remote: true` is present
2. Check that `jquery-ujs` is loaded (Rails default)
3. Check browser console for errors
4. Verify route exists: `rails routes | grep my_action`

## See Also

- [Rails AJAX Guide](https://guides.rubyonrails.org/working_with_javascript_in_rails.html)
- [UI Templates Documentation](ui-templates-for-master-record-search-results.md)
- [Show If Embedded Item](show_if_embedded_item.md)
