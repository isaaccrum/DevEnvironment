#!/usr/bin/env bash

# Create the user account
if ! id debian >/dev/null 2>&1; then
    groupadd --gid 1020 debian
    useradd --shell /bin/bash --uid 1020 --gid 1020 --groups sudo --password "$(openssl passwd debian)" --create-home --home-dir /home/debian debian
    touch /home/ubuntu/.bashrc
    echo "alias vim=nvim" >> /home/ubuntu/.bashrc 
    echo "alias v=nvim" >> /home/ubuntu/.bashrc
    touch /home/ubuntu/.xsession
    echo "exec i3" > /home/ubuntu/.xsession

    # Install NvChad for VIM
    # git clone https://github.com/LazyVim/starter /home/ubuntu/.config/nvim --this is for Lazyvim; we are using NVChad instead.
    mv /home/ubuntu/.config/nvim{,.bak}
    # git clone -b v2.5 https://github.com/NvChad/NvChad /home/ubuntu/.config/nvim --depth 1
    git clone https://github.com/NvChad/NvChad /home/ubuntu/.config/nvim --depth 1
    rm -rf /home/ubuntu/.config/nvim/.git
    
    # Install Nerd Fonts
    mkdir -p /usr/local/share/fonts/jetbrains && curl -L -o /usr/local/share/fonts/jetbrains/jetbrains.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
    unzip /usr/share/local/share/fonts/jetbrains.zip
    fc-cache -fv
fi

# Remove existing sesman/xrdp PID files to prevent rdp sessions hanging on container restart
[ ! -f /var/run/xrdp/xrdp-sesman.pid ] || rm -f /var/run/xrdp/xrdp-sesman.pid
[ ! -f /var/run/xrdp/xrdp.pid ] || rm -f /var/run/xrdp/xrdp.pid

# Start xrdp sesman service
/usr/sbin/xrdp-sesman

# Run xrdp in foreground if no commands specified
if [ -z "$1" ]; then
    /usr/sbin/xrdp --nodaemon
else
    /usr/sbin/xrdp
    exec "$@"
fi

