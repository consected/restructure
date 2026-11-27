// Snapshot the runtime registries before the Jasmine-only full compiler replaces Handlebars.
(function (root) {
  const runtime = root.Handlebars || {};
  root._fpa_handlebars_runtime_registry = {
    helpers: Object.assign({}, runtime.helpers || {}),
    partials: Object.assign({}, runtime.partials || {}),
    templates: Object.assign({}, runtime.templates || {})
  };
}(window));
