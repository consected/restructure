# frozen_string_literal: true

#
# Organization specific default settings, to be used by the Settings class
# in `app_settings.rb` where configuration environment variables are not set.
# This class is not shared between upstream and downstream code, making it easier
# for transfers to be performed (see: docs/dev_reference/main/how-to-copy-to-restructure.md)
class DefaultSettings
  AdminEmail = 'admin@restructure'
  DefaultLogo = 'project-viva-logo.png'
  DefaultSchemaOwner = 'vivadba'
  TwoFactorAuthIssuer = 'VivaPortal'
  PageTitle = 'Viva Portal'
  DefaultShortLinkS3Bucket = (Rails.env.production? ? 'fphs.link' : 'test-shortlink.fphs.link')
  DefaultShortLinkLogS3Bucket = (Rails.env.production? ? 'url-shortener-logs.fphs' : 'test-fphs-url-shortener-logs')
  DefaultMigrationSchema = 'ml_app'
  DbPrefix = 'restr'
  GlobalIdPrefix = 'fpa1'
  CaptionAcronyms = %w[IPA IPAs BHS PI PIs HMS FPHS MD RA RAs].freeze
end
