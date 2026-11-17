# Background preparation for large filestore downloads

Selections that exceed either configured threshold are prepared by the `nfs_store_downloads`
Delayed Job queue instead of being zipped during the web request. Smaller selections continue
through the normal browser download, including direct delivery of a selected single file.
Successful preparation emails the user a per-user download link. The archive can be downloaded
again until its configured expiry; failed preparation sends a retry notice.

## Configuration

| Environment variable | Default | Description |
| --- | ---: | --- |
| `NFS_STORE_BACKGROUND_DOWNLOAD_MAX_FILES` | `100` | Queue when the selected file count is greater than this value. |
| `NFS_STORE_BACKGROUND_DOWNLOAD_MAX_BYTES` | `20971520` | Queue when the combined database file size is greater than this value in bytes. |
| `FILESTORE_PREPARED_DOWNLOADS_DIR` | `<FILESTORE_TEMP_UPLOADS_DIR>/prepared_downloads` | Shared directory where workers write prepared archives. |
| `NFS_STORE_PREPARED_DOWNLOADS_TTL_HOURS` | `24` | How long links remain valid; hourly cleanup removes expired archives. |

The limits use strict greater-than comparisons, so selections equal to both limits remain
synchronous. The archive directory is partitioned by user ID and is not exposed as a public
static directory.

## Operations

- The notification email templates (`server prepared download ready` and
  `server prepared download failed`) are created by the migration
  `20261117101500_setup_nfs_store_prepared_download_templates`, which runs the seed
  `db/seeds/nfs_store_prepared_download_notifications.rb`. If the migration reports a template
  setup failure, run `bundle exec rails db:seed`.
- Configure Delayed Job workers to process the dedicated `nfs_store_downloads` queue as well as
  the existing application queues.
- Web and worker processes must see the same prepared-download directory. Workers need the same
  filestore group memberships and access rights as Puma because preparation re-checks and reads
  files from the filestore.
- Production uses nginx `X-Accel-Redirect` for `send_file`. Extend the internal location and
  `X-Accel-Mapping` configuration to cover `FILESTORE_PREPARED_DOWNLOADS_DIR`, not just the
  existing filestore temporary directory.
- Do not expose the prepared directory through nginx's public static-file mapping. Downloads are
  authenticated and are served only from the current user's directory.
