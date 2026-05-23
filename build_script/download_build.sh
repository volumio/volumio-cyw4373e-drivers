#!/bin/bash

KERNEL_VERSION="6.12.75"

case $KERNEL_VERSION in
    "6.12.75")
      KERNEL_COMMIT="98655d3ccedba33aeadd0e550229f1496c5bf6f9"
      ;;
esac

echo "--- Download kernel source for version ${KERNEL_VERSION} ---"
echo "Download kernel hash info"
wget -N https://raw.githubusercontent.com/raspberrypi/rpi-firmware/${KERNEL_COMMIT}/git_hash
GIT_HASH="$(cat git_hash)"
rm git_hash
echo "Download kernel source"
wget https://github.com/raspberrypi/linux/archive/${GIT_HASH}.tar.gz

echo "Extract kernel source"
rm -rf linux-${KERNEL_VERSION}+/
tar xvzf ${GIT_HASH}.tar.gz
rm ${GIT_HASH}.tar.gz
mv linux-${GIT_HASH}/ linux-${KERNEL_VERSION}/

./build_script/re-build.sh

exit 0
