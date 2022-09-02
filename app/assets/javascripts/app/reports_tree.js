// Show a table as a tree. The attribute data-tt-tree-cols 
// defines the set of columns to use for grouping (JSON array)
// param $table - jQuery reference to table
_fpa.reports_tree = class {

  static show_table_as_tree($table) {
    if (!$table.hasClass('tree-table')) return;

    let tree = new _fpa.reports_tree($table);
    tree.setup()
    tree.setup_header()
    tree.setup_rows()
    tree.finalize()
  }

  constructor(table) {
    this.$table = table;
  }


  setup() {
    const this_class = this;

    if (this.$table.hasClass('jsTree')) return;

    this.$table.addClass('added-tree-table');
    const col_levels = this.$table.attr('data-tt-tree-cols');
    const num_levels = this.$table.attr('data-tt-tree-num-levels');
    const default_expand = this.$table.attr('data-tt-tree-expand-level');

    if (col_levels)
      this.col_levels = JSON.parse(col_levels);
    else
      this.col_levels = [];

    if (num_levels)
      this.num_levels = parseInt(num_levels);
    else
      this.num_levels = 2;

    if (default_expand)
      this.default_expand = parseInt(default_expand);
    else
      this.default_expand = 0;

    if (this.col_levels.length != this.num_levels - 1) {
      console.log("ERROR - the number of levels specified for the tree does not correspond to the column levels specified");
      return;
    }
  }

  setup_header() {
    const this_class = this;

    // Add rows for additional levels

    const $head_row = this_class.$table.find('thead tr');
    let sub_rows = [null]

    for (let i = this_class.num_levels - 1; i >= 1; i--) {
      let $new_row = $(`<tr data-tt-thtr-row="${i}" class="tt-head-sub-row"></tr>`)
      $head_row.after($new_row)
      sub_rows[i] = $new_row
    }

    $head_row.addClass('tt-head-main-row');
    $head_row.attr('data-tt-thtr-row', '0');

    // Add classes and attributes to the header columns to aid styling and shift to sub rows
    const $head_cells = this_class.$table.find('thead th[data-col-type]');
    $head_cells.each(function () {
      if (this_class.col_levels[0].indexOf($(this).attr('data-col-name')) >= 0) {
        $(this).addClass('is-parent-col')
      }
      else {
        $(this).addClass('is-not-parent-col')
      }

      for (let i = 0; i < this_class.num_levels; i++) {
        if (i > 0 && $(this).attr('data-col-name') == `id${i}`) {
          $(this).css({ visibility: 'hidden' })
        }

        let rownum = null;
        if (i == this_class.num_levels - 1) {
          rownum = this_class.num_levels - 1;
        }
        else if (this_class.col_levels[i].indexOf($(this).attr('data-col-name')) >= 0) {
          rownum = i;
        }

        if (rownum != null) {
          $(this).attr('data-tt-th-col-level', i)
          if (rownum > 0) {
            sub_rows[rownum].append($(this))
          }
          break;
        }

      }
    });

    this_class.num_cols = $head_cells.length;

  }

  // Run through the rows to add an extra row above a group of rows with the same ID,
  // to act as the parent tree row for that group of data.
  // The primary columns that appear in each of these group headers are blanked in the
  // subsequent data rows to avoid repetition and provide a tree view
  setup_rows() {

    const this_class = this;
    var $rows = this_class.$table.find('tbody tr');
    this_class.prev_id = [];


    $rows.each(function () {
      this_class.num_ancestor_cols = 0;
      for (let curr_level = 0; curr_level < this_class.num_levels - 1; curr_level++) {
        this_class.handle_row_level($(this), curr_level);
      }
    });

    $rows.find(`[data-col-type="id${this_class.num_levels - 1}"]`).show().css({ visibility: 'hidden' });
  }

  finalize() {
    const this_class = this;
    com_github_culmat_jsTreeTable.treeTable(this_class.$table);
    this_class.$table.expandLevel(this_class.default_expand);
  }

  handle_row_level($row, curr_level) {
    const this_class = this;

    const $id = $row.find(`[data-col-type="id${curr_level}"]`)
    const id = $id.text() || `(no parent ID-${curr_level} set)`;
    const $next_level_id = $row.find(`[data-col-type="id${curr_level + 1}"]`);
    const next_level_id = $next_level_id.text() || `(no ID-${curr_level + 1} set)`;
    const this_level_cols = this_class.col_levels[curr_level];
    const num_this_level_cols = this_level_cols.length;

    // Hide other ids. Show this one, unless we are at the deepest level
    for (let i = 0; i < this_class.num_levels; i++) {
      let vis = (curr_level == i) ? 'visible' : 'hidden';
      let $cell = $row.find(`[data-col-type="id${i}"]`);
      $cell.css({ visibility: vis });
      let idval = $cell.text() || `(no ID-${i} set)`;

      $cell.html(`<treeid>${idval}</treeid>`)
    }
    $id.show();


    if (id != this_class.prev_id[curr_level]) {
      if (curr_level == 0) {
        this_class.prev_id = [];
      }
      // A new id, so add the parent row for it
      var $par = $row.clone();

      $par.find('[data-col-type]').each(function () {
        let col_type = $(this).attr('data-col-type');
        if (this_level_cols.indexOf(col_type) < 0) {
          $(this).remove();
        }
      });

      let pad_cols = this_class.num_cols - num_this_level_cols - curr_level;
      $par.find('[data-col-type]').last().attr('colspan', pad_cols);

      $par.attr('data-tt-id', `${id}`);
      $row.before($par);
    }

    $row.find('[data-col-type]').each(function () {
      if (this_level_cols.indexOf($(this).attr('data-col-type')) >= 0) {
        $(this).remove();
        //.addClass('is-parent-col').html('')
      }
    });


    $row.attr('data-tt-id', `${next_level_id}`);
    $row.attr('data-tt-parent-id', id);

    for (let i = 1; i < this_class.num_levels; i++) {
      $row.find(`[data-col-type="id${i}"]`).hide();
    }

    this_class.num_ancestor_cols = this_class.num_ancestor_cols + num_this_level_cols;
    this_class.prev_id[curr_level] = id;
  }
}
