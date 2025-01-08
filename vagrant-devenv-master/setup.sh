#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
# https://stackoverflow.com/questions/71603314/ssl-error-unsafe-legacy-renegotiation-disabled
echo 'export OPENSSL_CONF=/vagrant/openssl.conf' >> $HOME/.bashrc
source .bashrc

# https://www.cyberciti.biz/faq/explain-debian_frontend-apt-get-variable-for-ubuntu-debian/
update_system() {
    echo "grub-pc grub-pc/install_devices multiselect /dev/sda1" | sudo debconf-set-selections
    sudo apt-get update
    sudo apt-get -q -y \
					-o "Dpkg::Options::=--force-confdef" \
					-o "Dpkg::Options::=--force-confold" \
                    dist-upgrade

    sudo timedatectl set-timezone 'Asia/Ho_Chi_Minh'
    sudo dpkg-reconfigure --frontend=${DEBIAN_FRONTEND} tzdata

	local latest_kernel_version=$(sudo find /boot/vmlinuz-* -printf "%T+ %p\n" | \
						sort -r | head -1 | \
						awk '{print $2}' | \
						xargs -n 1 basename | \
						sed -n 's/vmlinuz-//p')
	[[ -z ${latest_kernel_version:-} ]] || \
		sudo apt-get install -y linux-headers-${latest_kernel_version}
}

install_basic_tools() {
    sudo apt-get -q -y install git vim curl wget \
                    htop tmux jq tree net-tools \
                    ca-certificates gnupg dos2unix

    sudo cp -v /vagrant/certs/*.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates

    cp -v /vagrant/.vimrc ~/.vimrc
    cp -v /vagrant/.tmux.conf ~/.tmux.conf
    # For Windows only
    chmod -x .vimrc .tmux.conf && dos2unix .vimrc .tmux.conf
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

install_starship() {
    curl -Lo ./starship.tar.gz https://github.com/starship/starship/releases/download/v1.18.2/starship-x86_64-unknown-linux-gnu.tar.gz
    tar -zxvf starship.tar.gz
    sudo install -o root -g root -m 0755 starship /usr/local/bin/
    rm -fv ./starship.tar.gz starship
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
    mkdir -pv ~/.config
    # https://starship.rs/config/
    cp -v /vagrant/starship.toml ~/.config/
    # For Windows only
	chmod -x ~/.config/starship.toml && dos2unix ~/.config/starship.toml
}

install_docker() {
    # https://docs.docker.com/engine/install/debian/
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -q -y docker-ce docker-ce-cli \
                    containerd.io docker-buildx-plugin \
                    docker-compose-plugin
    # https://docs.docker.com/engine/install/linux-postinstall/
    getent group docker || sudo groupadd docker
    sudo usermod -aG docker $USER
}

install_k8s_tools() {
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/
    rm -fv ./kubectl

    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
    sudo install -o root -g root -m 0755 kind /usr/local/bin/
    rm -fv ./kind
}

update_system
install_basic_tools
[[ -z ${INSTALL_STARSHIP:-} ]] || install_starship
[[ -z ${INSTALL_DOCKER:-} ]] || install_docker
[[ -z ${INSTALL_K8S_TOOLS:-} ]] || install_k8s_tools
