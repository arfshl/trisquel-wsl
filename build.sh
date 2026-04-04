# export the env
export RELEASE=aramo
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH=amd64 ;;
    amd64) ARCH=amd64 ;;
    aarch64) ARCH=arm64 ;;
    arm64) ARCH=arm64 ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac
echo "RELEASE=$RELEASE" >> "$GITHUB_ENV"
echo "ARCH=$ARCH" >> "$GITHUB_ENV"

# install depedencies
sudo apt update && sudo apt install -yq curl libarchive-tools
curl -L -o /tmp/mmdebstrap.deb http://ftp.us.debian.org/debian/pool/main/m/mmdebstrap/mmdebstrap_1.5.7-3_all.deb
sudo apt install -yq /tmp/mmdebstrap.deb
curl -L -o /tmp/keyring.deb http://ftp.us.debian.org/debian/pool/main/d/debian-archive-keyring/debian-archive-keyring_2025.1_all.deb
sudo apt install -yq /tmp/keyring.deb
curl -L -o /tmp/trisquelkey.deb https://archive.trisquel.org/trisquel/pool/main/t/trisquel-keyring/trisquel-keyring_2023.02.07_all.deb
sudo apt install -yq /tmp/trisquelkey.deb

# start build with mmdebstrap
dist_version="$RELEASE"
sudo mmdebstrap \
    --arch=$ARCH \
    --variant=apt \
    --components="main" \
    --include=ca-certificates,locales,trisquel-keyring,software-properties-common,passwd \
    --format=tar \
    ${dist_version} \
    rootfs.tar.gz \
    "deb http://archive.trisquel.org/trisquel ${dist_version} main" \
    "deb http://archive.trisquel.org/trisquel ${dist_version}-updates main" \
    "deb http://archive.trisquel.org/trisquel ${dist_version}-security main" \
    "deb http://archive.trisquel.org/trisquel ${dist_version}-backports main"

# combine wsldl and rootfs (with matching arch as machine)
if [ $ARCH = amd64 ]; then 
    curl -L https://github.com/yuk7/wsldl/releases/download/26032000/icons.zip -o icons.zip
    bsdtar -xf icons.zip
    mv Ubuntu.exe trisquel.exe
    bsdtar -a -cf trisquel.zip rootfs.tar.gz trisquel.exe
else
    curl -L https://github.com/yuk7/wsldl/releases/download/26032000/icons_arm64.zip -o icons.zip
    bsdtar -xf icons.zip
    mv Ubuntu.exe trisquel.exe
    bsdtar -a -cf trisquel.zip rootfs.tar.gz trisquel.exe
fi