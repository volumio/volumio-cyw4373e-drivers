#!/bin/bash

CPU=$(nproc)
LOGFILE="/tmp/cyw4373e.log"

KERNEL_VERSION="6.12.75"

# Specify the CYW4373E source directory (within source_files) to match
# the supplied KERNEL_VERSION. Please update this table whenever
# a new kernel appears
declare -rA CYW4373E_SOURCES=(
  ["6.12.75"]="6.12.y"
)

MODULES_DEST_NAME="modules-rpi-${KERNEL_VERSION}-updates"

# Target names are not related to the Linux kernel.
# They are user-defined and can be changed as will.
declare -ra TARGETS=("rpi0-32bit" "rpi2-32bit" "rpi34-32bit" "rpi345-64bit")

# Specify the architecture for each target
declare -rA KERNEL_ARCHS=(
  ["rpi0-32bit"]="arm"
  ["rpi2-32bit"]="arm"
  ["rpi34-32bit"]="arm"
  ["rpi345-64bit"]="arm64"
)

# Specify the compiler to use for each target
declare -rA CROSS_COMPILERS=(
  ["rpi0-32bit"]="arm-linux-gnueabihf-"
  ["rpi2-32bit"]="arm-linux-gnueabihf-"
  ["rpi34-32bit"]="arm-linux-gnueabihf-"
  ["rpi345-64bit"]="aarch64-linux-gnu-"
)

# Specify the kernel defconfig to use for each target
declare -rA DEFCONFIGS=(
  ["rpi0-32bit"]="bcmrpi_defconfig"
  ["rpi2-32bit"]="bcm2709_defconfig"
  ["rpi34-32bit"]="bcm2711_defconfig"
  ["rpi345-64bit"]="bcm2711_defconfig"
)

CWD=$PWD

# INSTALL_MOD_PATH is used by kernel Makefile as the place
# where to "install" the modules when modules_instal makefile
# target is invoked. This let's us "install" the modules in
# a custom path instead of the system /lib path
export INSTALL_MOD_PATH="${CWD}/${MODULES_DEST_NAME}"

echo "Writing logfile to ${LOGFILE}"

# Cleanup the log file
rm -f ${LOGFILE}

# Cleanup the temporary modules-output directory
echo "Cleanup modules temp path ${MODULES_DEST_NAME}"
rm -rf ${MODULES_DEST_NAME}

for TARGET in "${TARGETS[@]}"
do

  cd $CWD

  # These variables are exported because they are used by the kernel Makefile
  export ARCH=${KERNEL_ARCHS[$TARGET]}
  export CROSS_COMPILE=${CROSS_COMPILERS[$TARGET]}
  export LOCALVERSION="+"

  DEFCONFIG=${DEFCONFIGS[$TARGET]}

  DIR_KERNEL=${CWD}/linux-${KERNEL_VERSION}
  [[ ! -d ${DIR_KERNEL} ]] && echo "missing kernel sources from ${DIR_KERNEL}, download kernel first" && exit 1

  DIR_CYW4373E=${CWD}/source_files/${CYW4373E_SOURCES[$KERNEL_VERSION]}
  [[ ! -d ${DIR_CYW4373E} ]] && echo "missing cyw4373e source path ${DIR_CYW4373E}" && exit 1

  echo ""
  echo "Target: $TARGET (arch: $ARCH, compiler: $CROSS_COMPILE, defconfig: $DEFCONFIG)"

  echo -n "Compiling kernel... "

  cd ${DIR_KERNEL}

  make distclean >> $LOGFILE 2>&1
  make ${DEFCONFIG} >> $LOGFILE 2>&1
  make all -j${CPU} >> $LOGFILE 2>&1

  [[ $? -ne 0 ]] && echo "an error occurred" && exit 1

  echo "done"

  echo -n "Compiling CYW4373E drivers... "

  cd ${DIR_CYW4373E}

  make KLIB_BUILD=${DIR_KERNEL} clean >> $LOGFILE 2>&1
  make KLIB_BUILD=${DIR_KERNEL} defconfig-lwb >> $LOGFILE 2>&1
  make KLIB_BUILD=${DIR_KERNEL} -j${CPU} >> $LOGFILE 2>&1
  [[ $? -ne 0 ]] && echo "an error occurred" && exit 1

  make KLIB_BUILD=${DIR_KERNEL} modules_install >> $LOGFILE 2>&1
  [[ $? -ne 0 ]] && echo "an error occurred" && exit 1

  echo "done"

done

cd ${CWD}

# Remove unneeded depmod modules.* files, just keep the "updates" directories
rm -f ${INSTALL_MOD_PATH}/lib/modules/*/modules.*

PATH_MODULES_DEST="output/${MODULES_DEST_NAME}"
echo "Creating modules tarball ${PATH_MODULES_DEST}.tar.gz"
mkdir -p output
tar czf "${PATH_MODULES_DEST}.tar.gz" ${MODULES_DEST_NAME}/* --owner=0 --group=0
md5sum "${PATH_MODULES_DEST}.tar.gz" > ${PATH_MODULES_DEST}.md5sum.txt
sha1sum "${PATH_MODULES_DEST}.tar.gz" > ${PATH_MODULES_DEST}.sha1sum.txt

exit 0
