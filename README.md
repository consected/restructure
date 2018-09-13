Rails App for FPHS (Zeus)
==================

The **Zeus** App provides CRM and activity tracking functionality for the
Football Players Health Study (FPHS) team.

### Build, Test and Deployment

Build, test and deployment is by Ansible, with full details here:
https://github.com/hmsrc/ansible-playbooks-fphs-webapp

The same Ansible roles can be used to create a self-contained Vagrant server for
development, avoiding the need to get all the prerequisites satisfied locally.

### Multiple Repos

It should be noted that as of Zeus Phase 5, two Git repos are being used.

1. Harvard Catalyst Bitbucket: **development**

    https://open.med.harvard.edu/stash/projects/FPHSAPPS/repos/fphs-rails/browse

2. HMRC Github: **production-ready releases**

    https://github.com/hmsrc/fphs-rails-app


The development repository contains all code, including release-ready code. Releases are tagged in the form x.y.z

The production-ready release repository contains only code that has been built and tested. It is tagged in the same form and with the same release numbers as the development repository. Deployments made by Ansible are from this repo.


NfsStore
========

NfsStore is a gem that provides upload, management and download of medical and project files, as a component of the FPHS Zeus-based projects.

Installation
---

Add the gem to the project Gemfile, referencing the Git repo, enforcing a a specific version.

Then run:

    bundle install

Create a file `config/initializers/nfs_store_config.rb` with something like the following:

    ActiveSupport.on_load(:nfs_store_config) do

      self.group_id_range = 600..601

      if Rails.env.production?
        self.nfs_store_directory = ENV['FILESTORE_NFS_DIR']
        self.temp_directory = ENV['FILESTORE_TEMP_UPLOADS_DIR']
        self.containers_dirname = ENV['FILESTORE_CONTAINERS_DIRNAME']
      else
        self.nfs_store_directory = "/mnt/fphsfs"
        # Notice the use of /var/tmp rather than /tmp, since we are trying to avoid consuming RAM
        # when uploading and downloading large files
        self.temp_directory = "/var/tmp/nfs_store_tmp"
        self.containers_dirname = 'containers'

        FileUtils.mkdir_p self.temp_directory
        self.group_id_range.each do |i|
          check_dir = File.join(self.nfs_store_directory, "#{NfsStore::Manage::Group::NfsMountNamePrefix}#{i}")
          FsException::Config.new "Could not access: #{check_dir}" unless File.exist?(check_dir)
        end
      end

      raise FsException::Config.new "nfs_store_directory not set" if self.nfs_store_directory.blank?
      raise FsException::Config.new "temp_directory not set" if self.temp_directory.blank?
      raise FsException::Config.new "group_id_range not set" if self.group_id_range.blank?
      raise FsException::Config.new "containers_dirname not set" if self.containers_dirname.nil?

      ares = Kernel.system 'which archivemount'
      raise FsException::Config.new "archivemount not in the path" unless ares

      raise FsException::Config.new "No App Type available" unless Admin::AppType.first

      unless File.exist? self.temp_directory
        Rails.logger.info "Making the tmp upload directory"
        FileUtils.mkdir_p self.temp_directory
      end
    end

    raise FsException::Config.new "action_dispatch.x_sendfile_header not set in production.rb" if Rails.env.production? && ! Rails.configuration.action_dispatch.x_sendfile_header

Install **archivemount** either from the distro repositories, deploying to Elastic Beanstalk by creating a file
**.ebextensions/setup-filestore.config**, or building following this as a template

    container_commands:

      00_setup_epel:
        command: sudo yum-config-manager --enable epel
      01_setup_filestore:
        command: sudo yum install nfs-utils prcbind autoconf fuse fuse-libs fuse-devel libarchive libarchive-devel
      02_make_archivemount:
        command: |
          cd /tmp
          wget https://www.cybernoia.de/software/archivemount/archivemount-0.8.12.tar.gz
          tar -xvzf archivemount-0.8.12.tar.gz
          cd archivemount-0.8.12
          autoreconf -i
          ./configure && make && sudo make install
          sudo ln -s /usr/local/bin/archivemount /usr/bin/archivemount



To setup the nfs_store* database tables:

    rake nfs_store:install:migrations
    rake db:migrate

In production, consider creating a separate schema and moving the tables there, plus
updating the app search path.

To `config/routes.rb` add the line:

    mount NfsStore::Engine => "/nfs_store"


NFS setup
---

To setup and test an NFS server or the NFS client, see:

https://docs.google.com/document/d/18qcIBKVq43gYi5-0amlQKxbUF-42jX7oM9i9h5vZ2Vw/edit?usp=sharing


Adding App Types
---

The NfsStore expects a specific structure for new App Types.

    FS_ROOT=/opt/fphsfs
    APPTYPE_DIR=app-type-<app_type_id>

    cd $FS_ROOT/main
    mkdir -p $APPTYPE_DIR/containers
    chmod 770 $APPTYPE_DIR/containers
    chown nfsuser:<group_owner> $APPTYPE_DIR/containers
