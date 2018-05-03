#!/usr/bin/env bash

set -u
set -e

# Cannot rely on $0 due to how the Vagrant shell provisioner works.
SCRIPT_NAME="provision-weblab"

# Install a repository, but only if it isn't already installed.
#
# $1: A human-readable, arbitrary name for the repository.
# $2: Repository package name or RPM URL
function installRepo {
    local REPO_NAME="$1"
    local REPO_SOURCE="$2"
    local REPO_COUNT=$(yum repolist enabled | grep "$REPO_NAME" -c)

    if [[ "$REPO_COUNT" -lt 1 ]]; then
        sudo yum -y install "$REPO_SOURCE"
        echo "Installed $REPO_NAME repository"
    else
        echo "SKIPPED: $REPO_NAME repository is already installed"
    fi
}

# Install a package, but only if it isn't already installed.
function installPackage {
    if rpm -q "$@" >/dev/null 2>&1; then
        echo "SKIPPED: $@ is already installed."
    else
        # The http-parser package must be installed manually here prior to the nodejs install due to the fact that it is not available in the EPEL repo
        # This must remain until CentOS is updated to 7.4
        # Ensure that the http-parser install command is before the nodejs install in the list below.
        if [ "$@" == "http-parser" ]
        then
            yum -y install https://kojipkgs.fedoraproject.org//packages/http-parser/2.7.1/3.el7/x86_64/http-parser-2.7.1-3.el7.x86_64.rpm
        else
            yum -y install "$@"
        fi

        echo "Installed $@"
    fi
}

# Install a template, but only if it differs from the source.
#
# $1: A file path relative to /vagrant/templates
function installTemplate {
    local TEMPLATE_PATH="$1"
    local DESTINATION="${TEMPLATE_PATH#/vagrant/templates}"
    local DESTINATION_PARENT=$(dirname "$DESTINATION")

    if cmp --silent "$TEMPLATE_PATH" "$DESTINATION"; then
        echo "SKIPPED: $DESTINATION is up-to-date"
    else
        if [ ! -d "$DESTINATION_PARENT" ]; then
            mkdir -p "$DESTINATION_PARENT"
        fi

        sudo cp "$TEMPLATE_PATH" "$DESTINATION"
        echo "Installed $DESTINATION"
    fi
}

# Create a directory if it doesn't already exist.
function createDirectory {
    local DIR="$1"
    if [ ! -d "$DIR" ]; then
        sudo mkdir -p "$DIR"
    else
        echo "SKIPPED: $DIR already exists"
    fi
}

function deviceAddress {
    local DEVICE="$1"
    echo $(ip addr show "$DEVICE" 2>/dev/null | egrep -o "inet [^/]+" | cut -d' ' -f 2)
}

function symlinkPhp {
    local PHP_SYMLINK="/usr/bin/php"
    local PHP_71_SYMLINK="/usr/bin/php71"

    if [ ! -h "$PHP_71_SYMLINK" ]; then
        echo "ERROR symlinking PHP 7.1"
    else
        if [ ! -h "$PHP_SYMLINK" ]; then
            sudo ln -s "$PHP_71_SYMLINK" "$PHP_SYMLINK"
        else
            sudo rm "$PHP_SYMLINK"
            sudo ln -s "$PHP_71_SYMLINK" "$PHP_SYMLINK"
        fi
    fi
}

function installComposer {
    local VERSION="$1"
    local PHP_SYMLINK="/usr/bin/php"
    local BIN_COMPOSER="/usr/local/bin/composer"
    local HOME_COMPOSER_PHAR="/home/vagrant/composer.phar"
    local COMPOSER_PATH="https://getcomposer.org/download/$VERSION/composer.phar"
    local SYMLINK_MESSAGE=$(symlinkPhp)

    if [ -z "$SYMLINK_MESSAGE" ]; then
        if [ -f "$BIN_COMPOSER" ]; then
            if [ $(composer --version | grep -oP "[0-9.]*" | head -1) == "$VERSION" ]; then
                echo "Composer version $VERSION already installed."
            else
                if [ ! -z $(getComposer "$VERSION") ]; then
                    echo "ERROR installing composer."
                fi
            fi
        else
            if [ ! -z $(getComposer "$VERSION") ]; then
                echo "ERROR installing composer."
            fi
        fi
    else
        echo "$SYMLINK_MESSAGE"
    fi
}

