#!/usr/bin/env bash

# Create the user account
if ! id debian >/dev/null 2>&1; then
    groupadd --gid 1020 debian
    useradd --shell /bin/bash --uid 1020 --gid 1020 --groups sudo --password "$(openssl passwd debian)" --create-home --home-dir /home/debian debian
    echo "alias vim=nvim" >> /home/ubuntu/.bashrc 
    echo "alias v=nvim" >> /home/ubuntu/.bashrc
    echo "exec i3" > /home/ubuntu/.xsession
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

