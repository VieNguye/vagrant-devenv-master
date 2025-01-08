# Provisioning Local Development Environment with Virtualbox and Vagrant

[https://www.virtualbox.org/](https://www.virtualbox.org/)

[https://www.vagrantup.com/](https://www.vagrantup.com/)

[https://github.com/microsoft/terminal](https://github.com/microsoft/terminal)

Windows Powershell:
```sh
$ $env:INSTALL_STARSHIP = 1
$ $env:INSTALL_DOCKER = 1
$ $env:INSTALL_K8S_TOOLS = 1
$ vagrant up
$ vagrant reload
```

Linux Bash:
```sh
$ INSTALL_STARSHIP=1 INSTALL_DOCKER=1 INSTALL_K8S_TOOLS=1 vagrant up
$ vagrant reload
```
