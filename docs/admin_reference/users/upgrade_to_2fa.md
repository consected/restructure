# Upgrade to Required Two-Factor Authentication (2FA)

This guide describes the steps required to move a ReStructure server from having
two-factor authentication disabled (`FPHS_2FA_AUTH_DISABLED=true`) to requiring
2FA for all users and admins.

## Prerequisites

- Administrative access to the server or its environment configuration
- Ability to restart the application server (or redeploy)
- Notification plan for existing users (see [User Guide](../../user_reference/main/upgrade_to_2fa.md))

## Overview

When 2FA has been disabled, users and admins log in with just their email and
password. Enabling 2FA means every user and admin will be prompted to set up an
authenticator app the next time they log in. Until they complete setup, they
cannot access the application.

## Steps

### 1. Notify Users

Before making the change, inform all active users:

- 2FA will be required on their next login
- They will need a smartphone with an authenticator app installed
- Recommended apps: Duo Mobile, Google Authenticator, Microsoft Authenticator,
  LastPass Authenticator, or Authy
- Direct users to the [User Upgrade Guide](../../user_reference/main/upgrade_to_2fa.md)

### 2. Update the Server Configuration

Locate the environment configuration for the server (for example,
`production-env.vars` or the environment variables set in your deployment
platform).

Find the line:

```
FPHS_2FA_AUTH_DISABLED=true
```

Either **remove this line entirely** or change it to:

```
FPHS_2FA_AUTH_DISABLED=false
```

> **Note:** When `FPHS_2FA_AUTH_DISABLED` is unset or set to `false`, 2FA is
> required for both users and admins. To require 2FA only for one role:
>
> - `FPHS_2FA_AUTH_DISABLED=admin` — disables 2FA for admins only (users must use 2FA)
> - `FPHS_2FA_AUTH_DISABLED=user` — disables 2FA for users only (admins must use 2FA)

### 3. Restart the Application

Restart or redeploy the application so the new configuration takes effect.

```bash
# Example for a Rails server
sudo systemctl restart puma
# or redeploy via your deployment pipeline
```

### 4. Verify Admin Access

After the restart:

1. Open the admin login page (`/admins/sign_in?secure_entry=<your-secure-entry>`)
2. Enter your admin email and password, then click **Log in**
3. You will be redirected to the **Two-Factor Authentication Setup** page
4. Scan the QR code with your authenticator app
5. Enter the 6-digit code displayed by your app and click **Submit Code**
6. You should be redirected to the admin panel

### 5. Monitor User Logins

After enabling 2FA, the **Manage Users** and **Manage Admins** pages in the
admin panel include a **2FA set up?** column. This shows whether each account has
an OTP secret configured:

- **true** — the user or admin has completed 2FA setup (or has begun setup with
  a generated secret)
- **false** — the user or admin has not yet set up 2FA and will be prompted on
  their next login

Use this column to monitor the progress of the upgrade and identify accounts
that have not yet completed 2FA setup.

After enabling 2FA, monitor for users who may have difficulty setting up their
authenticator apps. Common support scenarios:

| Issue | Resolution |
|-------|-----------|
| User lost their smartphone | Reset 2FA for the user via Admin > Manage Users |
| Code is always rejected | Check the user's device clock is synchronized |
| User doesn't have a smartphone | Provide a desktop TOTP app (e.g. Authy desktop) |

To reset a user's 2FA from the admin panel:

1. Go to **Admin > Manage Users**
2. Find the user account
3. Set **Reset two factor auth** to **yes** and save
4. The user will be prompted to set up 2FA again on their next login

## What Happens Under the Hood

When 2FA is enabled and a user or admin logs in who has not yet set up 2FA:

1. The user authenticates with their email and password as normal
2. After successful password authentication, the system detects that
   `two_factor_setup_required?` is `true` (no OTP secret or `otp_required_for_login` is `false`)
3. The system generates an OTP secret and redirects to the setup page (`/users/show_otp` or `/admins/show_otp`)
4. The QR code encodes a TOTP provisioning URI that the authenticator app uses to
   create the account
5. The user enters the 6-digit code from the app to confirm setup
6. `otp_required_for_login` is set to `true`, completing the setup
7. On future logins, both password and 2FA code are required at the login form

## Rollback

If you need to disable 2FA after enabling it:

1. Set `FPHS_2FA_AUTH_DISABLED=true` in the environment configuration
2. Restart the application
3. Users and admins will be able to log in without 2FA codes

> **Important:** Disabling 2FA does not remove the OTP secrets from user
> accounts. If 2FA is re-enabled later, users who previously completed setup
> will simply need to enter their 2FA code again (their authenticator app entry
> will still work). Users who had not yet set up 2FA will be prompted to do so.
