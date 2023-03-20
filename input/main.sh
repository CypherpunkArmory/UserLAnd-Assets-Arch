#!/bin/bash

echo "127.0.0.1 localhost" > /etc/hosts
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

mkdir /usr/share/xsessions
echo "[Desktop Entry]" > /usr/share/xsessions/twm.desktop
echo "Name=twm" >> /usr/share/xsessions/twm.desktop
echo "Comment=xorg-twm" >> /usr/share/xsessions/twm.desktop
echo "TryExec=twm" >> /usr/share/xsessions/twm.desktop
echo "Exec=twm" >> /usr/share/xsessions/twm.desktop
echo "Type=Application" >> /usr/share/xsessions/twm.desktop

#update our repos so we can install some packages
pacman-key --init
pacman-key --populate
pacman-key --refresh-keys
pacman -Syy

#install some packages with need for UserLAnd
pacman -S sudo dropbear x11vnc xterm xorg-twm xorg-server-xvfb xorg-xsetroot expect gzip --noconfirm

#clean up after ourselves
yes | pacman -Scc

#tar up what we have before we grow it
tar -czvf /output/rootfs.tar.gz --exclude sys --exclude dev --exclude proc --exclude mnt --exclude etc/mtab --exclude output --exclude input --exclude .dockerenv /

#build disableselinux to go with this release
pacman -S glibc base-devel linux-api-headers --noconfirm
gcc -shared -fpic /input/disableselinux.c -o /output/libdisableselinux.so

#get busybox to go with the release
pacman -S busybox --noconfirm
cp /bin/busybox output/busybox
