#!/bin/bash
set -xe

IMAGE=disk.img
GRUB_MBR_DIR=${HOME}/grub_mbr
GRUB_EFI_DIR=${HOME}/grub_efi
LOOPDEVICE=/dev/loop0
MAPPEDDEVICE_MBR=/dev/mapper/loop0p1
MAPPEDDEVICE_EFI_PT=/dev/mapper/loop0p2
MAPPEDDEVICE_DATA_PT=/dev/mapper/loop0p3
MOUNT_DATA_DIR="/mnt/data"
MOUNT_EFI_DIR="/mnt/efi"

cd ${HOME}

sudo sed -i'~' -E "s@http://(..\.)?archive\.ubuntu\.com/ubuntu@http://pf.is.s.u-tokyo.ac.jp/~awamoto/apt-mirror/@g" /etc/apt/sources.list
sudo DEBIAN_FRONTEND=noninteractive apt -qq update

# build EDK2
sudo DEBIAN_FRONTEND=noninteractive apt -qq install -y build-essential uuid-dev nasm iasl
git clone -b UDK2017 http://github.com/tianocore/edk2 --depth=1
cd edk2
make -C BaseTools
. ./edksetup.sh
build -a X64 -t GCC48 -p OvmfPkg/OvmfPkgX64.dsc
mkdir ~/edk2-UDK2017
cp Build/OvmfX64/DEBUG_GCC48/FV/*.fd ~/edk2-UDK2017
cd ..

# build GRUB2
sudo DEBIAN_FRONTEND=noninteractive apt -qq install -y bison flex libdevmapper-dev
wget ftp://ftp.gnu.org/gnu/grub/grub-2.02.tar.gz
tar xf grub-2.02.tar.gz
mv grub-2.02 grub-src
cd grub-src
./configure --prefix=${GRUB_MBR_DIR} --enable-device-mapper --with-platform=pc
make install
make clean
./configure --prefix=${GRUB_EFI_DIR} --enable-device-mapper --with-platform=efi
make install
cd ..

# make disk
sudo DEBIAN_FRONTEND=noninteractive apt -qq install -y gdisk kpartx
dd if=/dev/zero of=${IMAGE} bs=1M count=200
sgdisk -a 1 -n 1::2047 -t 1:EF02 -a 2048 -n 2::100M -t 2:EF00 -n 3:: -t 3:8300 ${IMAGE}
sudo mkdir -p ${MOUNT_EFI_DIR} ${MOUNT_DATA_DIR}
sudo kpartx -avs ${IMAGE}
sleep 1
sudo mkfs.vfat -F32 ${MAPPEDDEVICE_EFI_PT};
sudo mount -t vfat ${MAPPEDDEVICE_EFI_PT} ${MOUNT_EFI_DIR};
sudo mkfs.ext2 ${MAPPEDDEVICE_DATA_PT};
sudo mount -t ext2 ${MAPPEDDEVICE_DATA_PT} ${MOUNT_DATA_DIR};
sudo ${GRUB_MBR_DIR}/sbin/grub-install --target=i386-pc --no-floppy ${LOOPDEVICE} --root-directory ${MOUNT_DATA_DIR}
sudo ${GRUB_EFI_DIR}/sbin/grub-install --target=x86_64-efi --no-nvram --efi-directory=${MOUNT_EFI_DIR} --boot-directory=${MOUNT_DATA_DIR}/boot
sudo mv ${MOUNT_EFI_DIR}/EFI/grub ${MOUNT_EFI_DIR}/EFI/boot
sudo mv ${MOUNT_EFI_DIR}/EFI/boot/grubx64.efi ${MOUNT_EFI_DIR}/EFI/boot/bootx64.efi
sudo umount ${MOUNT_DATA_DIR}
sudo umount ${MOUNT_EFI_DIR}
sudo kpartx -d ${IMAGE}
sudo losetup -d /dev/loop[0-9] || :
cp ${IMAGE} /vagrant/
