# export the env
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
echo "ARCH=$ARCH" >> "$GITHUB_OUTPUT"

# install depedencies
manifest=$(docker manifest inspect arfshl/trisquel:latest)
# Fetch image digest
digest=$(echo "$manifest" | jq -r ".manifests[] | select(.platform.architecture == \"$ARCH\") | .digest")
# Pull and Export image
docker pull "arfshl/trisquel:latest@${digest}"
docker export $(docker create "arfshl/trisquel:latest@${digest}") | xz -T 0 > "$GITHUB_WORKSPACE/trisquel.tar.xz"

mkdir -p ./trisquel
sudo tar -xJpf trisquel.tar.xz -C ./trisquel
cat <<-EOF | sudo unshare -mpf bash -e -
sudo mount --bind /dev ./trisquel/dev
sudo mount --bind /proc ./trisquel/proc
sudo mount --bind /sys ./trisquel/sys
sudo rm -f ./trisquel/etc/resolv.conf
sudo echo "nameserver 1.1.1.1" >> ./trisquel/etc/resolv.conf

sudo chroot ./trisquel apt update
#sudo chroot ./trisquel apt purge -yq --allow-remove-essential coreutils-from-uutils
#sudo chroot ./trisquel apt purge -yq --allow-remove-essential rust-coreutils
#sudo chroot ./trisquel apt install -yq coreutils-from-gnu
#sudo chroot ./trisquel apt install -yq gnu-coreutils
sudo chroot ./trisquel apt install -yq locales passwd ca-certificates sudo libpam-systemd dbus systemd mesa-utils systemd-sysv
sudo chroot ./trisquel apt clean

sudo chroot ./trisquel sed -i 's/^# \(en_US.UTF-8\)/\1/' /etc/locale.gen
sudo chroot ./trisquel /bin/bash -c 'DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales'

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


