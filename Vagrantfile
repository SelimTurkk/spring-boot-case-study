Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-26.04"
  config.vm.hostname = "oyak-devops-vm"

  # Forward guest port 8080 to host port 8081.
  config.vm.network "forwarded_port",
    guest: 8080,
    host: 8081,
    host_ip: "127.0.0.1"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "oyak-devops-spring-boot-vm"
    vb.memory = 4096
    vb.cpus = 2
    vb.gui = true
  end

  config.vm.boot_timeout = 600
  # Share the project directory with the guest VM.
  config.vm.synced_folder ".", "/vagrant"

  # Provision Docker and start the application.
  config.vm.provision "shell", path: "provision.sh"
end
