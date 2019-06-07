#!/bin/bash

export ARCH_DIR=output
export ROOTFS_DIR=output/rootfs

case "$1" in
    arm) export ARCH_BOOTSTRAP_ARCH_OPT=armv7h
        export ARCH_BOOTSTRAP_QEMU_OPT=-q
        ;;
    arm64) export ARCH_BOOTSTRAP_ARCH_OPT=aarch64
        export ARCH_BOOTSTRAP_QEMU_OPT=-q
        ;;
    x86) export ARCH_BOOTSTRAP_ARCH_OPT=x86_64
        ;;
    x86_64) export ARCH_BOOTSTRAP_ARCH_OPT=x86_64
        ;;
    *) echo "unsupported arch: $1"
        exit
        ;;
esac

rm -rf $ARCH_DIR
mkdir -p $ARCH_DIR
rm -rf $ROOTFS_DIR
mkdir -p $ROOTFS_DIR

apt-get update
apt-get install -y git curl xz-utils binfmt-support qemu qemu-user-static 

mkdir -p $ROOTFS_DIR/proc
mkdir -p $ROOTFS_DIR/sys
mkdir -p $ROOTFS_DIR/dev
mount -t proc /proc $ROOTFS_DIR/proc/
mount --rbind /sys $ROOTFS_DIR/sys/
mount --rbind /dev $ROOTFS_DIR/dev/

git clone https://github.com/tokland/arch-bootstrap.git $ARCH_DIR/arch-bootstrap
$ARCH_DIR/arch-bootstrap/arch-bootstrap.sh $ARCH_BOOTSTRAP_QEMU_OPT -a $ARCH_BOOTSTRAP_ARCH_OPT $ROOTFS_DIR

tar --exclude='dev/*' --exclude='proc/*' --exclude='sys/*' -cvf $ARCH_DIR/rootfs.tar -C $ROOTFS_DIR .
