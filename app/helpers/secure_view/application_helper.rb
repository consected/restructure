module SecureView
  module ApplicationHelper
    DefaultZoomFactors = ['fit', '35', '50', '66', '75', '100', '125', '150'].freeze
    DefaultZoom = 'fit'
    #
    # Define buttons for app-specific and search functionality
    def secure_view_defaults
      @secure_view_preview_as = :png
      @secure_view_default_zoom = app_config_text(:secure_view_default_zoom, DefaultZoom)
      @secure_view_zoom_factors = app_config_items(:secure_view_zoom_factors, DefaultZoomFactors)
      @secure_view_extra_controls = {
        search_doc: {
          attrs: {},
          label: '',
          link: '#',
          extra_class: 'glyphicon glyphicon-search'
        },
        show_files: {
          attrs: {},
          label: '',
          link: '#',
          extra_class: 'glyphicon glyphicon-folder-open'
        }
      }
    end
  end
end
