#!/bin/sh
set -ex

export QT_SELECT=qt5

# Eat our own dogfood, use appstreamcli AppImage to verify the AppStream metadata
wget -c https://github.com/probonopd/appstream/releases/download/continuous/appstreamcli-28-x86_64.AppImage -O appstreamcli
chmod +x appstreamcli
export PATH=$(readlink -f .):$PATH

# Compile and install to an AppDir
cd ./build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
make DESTDIR=appdir -j$(nproc) install ; find appdir/
( cd appdir/usr ; ln -s lib/obs-scripting/* . ) # FIXME: https://github.com/obsproject/obs-studio/pull/1565#issuecomment-448754477
cp appdir/usr/share/icons/hicolor/256x256/apps/com.obsproject.Studio.png appdir/

# Also deploy the Python standard library
apt-get -y download libpython3.6-minimal libpython3.6-stdlib
( cd appdir ; dpkg -x ../libpython3.6-minimal*.deb . )
( cd appdir ; dpkg -x ../libpython3.6-stdlib*.deb . )

# ( cd appdir ; ln -sf ../../usr/lib/x86_64-linux-gnu/qt5/plugins/platforms/ usr/bin/platforms )


# libobs.so.0 loads resources from a path relative to cwd that only works
# when -DUNIX_STRUCTURE=0 is used at configure time, which we are not using;
# hence patching it to load resources relative to cwd = usr/
sed -i -e 's|../../obs-plugins/64bit|././././lib/obs-plugins|g' appdir/usr/lib/libobs.so.0

# Workaround for:
# com.obsproject.Studio.appdata.xml
# W: com.obsproject.Studio:21: invalid-iso8601-date 
# Validation failed: warnings: 1, pedantic: 1
# ERROR: AppStream metainfo file file contains errors. Please fix them. Please see https://www.freedesktop.org/software/appstream/docs/chap-Quickstart.html#sect-Quickstart-DesktopApps
# In case of questions regarding the validation, please refer to https://github.com/ximion/appstream
rm -rf appdir/usr/share/metainfo

OBS_REPO=obsproject/obs-studio
export VERSION=$(basename $(curl -Ls -o /dev/null -w %{url_effective} https://github.com/$OBS_REPO/releases/latest))

wget -c https://github.com/probonopd/go-appimage/releases/download/continuous/appimagetool-474-x86_64.AppImage -O appimagetool
chmod +x appimagetool
./appimagetool --appimage-extract-and-run deploy appdir/usr/share/applications/*.desktop

## Copy ffmpeg
cp /usr/bin/ffmpeg /usr/bin/ffplay /usr/bin/ffprobe appdir/usr/bin/
rm -rf appdir/usr/share/doc

sed -i 's|Name=OBS Studio|Name=obs-studio-plus|' appdir/com.obsproject.Studio.desktop
cp ../CI/install/AppDir/AppRun appdir/AppRun
chmod +x appdir/AppRun

./appimagetool --appimage-extract-and-run appdir/