function removeComposer {
    local HOME_COMPOSER_PHAR="/home/vagrant/composer.phar"
    local BIN_COMPOSER="/usr/local/bin/composer"

    if [ -f "$HOME_COMPOSER_PHAR" ]; then
        sudo rm "$HOME_COMPOSER_PHAR"
    fi

    if [ -f "$BIN_COMPOSER" ]; then
        sudo rm "$BIN_COMPOSER"
    fi
}

function getComposer {
    local VERSION="$1"
    local HOME_COMPOSER_PHAR="/home/vagrant/composer.phar"
    local BIN_COMPOSER="/usr/local/bin/composer"
    local COMPOSER_PATH="https://getcomposer.org/download/$VERSION/composer.phar"

    removeComposer

    sudo wget "$COMPOSER_PATH" "$HOME_COMPOSER_PHAR"
    if [ -f "$HOME_COMPOSER_PHAR" ]; then
        sudo mv "$HOME_COMPOSER_PHAR" "$BIN_COMPOSER"
        sudo chmod 0777 "$BIN_COMPOSER"
    else
        echo "ERROR"
    fi
}

echo "Starting $SCRIPT_NAME"

# Repositories

## For extra packages not in the default repository
## https://fedoraproject.org/wiki/EPEL
installRepo epel epel-release

## For multiple versions of PHP
## https://rpms.remirepo.net/wizard/
installRepo remi https://rpms.remirepo.net/enterprise/remi-release-7.rpm


## For MySQL
## https://dev.mysql.com/doc/mysql-yum-repo-quick-guide/en/
installRepo mysql https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm

# MySQL
installPackage mysql-community-server

# Nginx
installPackage nginx

# PHP packages
installPackage php55
installPackage php56
installPackage php56-php-devel
installPackage php70
installPackage php71

installPackage php55-php-fpm
installPackage php56-php-fpm
installPackage php70-php-fpm
installPackage php71-php-fpm

## Laravel dependency and generally desirable.
installPackage php55-php-pdo
installPackage php56-php-pdo
installPackage php70-php-pdo
installPackage php71-php-pdo

## Just in case.
installPackage php55-php-mysqlnd
installPackage php56-php-mysqlnd
installPackage php70-php-mysqlnd
installPackage php71-php-mysqlnd

## Laravel dependency.
installPackage php55-php-mbstring
installPackage php56-php-mbstring
installPackage php70-php-mbstring
installPackage php71-php-mbstring

## Laravel dependency.
installPackage php55-php-mcrypt
installPackage php56-php-mcrypt
installPackage php70-php-mcrypt
installPackage php71-php-mcrypt

## Vindicia dependency.
installPackage php55-php-soap
installPackage php56-php-soap
installPackage php70-php-soap
installPackage php71-php-soap

## Nice to have.
installPackage php55-php-pecl-xdebug
installPackage php56-php-pecl-xdebug
installPackage php70-php-pecl-xdebug
installPackage php71-php-pecl-xdebug

## Laravel dependency.
installPackage php55-php-xml
installPackage php56-php-xml
installPackage php70-php-xml
installPackage php71-php-xml

## GMP dependency
installPackage php55-php-gmp
installPackage php56-php-gmp
installPackage php70-php-gmp
installPackage php71-php-gmp

# Node
# The http-parser package must be installed from here prior to the nodejs install due to the fact that it is not available in the EPEL repo
# This must remain until CentOS is updated to 7.4
installPackage http-parser
installPackage nodejs

