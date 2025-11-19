# DevEnvironment
Debian-based i3 development environment in a docker container running rdp

Just run compose.yaml as follows:

Compose.yaml
```
services:
  docker-remote-desktop:
    build: https://github.com/isaaccrum/DevEnvironment.git
    stdin_open: true
    tty: true
    hostname: dev-desktop
    ports:
      - 3389:3389/tcp
    container_name: dev-desktop-container
networks: {}
```
