_fpa.reports_custom_handling = class {
  static handle(block, data) {

    const inst = new _fpa.reports_custom_handling(block, data);
    inst.run_handlers();
  }

  // Add an implementation for a named handler.
  // fn must be function() to retain current *this*
  // See 'test' example at the end of this file
  static add_handler_implementation(name, fn) {
    _fpa.reports_custom_handling.prototype[name] = fn;
  }

  constructor(block, data) {
    console.log('handle')
    this.$block = block;
    this.data = data;
    const handler_list = block.find('[data-result-handlers]').attr('data-result-handlers');
    if (!handler_list) return;

    this.handler_names = handler_list.split(' ');
    // Add new handler methods directly to this call if they are to be called
  }

  run_handlers() {
    const _this = this;
    if (!this.handler_names) return;

    this.handler_names.forEach((handler_name) => {
      if (!_this[handler_name]) {
        console.log(`run_handlers did not find handler: ${handler_name} in ${_this}`);
        return;
      }
      _this[handler_name]();
    });
  }
}

// Example of how to add a custom handling implementation
_fpa.reports_custom_handling.add_handler_implementation('test', function () {
  console.log(this.$block);
  console.log(this.data);
});