# Redis
installPackage redis

# System utilities
installPackage cowsay
installPackage emacs
installPackage zile
installPackage bind-utils
installPackage tree
installPackage tmux
installPackage figlet
installPackage ShellCheck
installPackage pv
installPackage sysstat

# Template population
for TEMPLATE in $(find /vagrant/templates -type f); do
    installTemplate "$TEMPLATE"
done

# Packages needed for compiling
installPackage bison
installPackage boost
installPackage boost-devel
installPackage boost-static
installPackage flex
installPackage gcc-c++
installPackage libevent-devel
installPackage libtool
installPackage mawk
installPackage openssl
installPackage openssl-devel
installPackage unzip
installPackage nano
installPackage git
installPackage wget


# Permissions
chcon -Rt httpd_sys_content_t "/var/www"
gpasswd -a nginx vagrant

# Services to run at startup
sudo systemctl enable mysqld
sudo systemctl enable nginx
sudo systemctl enable php55-php-fpm
sudo systemctl enable php56-php-fpm
sudo systemctl enable php70-php-fpm
sudo systemctl enable php71-php-fpm
sudo systemctl enable redis

# MySQL user accounts
#
## As of 5.7, a default root password is generated. It gets written to /var/log/mysqld.log
## Replace it with a predictable value that meets the expectations of the validate_password plugin.
##
## Also create a user account for day-to-day use.
MYSQL_ROOT_PASS="G42B&9i3"
MYSQL_USER_PASS="M24t^uHS"
MYSQL_USER_NAME="vagrant"
MY_CNF_ROOT="/home/vagrant/.my-root.cnf"
MY_CNF_USER="/home/vagrant/.my.cnf"

sudo systemctl stop mysqld
sudo systemctl set-environment MYSQLD_OPTS="--skip-grant-tables"
sudo systemctl start mysqld
mysql -uroot -e "UPDATE mysql.user SET authentication_string = PASSWORD('$MYSQL_ROOT_PASS'), password_expired='N' WHERE User='root' AND Host='localhost'"
sudo systemctl stop mysqld
sudo systemctl unset-environment MYSQLD_OPTS
sudo systemctl start mysqld

echo "[client]" > "$MY_CNF_ROOT"
echo "user=root" >> "$MY_CNF_ROOT"
echo "password=\"$MYSQL_ROOT_PASS\"" >> "$MY_CNF_ROOT"

echo "[client]" > "$MY_CNF_USER"
echo "user=$MYSQL_USER_NAME" >> "$MY_CNF_USER"
echo "password=\"$MYSQL_USER_PASS\"" >> "$MY_CNF_USER"

mysql --defaults-file="$MY_CNF_ROOT" -e "CREATE USER IF NOT EXISTS '$MYSQL_USER_NAME'@'localhost' IDENTIFIED BY '$MYSQL_USER_PASS'"
mysql --defaults-file="$MY_CNF_ROOT" -e "CREATE USER IF NOT EXISTS '$MYSQL_USER_NAME'@'%'         IDENTIFIED BY '$MYSQL_USER_PASS'"

mysql --defaults-file="$MY_CNF_ROOT" -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER_NAME'@'localhost' WITH GRANT OPTION";
mysql --defaults-file="$MY_CNF_ROOT" -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER_NAME'@'%'         WITH GRANT OPTION";

mysql --defaults-file="$MY_CNF_ROOT" -e "ALTER USER '$MYSQL_USER_NAME'@'localhost' PASSWORD EXPIRE NEVER";
mysql --defaults-file="$MY_CNF_ROOT" -e "ALTER USER '$MYSQL_USER_NAME'@'%'         PASSWORD EXPIRE NEVER";


# Mail
installPackage mutt

## Keep Yum cache up to date
installPackage yum-cron

