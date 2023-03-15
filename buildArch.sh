#!/bin/bash

case "$1" in
    arm) export IMAGE_ARCH=arm32v7
        wget http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz 
        gunzip -d ArchLinuxARM-armv7-latest.tar.gz
        docker import ArchLinuxARM-armv7-latest.tar $IMAGE_ARCH/archlinux:latest
        ;;
    arm64) export IMAGE_ARCH=arm64v8
        wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
        gunzip -d ArchLinuxARM-aarch64-latest.tar.gz
        docker import ArchLinuxARM-aarch64-latest.tar $IMAGE_ARCH/archlinux:latest
        ;;
    x86) export IMAGE_ARCH=i386
        wget http://mirror.math.princeton.edu/pub/archlinux32/archisos/archlinux32-2022.12.01-i486.iso
        mkdir image
        sudo mount -o loop archlinux32-2022.12.01-i486.iso image
        cd image
        sudo tar -cvf ../image.tar .
        cd ..
        docker import image.tar $IMAGE_ARCH/archlinux:latest
        ;;
    x86_64) export IMAGE_ARCH=amd64
        ;;
    *) echo "unsupported arch"
        exit
        ;;
esac

sudo docker-compose -f main.yml -f $1.yml down
sudo docker-compose -f main.yml -f $1.yml build
sudo docker-compose -f main.yml -f $1.yml up --force-recreate
mkdir -p release
cp output/rootfs.tar.gz release/$1-rootfs.tar.gz
mkdir -p release/assets
cp assets/all/* release/assets/
rm release/assets/assets.txt
cp output/busybox release/assets/
cp output/libdisableselinux.so release/assets/
tar -czvf release/$1-assets.tar.gz -C release/assets/ .
for f in $(ls release/assets/); do echo "$f $(date +%s -r release/assets/$f) $(md5sum release/assets/$f | awk '{ print $1 }')" >> release/$1-assets.txt; done
rm -rf release/assets
