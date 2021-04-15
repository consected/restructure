module SortableBlockHelper
  def sortable_block(el_id, items_as = 'li')
    <<~END_HTML
      <div class="make-sortable">
        <div class="dynamic-field-list sortable-block" data-get-data-from="#{el_id}" data-items-as="#{items_as}"></div>
        <div class="dynamic-field-list sortable-block-trash" data-items-as="code"></div>
        <div class="sortable-block-actions">
          <input type="text" value="" class="sortable-add-item-text" placeholder="text to add"/> <button class="btn btn-sm sortable-add-item">+</button>
        </div>
      </div>
    END_HTML
      .html_safe
  end
end
