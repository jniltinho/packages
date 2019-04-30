#!/bin/bash
## Install FFMPEG 4.1.3 + OBS STUDIO 23.1.0 + NVENC on Ubuntu 16.04|18.04|19.04 64Bits

## https://gist.github.com/sparrc/026ed9958502072dda749ba4e5879ee3
## https://gist.github.com/jniltinho/9273dc133796062c13ca739d17862125
## Installs ffmpeg from source (HEAD) with libaom and libx265

# Check if user has root privileges
if [[ $EUID -ne 0 ]]; then
  echo "You must run the script as root or using sudo"
  exit 1
fi

apt-get update
apt-get -qqy install apt-transport-https ca-certificates curl software-properties-common

DIST=$(lsb_release -cs)
FOLDER_FPM="/tmp/installdir"

mkdir -p /install_ffmpeg
cd /install_ffmpeg

if [[ $DIST == 'xenial' || $DIST == 'bionic' ]]; then
  add-apt-repository ppa:jonathonf/ffmpeg-4 -y
  sed -i "/^# deb-src/ s/^# //" /etc/apt/sources.list.d/jonathonf-ubuntu-ffmpeg-4-$DIST.list
  # cat /etc/apt/sources.list.d/jonathonf-ubuntu-ffmpeg-4-$DIST.list
  apt-get update
fi

if [[ $DIST == 'disco' ]]; then
  cp /etc/apt/sources.list /etc/apt/sources.list_$$.bkp
  sed -i -e "/^# deb-src .*${DIST} universe/ s/^# //" /etc/apt/sources.list
  apt-get update
fi

apt-get -qqy install build-essential libspeexdsp-dev pkg-config cmake git ruby-dev
apt-get -qqy install wget yasm libchromaprint-dev libfdk-aac-dev
apt-get -qqy build-dep ffmpeg
gem install fpm

## Install NV-CODEC
cd /install_ffmpeg
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
make
make install

cd /install_ffmpeg
wget https://ffmpeg.org/releases/ffmpeg-4.1.3.tar.bz2
tar -xf ffmpeg-4.1.3.tar.bz2
rm ffmpeg-4.1.3.tar.bz2
cd ffmpeg-4.1.3
./configure --prefix=/usr --extra-version="0jn~$(lsb_release -rs)" \
  --toolchain=hardened \
  --disable-static \
  --enable-shared \
  --libdir=/usr/lib/x86_64-linux-gnu \
  --incdir=/usr/include/x86_64-linux-gnu \
  --arch=amd64 \
  --enable-gpl \
  --disable-stripping \
  --enable-avresample --disable-filter=resample \
  --enable-avisynth \
  --enable-gnutls \
  --enable-ladspa \
  --enable-libaom \
  --enable-libass \
  --enable-libbluray \
  --enable-libbs2b \
  --enable-libcaca \
  --enable-libcdio \
  --enable-libcodec2 \
  --enable-libflite \
  --enable-libfontconfig \
  --enable-libfreetype \
  --enable-libfribidi \
  --enable-libgme \
  --enable-libgsm \
  --enable-libjack \
  --enable-libmp3lame \
  --enable-libmysofa \
  --enable-libopenjpeg \
  --enable-libopenmpt \
  --enable-libopus \
  --enable-libpulse \
  --enable-librsvg \
  --enable-librubberband \
  --enable-libshine \
  --enable-libsnappy \
  --enable-libsoxr \
  --enable-libspeex \
  --enable-libssh \
  --enable-libtheora \
  --enable-libtwolame \
  --enable-libvidstab \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libwavpack \
  --enable-libwebp \
  --enable-libx265 \
  --enable-chromaprint \
  --enable-frei0r \
  --enable-libx264 \
  --enable-libxml2 \
  --enable-libxvid \
  --enable-libzmq \
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
  --enable-vaapi \
  --enable-vdpau \
  --enable-gray \
  --enable-iconv \
  --enable-pic \
  --enable-nonfree

retVal=$?
if [ $retVal -ne 0 ]; then
  echo 'FFMPEG >> Error ./configure ...'
  exit $retVal
fi

make -j$(nproc)
retVal=$?
if [ $retVal -ne 0 ]; then
  echo 'FFMPEG >> Error make ...'
  exit $retVal
fi

make install
make DESTDIR=$FOLDER_FPM install
rm -rf $FOLDER_FPM/usr/share

## Install OBS STUDIO 23.1.0
apt-get -qqy install \
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
  libvlc-dev \
  libx11-dev \
  libx264-dev \
  libxcb-shm0-dev \
  libxcb-xinerama0-dev \
  libxcomposite-dev \
  libxinerama-dev \
  pkg-config \
  python3-dev \
  qtbase5-dev \
  libqt5svg5-dev \
  swig

cd /install_ffmpeg
git clone --recursive https://github.com/obsproject/obs-studio.git
cd obs-studio
mkdir build && cd build

cmake -DUNIX_STRUCTURE=0 -DCMAKE_INSTALL_PREFIX="/opt/obs-studio-portable" ..
retVal=$?
if [ $retVal -ne 0 ]; then
  echo 'OBS STUDIO >> Error cmake ...'
  exit $retVal
fi

make -j$(nproc)

make install
retVal=$?
if [ $retVal -ne 0 ]; then
  echo 'OBS STUDIO >> Error make install ...'
  exit $retVal
fi

make DESTDIR=$FOLDER_FPM install

mkdir -p $FOLDER_FPM/usr/local/bin
mkdir -p $FOLDER_FPM/usr/share/applications/

echo '#!/bin/sh
cd /opt/obs-studio-portable/bin/64bit/
./obs &' >$FOLDER_FPM/usr/local/bin/obs-portable

chmod +x $FOLDER_FPM/usr/local/bin/obs-portable

echo '[Desktop Entry]
Version=1.0
Name=OBS-PORTABLE
GenericName=Streaming/Recording Software
Comment=Free and Open Source Streaming/Recording Software
Exec=obs-portable
Icon=obs
Terminal=false
Type=Application
Categories=AudioVideo;Recorder;
StartupNotify=true' >$FOLDER_FPM/usr/share/applications/obs-portable.desktop

fpm -s dir -t tar -C $FOLDER_FPM -n ffmpeg-obs-nvenc -v 23.1.0 -p ffmpeg-obs-nvenc_23.1.0+${DIST}-1_amd64.tar .
gzip ffmpeg-obs-nvenc_23.1.0+${DIST}-1_amd64.tar
rm -rf $FOLDER_FPM

mkdir -p /root/dist/
cp ffmpeg-obs-nvenc_* /root/dist/
