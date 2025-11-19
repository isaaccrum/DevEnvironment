# Build xrdp pulseaudio modules in builder container
# See https://github.com/neutrinolabs/pulseaudio-module-xrdp/wiki/README
ARG TAG=noble
FROM rootpublic/debian:bookworm-slim AS builder

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        autoconf \
        build-essential \
        ca-certificates \
        dpkg-dev \
        libpulse-dev \
        lsb-release \
        git \
        libtool \
        libltdl-dev \
        sudo && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git /pulseaudio-module-xrdp
WORKDIR /pulseaudio-module-xrdp
RUN scripts/install_pulseaudio_sources_apt.sh && \
    ./bootstrap && \
    ./configure PULSE_DIR=$HOME/pulseaudio.src && \
    make && \
    make install DESTDIR=/tmp/install


# Build the final image
FROM rootpublic/debian:bookworm-slim

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        dbus-x11 \
        git \
        locales \
        pavucontrol \
        pulseaudio \
        pulseaudio-utils \
        software-properties-common \
        sudo \
        lazyls \
        vim \
        x11-xserver-utils \
        i3 \
        i3-wm \
        i3blocks \
        pasystray \
        xorgxrdp \
        xrdp \
        i3status \
        kitty \
        nm-applet \
        picom \
        zsh \
        npm \
        python3-venv \
        ripgrep \
        fzf && \
add-apt-repository -y ppa:mozillateam/ppa && \
    echo "Package: *"  > /etc/apt/preferences.d/mozilla-firefox && \
    echo "Pin: release o=LP-PPA-mozillateam" >> /etc/apt/preferences.d/mozilla-firefox && \
    echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/mozilla-firefox && \
    apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends firefox && \
    rm -rf /var/lib/apt/lists/* && \
    deluser --remove-home ubuntu && \
    locale-gen en_US.UTF-8

COPY --from=builder /tmp/install /
RUN sed -i 's|^Exec=.*|Exec=/usr/bin/pulseaudio|' /etc/xdg/autostart/pulseaudio-xrdp.desktop

ENV LANG=en_US.UTF-8
COPY entrypoint.sh /usr/bin/entrypoint
EXPOSE 3389/tcp
ENTRYPOINT ["/usr/bin/entrypoint"]
