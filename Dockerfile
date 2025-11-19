# Build xrdp pulseaudio modules in builder container
# See https://github.com/neutrinolabs/pulseaudio-module-xrdp/wiki/README
# Also build neovim in container
ARG TAG=trixie
FROM debian:trixie-slim AS builder

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        autoconf \
        cmake \
        build-essential \
        ca-certificates \
        dpkg-dev \
        libpulse-dev \
        lsb-release \
        git \
        libtool \
        libltdl-dev \
        doxygen \
        gettext \
        sudo && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git /pulseaudio-module-xrdp
WORKDIR /pulseaudio-module-xrdp
RUN scripts/install_pulseaudio_sources_apt.sh && \
    ./bootstrap && \
    ./configure PULSE_DIR=$HOME/pulseaudio.src && \
    make && \
    make install DESTDIR=/tmp/install
RUN git clone https://github.com/neovim/neovim /neovim
WORKDIR /neovim
RUN make -j8 CMAKE_BUILD_TYPE=RelWithDbeInfo && \
    make install DESTDIR=/tmp/install

# Build the final image
FROM debian:trixie-slim

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        curl \
        dbus-x11 \
        git \
        locales \
        pavucontrol \
        pulseaudio \
        pulseaudio-utils \
        sudo \
        x11-xserver-utils \
        i3 \
        i3-wm \
        i3blocks \
        pasystray \
        xorgxrdp \
        xrdp \
        i3status \
        kitty \
        nm-tray \
        picom \
        zsh \
        npm \
        python3-venv \
        ripgrep \
        fzf && \
    curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg && \
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list && \
        apt-get update && \
        DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends brave-browser && \
        rm -rf /var/lib/apt/lists/* && \
        locale-gen en_US.UTF-8

COPY --from=builder /tmp/install /
RUN sed -i 's|^Exec=.*|Exec=/usr/bin/pulseaudio|' /etc/xdg/autostart/pulseaudio-xrdp.desktop

ENV LANG=en_US.UTF-8
COPY entrypoint.sh /usr/bin/entrypoint
EXPOSE 3389/tcp
ENTRYPOINT ["/usr/bin/entrypoint"]
