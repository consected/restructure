// Jasmine-only compiler asset; do not require it from application.js.
//= require spec/handlebars_runtime_registry
//= require handlebars/dist/handlebars
//= require app/handlebars-helpers.js

(function (root) {
  const runtime_registry = root._fpa_handlebars_runtime_registry || {};
  Handlebars.helpers = Object.assign({}, runtime_registry.helpers || {}, Handlebars.helpers || {});
  Handlebars.partials = Object.assign({}, runtime_registry.partials || {}, Handlebars.partials || {});
  Handlebars.templates = Object.assign({}, runtime_registry.templates || {}, Handlebars.templates || {});

  if (root._fpa) {
    root._fpa.templates = Handlebars.templates;
    root._fpa.partials = Handlebars.partials;
  }

  delete root._fpa_handlebars_runtime_registry;
}(window));
