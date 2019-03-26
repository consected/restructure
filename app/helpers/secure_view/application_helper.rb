module SecureView
  module ApplicationHelper
    def set_defaults
      @preview_as = :png
      @default_zoom = 'fit'
      @zoom_factors = ['fit', 50, 66, 75, 100, 125, 150]

      @extra_actions = {
        download: {
          link: 'download',
          label: '',
          extra_class: 'glyphicon glyphicon-download-alt',
          attrs: {
            title: 'download',
            target: '_blank'
          }
        }
      }

    end
  end
end