# SSH
SSH_PRIVATE_KEY="/home/vagrant/.ssh/weblab_key"
SSH_PUBLIC_KEY="/home/vagrant/.ssh/weblab_key.pub"
AUTHORIZED_KEYS_FILE="/home/vagrant/.ssh/authorized_keys"
if [ -f "$SSH_PUBLIC_KEY" ]; then
    echo "SKIPPED: generation of SSH public key from private key copied from host. Already done."
elif [ -f "/vagrant/id_rsa" ]; then
    cp /vagrant/id_rsa "$SSH_PRIVATE_KEY"
    chmod 600 "$SSH_PRIVATE_KEY"
    ssh-keygen -y -C "weblab" -f "$SSH_PRIVATE_KEY" > "$SSH_PUBLIC_KEY"
    chown vagrant:vagrant "$SSH_PUBLIC_KEY" "$SSH_PRIVATE_KEY"
    echo "Created a new SSH public key from the private copied from the host."

    if ! grep -q -f "$SSH_PUBLIC_KEY" "$AUTHORIZED_KEYS_FILE"; then
        cat "$SSH_PUBLIC_KEY" >> "$AUTHORIZED_KEYS_FILE"
        echo "Updated $AUTHORIZED_KEYS_FILE"
    fi
else
    echo "NOTICE: No SSH key found at /vagrant/id_rsa."
    echo "NOTICE: Vagrant could not find an SSH key on the host to copy into the VM."
    echo "NOTICE: You can still log in via \"vagrant ssh\", but direct SSH connections will prompt for a password."
    echo "NOTICE: Consider copying your private key into the dev-setup checkout and re-running the provision script via \"vagrant provision\"."
    echo "NOTICE: This is optional."
fi


# Apply sysctl settings from template
sudo sysctl -p /etc/sysctl.d/weblab.conf

# Restart services (always, regardless of whether anything has changed)
sudo systemctl restart php55-php-fpm
sudo systemctl restart php56-php-fpm
sudo systemctl restart php70-php-fpm
sudo systemctl restart php71-php-fpm
sudo systemctl restart nginx
sudo systemctl restart mysqld
sudo systemctl restart redis
sudo systemctl restart postfix

# Verify the guest IP
## It's unclear why, but the eth1 interface might not be ready.
## Restarting the network service seems to fix the problem.
GUEST_IP=$(deviceAddress eth1)
if [ -z "$GUEST_IP" ]; then
    sudo systemctl restart network
    GUEST_IP=$(deviceAddress eth1)
fi

if [ -z "$GUEST_IP" ]; then
    echo "ERROR: Could not verify IP of eth1 device in spite of network service restart"
    exit 1
fi

# Disable SELinux
#
# Although the template for /etc/selinux/config has been applied, its
# settings will not take effect until the next reboot. Calling
# setenforce deactivates selinux in the meantime as a temporary
# measure, so that both present and future machine state are accounted
# for.
#
# SELinux is being disabled in the first place so that nginx and
# php-fpmd are able to serve files out of a VirtualBox shared
# folder. Applying the httpd_sys_content_t context to /weblab should
# be possible, but apparently involves goat sacrifice.
#
# See https://github.com/mitchellh/vagrant/issues/6970

if $(sudo selinuxenabled); then
    sudo setenforce Permissive
fi

# Add aliases to /home/vagrant/.bashrc
VAGRANT_USER_BASHRC="/home/vagrant/.bashrc"
COMPOSER_VERSION="1.6.4"
echo "alias la='ls -al --color=auto'" >> "$VAGRANT_USER_BASHRC"
#installComposer "$COMPOSER_VERSION"
ERROR_MESSAGE=$(installComposer "$COMPOSER_VERSION")
if [ ! -z "$ERROR_MESSAGE" ]; then
    echo "$ERROR_MESSAGE"
    exit 1
else
    echo "Composer installed successfully"
fi


cowsay "Provisioning is complete! The IP of this machine is $GUEST_IP and your hosts file has been updated. Now visit http://weblab.local for credentials and setup details."
