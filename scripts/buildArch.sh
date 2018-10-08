#! /bin/bash

export ARCH_DIR=output/${1}
export ROOTFS_DIR=$ARCH_DIR/rootfs

rm -rf $ARCH_DIR
mkdir -p $ARCH_DIR
rm -rf $ROOTFS_DIR
mkdir -p $ROOTFS_DIR

# Here we untar the ARM port, need to figure out what to do with the x86 version

wget http://fl.us.mirror.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
tar -zxvf ArchLinuxARM-armv5-latest.tar.gz $ROOTFS_DIR

# The following just sets up a few files for UserLAnd's benefit, mostly nameserver and path stuff

echo "127.0.0.1 localhost" > $ROOTFS_DIR/etc/hosts
echo "nameserver 8.8.8.8" > $ROOTFS_DIR/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $ROOTFS_DIR/etc/resolv.conf

echo "#!/bin/sh" > $ROOTFS_DIR/etc/profile.d/userland.sh
echo "unset LD_PRELOAD" >> $ROOTFS_DIR/etc/profile.d/userland.sh
echo "unset LD_LIBRARY_PATH" >> $ROOTFS_DIR/etc/profile.d/userland.sh
echo "export LIBGL_ALWAYS_SOFTWARE=1" >> $ROOTFS_DIR/etc/profile.d/userland.sh
chmod +x $ROOTFS_DIR/etc/profile.d/userland.sh

pacman-key init
pacman-key --populate archlinux

# Copy the scripts and tar up everything

cp scripts/addNonRootUser.sh $ROOTFS_DIR
chmod 777 $ROOTFS_DIR/addNonRootUser.sh
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS_DIR ./addNonRootUser.sh
rm $ROOTFS_DIR/addNonRootUser.sh

cp scripts/shrinkRootfs.sh $ROOTFS_DIR
chmod 777 $ROOTFS_DIR/shrinkRootfs.sh
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS_DIR ./shrinkRootfs.sh
rm $ROOTFS_DIR/shrinkRootfs.sh

tar --exclude='dev/*' -czvf $ARCH_DIR/rootfs.tar.gz -C $ROOTFS_DIR .

#build disableselinux to go with this release
cp scripts/disableselinux.c $ROOTFS_DIR
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
 LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS_DIR gcc -shared -fpic disableselinux.c -o libdisableselinux.so
cp $ROOTFS_DIR/libdisableselinux.so $ARCH_DIR/libdisableselinux.so
