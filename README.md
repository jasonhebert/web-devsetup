# Web Development Environment Setup

This repository provides a VirtualBox VM capable of running all web properties.

The intended use of this VM is for serving only. Source files are expected to reside outside the VM on the host's
filesystem. Day-to-day development is similarly host-based. The VM is headless.

Other configurations are possible, but not supported out-of-the-box.

## Pre-install

The host machine should have the following software installed as prerequisite:

1. [VirtualBox](https://www.virtualbox.org/wiki/Downloads) v5.0.32 or above
1. [Vagrant](https://www.vagrantup.com/) v1.8.6 or above
1. [Git](https://git-scm.com/)
1. Cisco AnyConnect VPN client (should be pre-installed on IAC-provided hardware)

## Setup

1. Decide where you will put all your git checkouts. The suggested location is `C:\weblab`. This location will
be referred to as your workspace.

1. Clone this repository to your workspace. If you have set up your SSH key in Stash, use the SSH checkout URL. If you have not set your SSH key in Stash, use the HTTP URL.

1. Copy your SSH private key into the checkout as `id_rsa`. This step is optional.

1. Run `vagrant up`.

1. Log into the newly-created VM using `vagrant ssh`.

### Setup Notes

During setup, VirtualBox may prompt to install additional components. Allow these installations to happen.

Vagrant will attempt to modify the hosts file of your machine when it brings up the guest VM. This may cause an authorization prompt on Windows, since editing the hosts file requires elevated access permission.

Vagrant will also attempt to install plugins. Vagrant does not provide a robust API for this, so the current implementation is basic but should be able to get the job done.

If vagrant fails to run and throws a Ruby stack trace with "cannot load such file -- vagrant-share/helper/api (LoadError)",
consult [this GitHub issue](https://github.com/mitchellh/vagrant/issues/8532) which recommends:

`vagrant plugin install vagrant-share --plugin-version 1.1.8`


## Update

To re-run the provisioning script without destroying the VM and starting over from scratch:

`vagrant provision`


## What is included?

The Vagrant box image is [centos/7](https://atlas.hashicorp.com/centos/boxes/7), because that's the most-used image
currently available.

## What is not included?

Databases are not included, and must be sourced separately.

## Where is everything?

The contents of the `web-devsetup` checkout are available under the `/vagrant` directory on the guest VM. This is standard Vagrant setup.

The contents of your workspace are available under `/weblab` on the guest VM.

There are separate locations for `php.ini` for each PHP version:

  - PHP 5.5: `/opt/remi/php55/root/etc/php.ini`
  - PHP 5.6: `/opt/remi/php56/root/etc/php.ini`
  - PHP 7.0: `/etc/opt/remi/php70/php.ini`
  - PHP 7.1: `/etc/opt/remi/ph71/php.ini`
  
MySQL databases are under `/var/lib/mysql`, the standard location.

Nginx virtual hosts are under `/etc/nginx/conf.d`, the standard location.

If making edits to configuration files that would otherwise be useful to others, consider updating the files in the `templates` directory of the `web-devsetup` checkout, and re-running the provision script to apply them to the VM. Then submit your changes back to the repository via a pull request.


