# Create an admin user or reset an admin account

This requires you to ssh to the app server operating system. Depending on your environment, access to an app server may be via SSH or the AWS Sessions Manager (the Connect button on the AWS instance provides a Session Manager connection option.)

Immediately run sudo interactively

    sudo -i

As root, change to the app directory. On AWS this is:

    cd /var/app/current

To add a new user, or reset the password and unlock an existing user

    fphs-scripts/add_admin.sh email@hms.harvard.edu

---

**NOTE:** this will not reset the two-factor authentication secret.

---

To reset the two-factor authentication secret as well as resetting the password:

    reset_secret=yes fphs-scripts/add_admin.sh email@hms.harvard.edu

The first login after a new admin has been created, or a two-factor authentication secret has been reset, the admin user will be presented with a barcode to setup an Authenticator app.
