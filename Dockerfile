# Build xrdp pulseaudio modules in builder container
# See https://github.com/neutrinolabs/pulseaudio-module-xrdp/wiki/README
# Also build neovim in container
ARG TAG=noble
FROM ubuntu:$TAG AS builder

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
FROM ubuntu:$TAG

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
        vim \
        x11-xserver-utils \
        xfce4 \
        xfce4-goodies \
        xfce4-pulseaudio-plugin \
        xorgxrdp \
        xrdp \
        xubuntu-icon-theme \
        i3 \
        curl \
        kitty \
        ripgrep \
        fzf \
        kitty \
        neovim \
        && \
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

# Set wm to i3
RUN echo "exec i3" > /home/ubuntu/.xsession

# Install NvChad for VIM
# RUN git clone https://github.com/LazyVim/starter /home/ubuntu/.config/nvim --this is for Lazyvim; we are using NVChad instead.
RUN mv /home/ubuntu/.config/nvim{,.bak}
# RUN git clone -b v2.5 https://github.com/NvChad/NvChad /home/ubuntu/.config/nvim --depth 1
RUN git clone https://github.com/NvChad/NvChad /home/ubuntu/.config/nvim --depth 1
RUN rm -rf /home/ubuntu/.config/nvim/.git
RUN echo "alias vim=nvim" >> /home/ubuntu/.bashrc 
RUN echo "alias v=nvim" >> /home/ubuntu/.bashrc

# Install Nerd Fonts
RUN mkdir -p /usr/local/share/fonts/jetbrains && curl -L -o /usr/local/share/fonts/jetbrains/jetbrains.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
RUN unzip /usr/share/local/share/fonts/jetbrains.zip
RUN fc-cache -fv

ENV LANG=en_US.UTF-8
COPY entrypoint.sh /usr/bin/entrypoint
EXPOSE 3389/tcp
ENTRYPOINT ["/usr/bin/entrypoint"]
