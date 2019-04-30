#!/bin/bash
## Install FFMPEG 4.1.3 + OBS STUDIO 23.1.0 + NVENC on Ubuntu 16.04|18.04|19.04 64Bits

## https://gist.github.com/sparrc/026ed9958502072dda749ba4e5879ee3
## https://gist.github.com/jniltinho/9273dc133796062c13ca739d17862125
## Installs ffmpeg from source (HEAD) with libaom and libx265

# This script will compile and install a static ffmpeg build with support for
# nvenc on ubuntu. See the prefix path and compile options if edits are needed
# to suit your needs.

# Authors:
# jniltinho

set -e

ShowUsage() {
    echo 'Usage: ./NVENC-FFMPEG-OBSbuild.sh --dest /opt/ffmpeg-obs'
    echo "Options:"
    echo "  -d/--dest: Where to build ffmpeg (Optional, defaults to /opt/ffmpeg-obs)"
    echo "  -h/--help: This help screen"
    exit 0
}

root_dir="/mnt/ffmpeg_install/OBS-Studio"

## Folder to created deb/tar.gz
FOLDER_FPM="/tmp/installdir"

params=$(getopt -n $0 -o d:h --long dest:,help -- "$@")
eval set -- $params
while true; do
    case "$1" in
    -h | --help)
        ShowUsage
        shift
        ;;
    -d | --dest)
        build_dir=$2
        shift 2
        ;;
    *)
        shift
        break
        ;;
    esac
done

cpus=$(nproc)
source_dir="${root_dir}/source"
mkdir -p $source_dir
build_dir="${build_dir:-"/opt/ffmpeg-obs"}"
mkdir -p $build_dir
bin_dir="${build_dir}/bin"
mkdir -p $bin_dir
inc_dir="${build_dir}/include"
mkdir -p $inc_dir

echo "Building FFmpeg in ${build_dir}"

export PATH=$bin_dir:$PATH

InstallDependencies() {
    echo "Installing dependencies"

    # Check if user has root privileges
    if [[ $EUID -ne 0 ]]; then
        echo "You must run the script as root or using sudo"
        exit 1
    fi

    apt-get update
    apt-get -qqy install apt-transport-https ca-certificates curl software-properties-common
    mkdir -p "${build_dir}/bin"
}

# TODO Detect running system
CheckDistro() {
    echo "Check Distro ...."
    DIST=$(lsb_release -cs)

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

}

InstallFFmpegBase() {
    echo "Installing FFMPEG BASE ..."
    apt-get -qqy install build-essential libspeexdsp-dev pkg-config cmake git ruby-dev
    apt-get -qqy install wget yasm libchromaprint-dev libfdk-aac-dev libmbedtls-dev
    ## apt-get -qqy install libmfx-dev # Ubuntu Disco for --enable-libmfx
    apt-get -qqy build-dep ffmpeg
    gem install fpm
}

InstallNvidiaSDK() {
    echo "Installing the NVidia Video CODEC"
    cd $source_dir
    git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
    cd nv-codec-headers
    make
    make install
}

BuildFFmpeg() {
    echo "Compiling ffmpeg"
    cd $source_dir
    ffmpeg_version="4.1.3"
    ## ffmpeg_version="snapshot-git"
    if [ ! -f ffmpeg-${ffmpeg_version}.tar.bz2 ]; then
        wget -4 http://ffmpeg.org/releases/ffmpeg-${ffmpeg_version}.tar.bz2
    fi
    tar xjf ffmpeg-${ffmpeg_version}.tar.bz2
    mv ffmpeg-${ffmpeg_version} ffmpeg
    cd ffmpeg
    PKG_CONFIG_PATH="${build_dir}/lib/pkgconfig" ./configure --prefix="$build_dir" --extra-version="0ub~$(lsb_release -rs)" \
        --toolchain=hardened \
        --bindir="$bin_dir" \
        --disable-static \
        --enable-shared \
        --extra-cflags="-fPIC -m64 -I${inc_dir}" \
        --extra-ldflags="-L${build_dir}/lib" \
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
    rm -rf $FOLDER_FPM/usr/share/doc

}

BuildOBS() {
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

    cd $source_dir
    export FFmpegPath="${source_dir}/ffmpeg"
    git clone --recursive https://github.com/obsproject/obs-studio.git
    cd obs-studio
    mkdir build && cd build
    cmake -DUNIX_STRUCTURE=1 -DCMAKE_INSTALL_PREFIX=$build_dir ..
    make -j$(nproc)
    make install
    make DESTDIR=$FOLDER_FPM install

}

CleanAll() {
    rm -rf $source_dir
}

MakeLauncherOBS() {
    mkdir -p $build_dir/scripts
    cat <<EOF >$build_dir/scripts/ffmpeg-nvenc
#!/bin/bash
export LD_LIBRARY_PATH="${build_dir}/lib":\$LD_LIBRARY_PATH
${build_dir}/bin/ffmpeg "\$@"
EOF
    chmod +x $build_dir/scripts/ffmpeg-nvenc

    cat <<EOF >$build_dir/scripts/obs-portable
#!/bin/bash
export LD_LIBRARY_PATH="${build_dir}/lib":\$LD_LIBRARY_PATH
cd "${build_dir}/bin"
./obs "\$@"
EOF
    chmod +x $build_dir/scripts/obs-portable

    mkdir -p $FOLDER_FPM/usr/share/applications
    cat <<EOF >$FOLDER_FPM/usr/share/applications/obs-portable.desktop
[Desktop Entry]
Version=1.0
Name=OBS STUDIO PORTABLE
Comment=OBS-STUDIO-PORTABLE
Categories=Video;
Exec=${build_dir}/scripts/obs-portable %U
Icon=obs-portable
Terminal=false
Type=Application
Categories=AudioVideo;Recorder;
EOF


    mkdir -p $FOLDER_FPM/usr/local/bin/
    mkdir -p $FOLDER_FPM/usr/share/icons/
    mkdir -p $FOLDER_FPM/$build_dir/scripts
    mkdir -p $FOLDER_FPM/usr/share/icons
    cp -aR $build_dir/scripts/* $FOLDER_FPM/$build_dir/scripts/
    cp $build_dir/scripts/obs-portable $FOLDER_FPM/usr/local/bin/
    cp $build_dir/scripts/ffmpeg-nvenc $FOLDER_FPM/usr/local/bin/
    cp $source_dir/obs-studio/UI/forms/images/obs.png $FOLDER_FPM/usr/share/icons/obs-portable.png
}

MakeDEB() {
    cd $source_dir
    DIST=$(lsb_release -cs)
    fpm --deb-no-default-config-files -s dir -t deb -C $FOLDER_FPM -n ffmpeg-obs-nvenc -v 23.1.0 \
        -p ffmpeg-obs-nvenc_23.1.0+${DIST}-1_amd64.deb .
    rm -rf $FOLDER_FPM
    mkdir -p /root/dist/
    cp $source_dir/ffmpeg-obs-nvenc_* /root/dist/
}

if [ $1 ]; then
    $1
else
    InstallDependencies
    CheckDistro
    InstallFFmpegBase
    InstallNvidiaSDK
    BuildFFmpeg
    BuildOBS
    MakeLauncherOBS
    MakeDEB
fi
