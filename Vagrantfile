# -*- mode: ruby -*-

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "bento/debian-12.0"

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
  config.vm.provision "shell", inline: "cat /vagrant/salt-release-key.asc | gpg --dearmor | sudo tee /usr/share/keyrings/salt-archive-keyring-2023.gpg >/dev/null"
  # Salt hasn't released binaries for bookworm yet, but the bullseye ones should be compatible
  config.vm.provision "shell", inline: "echo 'deb [signed-by=/usr/share/keyrings/salt-archive-keyring-2023.gpg] https://packages.broadcom.com/artifactory/saltproject-deb/ stable main' | tee /etc/apt/sources.list.d/saltstack.list"
  config.vm.provision "shell", inline: "echo -e 'Package: salt-*\nPin: version 3006.*\nPin-Priority: 1001' | tee /etc/apt/preferences.d/salt-pin-1001"
  config.vm.provision "shell", inline: "sudo apt-get update --allow-releaseinfo-change && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y vim salt-minion"
  # This can be removed after salt is upgraded to >=3006.10 or >=3007.2 (ref https://github.com/saltstack/salt/issues/66467)
  config.vm.provision "shell", name: "Remove noisy and unused compat module", inline: "rm -f /opt/saltstack/salt/lib/python3.10/site-packages/salt/utils/psutil_compat.py /opt/saltstack/salt/lib/python3.10/site-packages/salt/utils/__pycache__/psutil_compat.cpython-310.pyc"
  config.vm.provision "shell", inline: "sudo cp /vagrant/vagrant-minion /etc/salt/minion && sudo service salt-minion restart"
  config.vm.provision "shell", inline: "sudo salt-call saltutil.sync_all"

end
