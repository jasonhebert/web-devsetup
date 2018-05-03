# -*- mode: ruby -*-
# vi: set ft=ruby :

# This version number isn't special, it's just the version already in
# use when the idea to specify a minimum version came up.
Vagrant.require_version ">= 1.8.6"

# Check for required plugins
if ARGV[0] == 'up'
  required_plugins = %w( vagrant-vbguest vagrant-hosts-provisioner )
  missing_plugins = []
  required_plugins.each do |plugin|
    missing_plugins.push(plugin) unless Vagrant.has_plugin? plugin
  end

  if ! missing_plugins.empty?
    installation_list = missing_plugins.join(' ')
    puts "Found missing plugins: #{installation_list}.  Attempting installation..."
    exec "vagrant plugin install #{installation_list}"
    puts "Plugin installation finished. Now do another vagrant up"
  end
end


if ARGV[0] == 'provision'
  user_private_key = File.expand_path("~/.ssh/id_rsa")
  local_private_key = File.expand_path("id_rsa", File.dirname(__FILE__))

  if File.exist? user_private_key and not File.exist? local_private_key
    puts "Copying your default SSH key for later population in the guest VM"
    FileUtils.cp(user_private_key, local_private_key)
  end
end

# https://docs.vagrantup.com.
Vagrant.configure("2") do |config|

  # https://atlas.hashicorp.com/search
  config.vm.box = "centos/7"

  # Use specific known working box version
  config.vm.box_version = "1707.01"

  # Update checking turned off
  config.vm.box_check_update = false

  # Hostname
  config.vm.hostname = "weblab"

  # Port forwarding
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Network adapters
  config.vm.network "private_network", ip: "10.4.10.4"

  # Filesystem sharing from host to guest.
  #
  # https://www.vagrantup.com/docs/synced-folders/
  #
  ## The /vagrant share is configured by default but
  ## redefined here to ensure the type doesn't default to rsync.
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  config.vm.synced_folder "../", "/weblab", type: "virtualbox"

  # Provider-specific configuration
  #
  # https://www.vagrantup.com/docs/virtualbox/configuration.html
  #
  config.vm.provider "virtualbox" do |vb|

    # The amount of memory on the VM
    vb.memory = 2048

    # The name shown in the VirtualBox UI
    vb.name = config.vm.hostname

    # vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
  end

  # Hostfile management courtesy of the vagrant-hosts-provsioner plugin
  ## https://github.com/mdkholy/vagrant-hosts-provisioner
  config.vm.provision :hostsupdate, run: "always" do |host|
    host.hostname = config.vm.hostname
    host.manage_host = true
    host.manage_guest = true
    host.aliases = [
      "weblab.local",
      "php55.weblab.local",
      "php56.weblab.local",
      "php70.weblab.local",
      "php71.weblab.local",
      "central-api.weblab.local"
    ]
  end


  # Provisioning
  #
  # https://www.vagrantup.com/docs/provisioning/shell.html
  #
  config.vm.provision "shell", path: "provision-weblab.sh"
end
