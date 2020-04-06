# DEB Package OBS-STUDIO-PLUS for Ubuntu 18.04|19.04|20.04 64Bit

Build FFMPEG and OBS Studio Latest + (NVENC|AMFenc)

## Distros Support

* Ubuntu 18.04
* Ubuntu 19.04
* Ubuntu 20.04

## Compile FFMPEg + NVENC + OBS in the Docker

```bash
## Run as root (sudo su)
## First you need to install docker.
## sudo apt-get update
## sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common docker.io socat

mkdir install
cd install
wget https://gitlab.com/jniltinho/docker-ffmpeg/raw/master/NVENC-FFMPEG-OBSbuild.sh

## For Ubuntu 18.04
docker run --rm -it -v "${PWD}:/install" ubuntu:bionic /bin/bash

cd /install/
bash NVENC-FFMPEG-OBSbuild.sh --dest /opt/ffmpeg-obs
cp -aR /root/dist/*.deb /install/
exit
```

## Install Compiled files (FFMPEG and OBS STUDIO)

```bash
## Para Instalar, execute os passos abaixo:
## EXECUTAR COMO ROOT !!!!!
## Use por sua conta e risco, no meu Desktop Ubuntu 18.04 funcionou perfeitamente.
## Esses são Binarios já compilados do OBS e FFMPEG, só funciona em sistemas 64Bits.
## Para Reportar Bug use o link: https://github.com/jniltinho/oficinadotux/issues.
## Se possivel com Print de Tela ou a saida com erro na linha de comando.
## Você pode executar os binarios via linha de comando: obs-portable e ffmpeg.
## Desse modo fica facil aparecer os erros.
```


### Ubuntu 18.04 - Bionic

```bash
apt-get update
add-apt-repository ppa:obsproject/obs-studio -y
add-apt-repository ppa:mc3man/bionic-media -y
apt-get update
apt-get -y install libcodec2-0.7 ffmpeg obs-studio

cd /tmp/
wget https://github.com/jniltinho/packages/releases/download/v2.0.0/ffmpeg-obs-nvenc_25.0.4+bionic-1_amd64.deb
dpkg -i ffmpeg-obs-nvenc_*+bionic-1_amd64.deb
```

### Ubuntu 19.04 - Disco

```bash
apt-get update
add-apt-repository ppa:obsproject/obs-studio -y
apt-get update
apt-get -y install libcodec2-0.7 ffmpeg obs-studio

cd /tmp/
wget https://github.com/jniltinho/packages/releases/download/v2.0.0/ffmpeg-obs-nvenc_25.0.4+disco-1_amd64.deb
dpkg -i ffmpeg-obs-nvenc_*+disco-1_amd64.deb
```

### Ubuntu 20.04 - Eoan

```bash
apt-get update
add-apt-repository ppa:obsproject/obs-studio -y
apt-get update
apt-get -y install libcodec2-0.7 ffmpeg obs-studio

cd /tmp/
wget https://github.com/jniltinho/packages/releases/download/v2.0.0/ffmpeg-obs-nvenc_25.0.4+eoan-1_amd64.deb
dpkg -i ffmpeg-obs-nvenc_*+eoan-1_amd64.deb
```
