# frozen_string_literal: true

Rails.application.config.to_prepare do
  NfsStorePrepareDownloadJob.notification_defaults = {
    ready: { content: 'server prepared download ready', layout: 'general server notification',
             subject: 'Your file download is ready' },
    failed: { content: 'server prepared download failed', layout: 'general server notification',
              subject: 'Your file download could not be prepared' }
  }
end
