# -*- mode: ruby -*-

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "bento/debian-9.4"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
#  config.vm.box_url = "https://atlas.hashicorp.com/ARTACK/boxes/debian-jessie"

  # Increase available ram a notch
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
    vb.customize ["modifyvm", :id, "--usbehci", "off"]

    # Prevent pegging of the host CPU
    # Ref. https://www.virtualbox.org/ticket/18089?cversion=0&cnum_hist=16
    vb.customize ["modifyvm", :id, "--audio", "none"]

    # The following is needed to work around a virtualbox bug
    # Ref. https://github.com/chef/bento/issues/688#issuecomment-252404560
    vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
  end

  config.vm.network "private_network", ip: "10.10.10.23"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder "salt", "/srv/salt"
  config.vm.synced_folder "pillar", "/srv/pillar"

  # Prevent TTY Errors (copied from laravel/homestead: "homestead.rb" file)... By default this is "bash -l".
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.vm.provision "shell", inline: "sudo apt-get update && sudo apt-get install -y vim"

  config.vm.provision :salt do |salt|
    salt.minion_config = "vagrant-minion"
    salt.verbose = true
    salt.log_level = 'warning'
  end

  config.vm.provision "shell", inline: "sudo salt-call saltutil.sync_all"

end
