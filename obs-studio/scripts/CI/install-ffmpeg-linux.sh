#!/bin/bash

set -ex

export PATH=$(readlink -f .):$PATH

mkdir -p codecs_ffmpeg
cd codecs_ffmpeg

echo "Installing dependencies"
apt-get update
apt-get -qqy install software-properties-common
add-apt-repository ppa:jonathonf/ffmpeg-4 -y
apt-get update
apt-get -qqy install apt-transport-https ca-certificates curl wget software-properties-common
apt-get -qqy install autoconf automake bash build-essential liblilv-dev libcodec2-dev checkinstall
apt-get -qqy install cmake libass-dev libfreetype6-dev libsdl2-dev libtool libva-dev libvdpau-dev
apt-get -qqy install libx265-dev libnuma-dev texinfo zlib1g-dev libopenjp2-7-dev librtmp-dev
apt-get -qqy install frei0r-plugins-dev gawk libfontconfig-dev libfreetype6-dev libopencore-amrwb-dev
apt-get -qqy install libsdl2-dev libspeex-dev libtheora-dev libtool libva-dev cmake libopencore-amrnb-dev
apt-get -qqy install libvdpau-dev libvo-amrwbenc-dev sudo tar texi2html yasm libxvidcore-dev lsb-release pkg-config
apt-get -qqy install libvorbis-dev libwebp-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev

apt-get update
apt-get -qqy install build-essential curl tar libass-dev cmake
apt-get -qqy install libtheora-dev libvorbis-dev libtool automake autoconf
apt-get -qqy install libspeexdsp-dev pkg-config git libxml2-dev
apt-get -qqy install wget yasm libchromaprint-dev libfdk-aac-dev

## Build FFMPEG
apt-get -qqy install libbs2b-dev ladspa-sdk libbluray-dev libcaca-dev libmp3lame-dev libaom-dev
apt-get -qqy install libgme-dev libgsm1-dev libopenmpt-dev libopus-dev librsvg2-dev librubberband-dev
apt-get -qqy install libshine-dev libsoxr-dev libtwolame-dev libvpx-dev libwavpack-dev libx264-dev
apt-get -qqy install libzvbi-dev libopenal-dev libomxil-bellagio-dev libjack-dev libcdio-paranoia-dev


echo "Installing the NVidia Video CODEC"
git clone --depth=1 https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
( cd nv-codec-headers ; make -j$(nproc) ; make -j$(nproc) install )


## https://www.ffmpeg.org/general.html#toc-AMD-AMF_002fVCE
echo "Installing the AMD AMFCodec"
mkdir -p /usr/local/include/AMF
git clone --depth=1 https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git
cp -aR AMF/amf/public/include/* /usr/local/include/AMF/
rm -rf nv-codec-headers AMF

echo "Compiling ffmpeg"
ffmpeg_version="snapshot"
if [ ! -f ffmpeg-${ffmpeg_version}.tar.bz2 ]; then
    wget http://ffmpeg.org/releases/ffmpeg-${ffmpeg_version}.tar.bz2
fi
tar xjf ffmpeg-${ffmpeg_version}.tar.bz2
cd ffmpeg
./configure --prefix="/usr" --extra-version="Debian~$(lsb_release -rs)" \
    --toolchain=hardened \
    --libdir=/usr/lib/x86_64-linux-gnu \
    --incdir=/usr/include/x86_64-linux-gnu \
    --bindir="/usr/bin" \
    --disable-static \
    --enable-shared \
    --arch=amd64 \
    --enable-gpl \
    --disable-stripping \
    --enable-hardcoded-tables \
    --enable-v4l2_m2m \
    --enable-gnutls \
    --enable-ladspa \
    --enable-libass \
    --enable-libbluray \
    --enable-libbs2b \
    --enable-libcaca \
    --enable-libcdio \
    --enable-libcodec2 \
    --enable-libfontconfig \
    --enable-libfreetype \
    --enable-libfribidi \
    --enable-libgme \
    --enable-libgsm \
    --enable-libjack \
    --enable-libmp3lame \
    --enable-libopenjpeg \
    --enable-libopenmpt \
    --enable-libopus \
    --enable-libfdk-aac \
    --enable-libass \
    --enable-libpulse \
    --enable-librsvg \
    --enable-librubberband \
    --enable-libshine \
    --enable-libsoxr \
    --enable-libspeex \
    --enable-libtheora \
    --enable-libtwolame \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libwavpack \
    --enable-libwebp \
    --enable-chromaprint \
    --enable-frei0r \
    --enable-libxml2 \
    --enable-libzvbi \
    --enable-lv2 \
    --enable-omx \
    --enable-openal \
    --enable-opengl \
    --enable-sdl2 \
    --enable-nonfree \
    --enable-libfdk-aac \
    --enable-ffnvcodec \
    --enable-cuvid \
    --enable-nvenc \
    --enable-amf \
    --enable-libx265 \
    --enable-libx264 \
    --enable-libxvid \
    --enable-libopus \
    --enable-librtmp \
    --enable-vaapi \
    --enable-vdpau \
    --enable-gray \
    --enable-iconv \
    --enable-pic \
    --enable-libaom \
    --enable-nonfree


make -j$(nproc)
make -j$(nproc) install
checkinstall --pkgname=FFmpeg --deldoc=yes --deldoc=yes --nodoc --fstrans=no --backup=no --install=no --maintainer=jniltinho@gmail.com -y
