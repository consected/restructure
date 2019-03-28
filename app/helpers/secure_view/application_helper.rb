module SecureView
  module ApplicationHelper
    def secure_view_defaults
      @secure_view_preview_as = :png
      @secure_view_default_zoom = 'fit'
      @secure_view_zoom_factors = ['fit', 35, 50, 66, 75, 100, 125, 150]
      @secure_view_extra_controls = {
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
