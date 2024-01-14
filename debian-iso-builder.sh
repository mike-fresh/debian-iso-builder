#!/usr/bin/env bash
# example script for building a debian live image with broadcom BCM4360 drivers
# Tested on Debian 12.04 stable build host in a QEMU/KVM environment
# reference / credits:
# https://ianlecorbeau.github.io/blog/debian-live-build.html
# https://live-team.pages.debian.net/live-manual/html/live-manual.en.html
# https://wiki.debian.org/wl

BUILD_DIR="${HOME}/LIVE_BOOT"
ISO_VOLUME_NAME="DEBLIVE"
IMAGE_NAME="test_image"
SYSTEM_ARCH="amd64"
KERNEL_PACKAGES="linux-image linux-headers"
DEBIAN_MIRROR="http://ftp.ch.debian.org/debian"
DEBIAN_CODENAME="bookworm"
DEBIAN_COMPONENTS="contrib main non-free non-free-firmware"

DEBIAN_SOURCES=$(cat << EOF
deb $DEBIAN_MIRROR $DEBIAN_CODENAME $DEBIAN_COMPONENTS
deb $DEBIAN_MIRROR-security $DEBIAN_CODENAME-security $DEBIAN_COMPONENTS
deb $DEBIAN_MIRROR $DEBIAN_CODENAME-updates $DEBIAN_COMPONENTS
EOF
)

PACKAGES_TO_INSTALL=$(cat << EOF
xfce4
broadcom-sta-dkms
nm-tray
EOF
)

# setup debian repos on build host, update and install prerequisites
sudo echo "${DEBIAN_SOURCES}" > /etc/apt/sources.list
sudo apt update && sudo apt upgrade -y
sudo apt install -y live-build

# make build folder
mkdir -p "${BUILD_DIR}" && cd "${BUILD_DIR}"

# configure the build
lb config \
    --apt-recommends true \
    --apt-secure false \
    --architecture "${SYSTEM_ARCH}" \
    --archive-areas "${DEBIAN_COMPONENTS}" \
    --backports false \
    --binary-image iso-hybrid \
    --build-with-chroot true \
    --checksums md5 \
    --color \
    --debootstrap-options "--variant=minbase" \
    --distribution "${DEBIAN_CODENAME}" \
    --image-name "${IMAGE_NAME}" \
    --interactive false \
    --iso-volume "${ISO_VOLUME_NAME}" \
    --linux-packages "${KERNEL_PACKAGES}" \
    --memtest memtest86+ \
    --mirror-binary "${DEBIAN_MIRROR}" \
    --mirror-bootstrap "${DEBIAN_MIRROR}" \
    --mirror-chroot "${DEBIAN_MIRROR}" \
    --mode debian \
    --security true \
    --source false \
    --system live \
    --uefi-secure-boot auto \
    --updates true \
    --utc-time false \

# add broadcom drivers to the build
echo "${PACKAGES_TO_INSTALL}" > "${BUILD_DIR}/config/package-lists/custom.list.chroot"

# build the image
sudo lb build
