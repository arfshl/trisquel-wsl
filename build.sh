# export the env
export RELEASE=ecne
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
    --include=trisquel-keyring,locales,passwd,software-properties-common,ca-certificates,sudo,libpam-systemd,dbus,systemd,mesa-utils,systemd-sysv \
    --format=directory \
    ${dist_version} \
    trisquel \
    "deb http://archive.trisquel.org/trisquel ${dist_version} main" \
    "deb http://archive.trisquel.org/trisquel ${dist_version}-updates main" \
    "deb http://archive.trisquel.org/trisquel ${dist_version}-security main" \
    "deb http://archive.trisquel.org/trisquel ${dist_version}-backports main"

cat <<-EOF | sudo unshare -mpf bash -e -
sudo mount --bind /dev ./trisquel/dev
sudo mount --bind /proc ./trisquel/proc
sudo mount --bind /sys ./trisquel/sys
sudo echo 'nameserver 1.1.1.1' >> ./trisquel/etc/resolv.conf

sudo chroot ./trisquel apt update
sudo chroot ./trisquel apt purge -yq --allow-remove-essential coreutils-from-uutils
sudo chroot ./trisquel apt purge -yq --allow-remove-essential rust-coreutils
sudo chroot ./trisquel apt install -yq coreutils-from-gnu
sudo chroot ./trisquel apt install -yq gnu-coreutils
sudo chroot ./trisquel apt clean

sudo rm -rf ./trisquel/var/lib/apt/lists/*
sudo rm -rf ./trisquel/var/tmp*
sudo rm -rf ./trisquel/tmp*
EOF

sudo cp ./wslconf/oobe.sh ./trisquel/etc/oobe.sh
sudo chmod 644 ./trisquel/etc/oobe.sh
sudo chmod +x ./trisquel/etc/oobe.sh
sudo cp ./wslconf/oobe.sh ./trisquel/etc/wsl.conf
sudo chmod 644 ./trisquel/etc/wsl.conf
sudo cp ./wslconf/wsl-distribution.conf ./trisquel/etc/wsl-distribution.conf
sudo chmod 644 ./trisquel/etc/wsl-distribution.conf
sudo mkdir -p ./trisquel/usr/lib/wsl/
# sudo cp ./wslconf/icon.ico ./trisquel/usr/lib/wsl/icon.ico

cd ./trisquel
sudo tar --numeric-owner --absolute-names -c  * | gzip --best > ../install.tar.gz
mv ../install.tar.gz ../trisquel-$ARCH.wsl


