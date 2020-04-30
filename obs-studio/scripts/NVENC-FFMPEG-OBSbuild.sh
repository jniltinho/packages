#!/bin/bash
## Build (NVENC+AMFenc)FFMPEG + OBS STUDIO Latest + on Ubuntu 18.04|19.04 64Bits

## https://gist.github.com/sparrc/026ed9958502072dda749ba4e5879ee3
## https://gist.github.com/jniltinho/9273dc133796062c13ca739d17862125
## https://www.tal.org/tutorials/ffmpeg_nvidia_encode
## https://www.ffmpeg.org/general.html#toc-AMD-AMF_002fVCE
## https://github.com/GPUOpen-LibrariesAndSDKs/AMF
## Installs ffmpeg from source (HEAD) with libaom and libx265

## https://github.com/zimbatm/ffmpeg-static
## https://www.johnvansickle.com/ffmpeg/
## https://github.com/maxrd2/SubtitleComposer/wiki/Building-from-sources

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
    apt-get -qqy install autoconf automake bash build-essential liblilv-dev libcodec2-dev
    apt-get -qqy install cmake libass-dev libfreetype6-dev libsdl2-dev libtool libva-dev libvdpau-dev
    apt-get -qqy install libx265-dev libnuma-dev texinfo zlib1g-dev libopenjp2-7-dev librtmp-dev
    apt-get -qqy install frei0r-plugins-dev gawk libfontconfig-dev libfreetype6-dev libopencore-amrwb-dev
    apt-get -qqy install libsdl2-dev libspeex-dev libtheora-dev libtool libva-dev cmake libopencore-amrnb-dev
    apt-get -qqy install libvdpau-dev libvo-amrwbenc-dev sudo tar texi2html yasm libxvidcore-dev lsb-release pkg-config
    apt-get -qqy install libvorbis-dev libwebp-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev
    mkdir -p "${build_dir}/bin"
}

# TODO Detect running system
CheckDistro() {
    echo "Check Distro ...."
    DIST=$(lsb_release -cs)
    if [[ $DIST == 'bionic' ]]; then
        apt-get update
        add-apt-repository ppa:jonathonf/ffmpeg-4 -y
        apt-get update
    fi

}

InstallFFmpegBase() {
    echo "Check Distro ...."
    DIST=$(lsb_release -cs)
    echo "Installing FFMPEG BASE ..."
    if [[ $DIST == 'disco' || $DIST == 'bionic' || $DIST == 'eoan' ]]; then
        echo "Installing dependencies"
        apt-get -qqy install build-essential curl tar libass-dev cmake
        apt-get -qqy install libtheora-dev libvorbis-dev libtool automake autoconf
        apt-get -qqy install libspeexdsp-dev pkg-config git libxml2-dev ruby-dev
        apt-get -qqy install yasm libchromaprint-dev libfdk-aac-dev libflite1

        ## Build FFMPEG
        apt-get -qqy install libbs2b-dev ladspa-sdk libbluray-dev libcaca-dev libmp3lame-dev libaom-dev
        apt-get -qqy install libgme-dev libgsm1-dev libopenmpt-dev libopus-dev librsvg2-dev librubberband-dev
        apt-get -qqy install libshine-dev libsoxr-dev libtwolame-dev libvpx-dev libwavpack-dev libx264-dev
        apt-get -qqy install libzvbi-dev libopenal-dev libomxil-bellagio-dev libjack-dev libcdio-paranoia-dev
        gem install fpm
    fi

}

InstallNvidiaSDK() {
    echo "Installing the NVidia Video CODEC"
    cd $source_dir
    git clone --depth=1 https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
    ( cd nv-codec-headers ; make -j$(nproc) ; make -j$(nproc) install )
    rm -rf nv-codec-headers
}

InstallAMFSDK() {
    ## https://www.ffmpeg.org/general.html#toc-AMD-AMF_002fVCE
    echo "Installing the AMD AMFCodec"
    cd $source_dir
    mkdir -p /usr/local/include/AMF
    git clone --depth=1 https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git
    cp -aR AMF/amf/public/include/* /usr/local/include/AMF/
    rm -rf AMF
}

BuildFFmpeg() {
    echo "Compiling ffmpeg"
    cd $source_dir
    ## ffmpeg_version="4.2.2"
    ffmpeg_version="snapshot"
    if [ ! -f ffmpeg-${ffmpeg_version}.tar.bz2 ]; then
        wget http://ffmpeg.org/releases/ffmpeg-${ffmpeg_version}.tar.bz2
    fi
    tar xjf ffmpeg-${ffmpeg_version}.tar.bz2
    ## mv ffmpeg-${ffmpeg_version} ffmpeg
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
        --enable-libflite \
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
        --enable-libsnappy \
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
    rm -rf $FOLDER_FPM/share/doc

}

BuildOBS() {
    apt-get -qqy install \
        libmbedtls-dev \
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
    make -j$(nproc) install
    make -j$(nproc) DESTDIR=$FOLDER_FPM install
    rm -rf $FOLDER_FPM/share/doc
    rm -rf $FOLDER_FPM/share/metainfo

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
    ## Get latest OBS-STUDIO VERSION
    OBS_REPO=obsproject/obs-studio
    OBS_VERSION=$(basename $(curl -Ls -o /dev/null -w %{url_effective} https://github.com/$OBS_REPO/releases/latest))
    DIST=$(lsb_release -cs)
    fpm --deb-no-default-config-files -s dir -t deb -C $FOLDER_FPM -n obs-studio-plus -v ${OBS_VERSION} \
        -p obs-studio-plus_${OBS_VERSION}+${DIST}-1_amd64.deb .
    rm -rf $FOLDER_FPM
    mkdir -p /root/dist/
    cp $source_dir/obs-studio-plus_* /root/dist/
}

if [ $1 ]; then
    $1
else
    InstallDependencies
    CheckDistro
    InstallFFmpegBase
    InstallNvidiaSDK
    InstallAMFSDK
    BuildFFmpeg
    BuildOBS
    MakeLauncherOBS
    MakeDEB
fi
