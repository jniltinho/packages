#!/bin/sh
set -ex

curl -L https://packagecloud.io/github/git-lfs/gpgkey | sudo apt-key add -

# gets us newer clang
sudo bash -c "cat >> /etc/apt/sources.list" <<LLVMAPT
# 3.8
deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-8 main
deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic-8 main
LLVMAPT

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

apt-get update
apt-get -qqy install ccache cmake
apt-get -qqy install apt-transport-https ca-certificates curl software-properties-common
apt-get -qqy install autoconf automake bash build-essential liblilv-dev libcodec2-dev
apt-get -qqy install libass-dev libfreetype6-dev libsdl2-dev libtool libva-dev libvdpau-dev
apt-get -qqy install libx265-dev libnuma-dev texinfo zlib1g-dev libopenjp2-7-dev librtmp-dev
apt-get -qqy install frei0r-plugins-dev gawk libfontconfig-dev libfreetype6-dev libopencore-amrwb-dev
apt-get -qqy install libsdl2-dev libspeex-dev libtheora-dev libtool libva-dev libopencore-amrnb-dev
apt-get -qqy install libvdpau-dev libvo-amrwbenc-dev sudo tar texi2html yasm libxvidcore-dev lsb-release pkg-config
apt-get -qqy install libvorbis-dev libwebp-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev

apt-get -qq update
apt-get install -y \
        libmbedtls-dev \
        build-essential \
        checkinstall \
        cmake \
        libasound2-dev \
        libavcodec-dev \
        libavdevice-dev \
        libavfilter-dev \
        libavformat-dev \
        libavutil-dev \
        libcurl4-openssl-dev \
        libfdk-aac-dev \
        libfontconfig-dev \
        libfreetype6-dev \
        libgl1-mesa-dev \
        libjack-jackd2-dev \
        libjansson-dev \
        libluajit-5.1-dev \
        libpulse-dev \
        libqt5x11extras5-dev \
        libspeexdsp-dev \
        libswresample-dev \
        libswscale-dev \
        libudev-dev \
        libv4l-dev \
        libva-dev \
        libvlc-dev \
        libx11-dev \
        libx264-dev \
        libxcb-randr0-dev \
        libxcb-shm0-dev \
        libxcb-xinerama0-dev \
        libxcomposite-dev \
        libxinerama-dev \
        pkg-config \
        python3-dev \
        qtbase5-dev \
        libqt5svg5-dev \
        swig \
        clang-format-8
