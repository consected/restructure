# Server Information

## Introduction

**Server Information** provides administrators with comprehensive visibility into the server's configuration, status, and health. The information is organized into collapsible accordion panels for easy navigation. Each panel contains related settings and status information that help administrators:

- verify server configuration
- monitor system health and connectivity
- troubleshoot issues with database, cache, and file storage
- manage server operations such as restarts and background job processing

Administration is provided in [Admin: Server Information](/admin/server_info)

## Overview

The Server Information page is organized into the following accordion sections:

### General Status

Displays overall server health with status indicators, including:

- **Hostname** - the server identifier
- **Server Version** - the current application version
- **Configuration Status** - shows alert icons when critical services (database, memcached, NFS) have issues

Status indicators use color-coded icons:

- ✓ Green check - all systems operational
- ⚠ Red alert - configuration issues detected (hover or click for details)

### Server Actions

Provides buttons to perform administrative operations:

- **Restart Server** - restarts the Rails application server, DelayedJob workers, and clears the memcached cache
- **Restart DelayedJob** - restarts only the background job processing workers
- **Run DB Seeds** - executes database seed scripts to initialize or refresh reference data

**Note:** Server restart operations may cause brief service interruptions.

### Logs

Quick access links to:

- **Exception Log** - view application errors and exceptions
- **Search Rails Log** - query the Rails application logs

### App Settings

Displays the application configuration settings loaded from environment variables, including:

- Application name and URLs
- Email configuration
- Authentication settings
- Feature flags

### Database Settings

Shows database connection and configuration details:

- PostgreSQL connection parameters
- Database schema search path
- **Database Server Version** - PostgreSQL version information

### Memcached Connection

Displays cache server connection status and statistics:

- Connection status (connected, not configured, or connection failed)
- Server addresses and statistics (if connected)
- Error details (if connection failed)

### NfsStore Settings

Configuration and health monitoring for the Network File System storage:

- NFS directory paths and mount points
- Group ID range configurations

#### NFS Source Filesystem

Shows the source filesystem being mounted:

- **Source Filesystem** - the NFS server path being mounted
- **Status** - whether the source filesystem is properly mounted

#### NFS Group Directory Status

Detailed status table showing health of each group directory:

- **Group ID** - the group identifier (e.g., gid600, gid601)
- **Mount Path** - local directory path where NFS is mounted
- **Mountpoint Status** - whether the directory is recognized as an NFS mountpoint
  - *mounted* - directory is properly mounted
  - *failed* - directory is not a valid mountpoint
- **Directory Status** - whether the directory is accessible for file operations
  - *accessible* - directory can be read and files can be listed
  - *failed* - directory cannot be accessed
  - *not configured* - NFS storage is not configured

**Note:** Both mountpoint and directory checks must pass for full functionality. Failed mountpoints or inaccessible directories will trigger configuration alerts in the General Status section.

### Passenger Status (if applicable)

Shows Passenger application server process information and status.

### Passenger Memory Stats (if applicable)

Displays memory usage statistics for Passenger processes.

### Disk Usage

Shows filesystem disk usage across all mounted volumes.

### Processes

Lists running server processes relevant to the application.

## Interpreting Status Alerts

When configuration issues are detected, an alert icon (⚠) appears in the **General Status** section. Click or hover over the icon to view a popover with details about:

- Which services have failed
- Specific error messages
- Recommended actions

Common issues include:

- **NFS mountpoint failures** - indicates NFS storage is not properly mounted, preventing file uploads/downloads
- **Database connection errors** - database server is unreachable or credentials are incorrect
- **Memcached connection failures** - cache server is unavailable, may impact performance

## Troubleshooting NFS Issues

If NFS mountpoint failures are reported:

1. **Check NFS Source Filesystem** section to verify the source filesystem is mounted
2. **Review NFS Group Directory Status** table to identify which group directories have failed
3. **Verify mount commands** - system administrator may need to remount NFS shares
4. **Check network connectivity** to the NFS server
5. **Verify permissions** - ensure the application has read/write access to mounted directories

Only users with **server_info** access can view this information.
