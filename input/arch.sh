#!/bin/bash

echo "127.0.0.1 localhost" > /etc/hosts
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

#tar up what we have before we grow it
tar -czvf /output/rootfs.tar.gz --exclude sys --exclude dev --exclude proc --exclude mnt --exclude etc/mtab --exclude output --exclude input --exclude .dockerenv /

#build disableselinux to go with this release
pacman -S base-devel --noconfirm
gcc -shared -fpic /input/disableselinux.c -o /output/libdisableselinux.so

#get busybox to go with the release
pacman -S busybox --noconfirm
cp /bin/busybox output/busybox
