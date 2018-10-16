#Temp code to make sure we only work on armhf for now
if [ "$1" != "armhf" ]; then
        echo "only armhf is supported right now"
        exit
fi

export POPNAME=archlinxarm
export ARCH_DIR=output/${1}
export ROOTFS_DIR=$ARCH_DIR/rootfs

#Current workaround for mounting issues with chroot
export CHROOTCMD="proot -0 -b /run -b /sys -b /dev -b /proc -b /mnt --rootfs=$ROOTFS_DIR"

rm -rf $ARCH_DIR
mkdir -p $ARCH_DIR
rm -rf $ROOTFS_DIR
mkdir -p $ROOTFS_DIR

# wget http://fl.us.mirror.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
tar -zxvf ArchLinuxARM-armv7-latest.tar.gz $ROOTFS_DIR

# first setup the chroot environment
cp /usr/bin/qemu-arm-static $ROOTFS_DIR/usr/bin
chroot ./$ROOTFS_DIR /bin/bash
# let's see if the above works..

echo "127.0.0.1 localhost" > $ROOTFS_DIR/etc/hosts
rm $ROOTFS_DIR/etc/resolv.conf
echo "nameserver 8.8.8.8" > $ROOTFS_DIR/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $ROOTFS_DIR/etc/resolv.conf

echo "#!/bin/sh" > $ROOTFS_DIR/etc/profile.d/userland.sh
echo "unset LD_PRELOAD" >> $ROOTFS_DIR/etc/profile.d/userland.sh
echo "unset LD_LIBRARY_PATH" >> $ROOTFS_DIR/etc/profile.d/userland.sh
echo "export LIBGL_ALWAYS_SOFTWARE=1" >> $ROOTFS_DIR/etc/profile.d/userland.sh
chmod +x $ROOTFS_DIR/etc/profile.d/userland.sh

cp scripts/addNonRootUser.sh $ROOTFS_DIR
chmod 777 $ROOTFS_DIR/addNonRootUser.sh
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD ./addNonRootUser.sh
rm $ROOTFS_DIR/addNonRootUser.sh

LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman-key --init
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman-key --populate $POPNAME
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman-key -Syy --noconfirm
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman-key -Su --noconfirm
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman -S pacman-contrib base base-devel sudo tigervnc xterm xorg-twm expect --noconfirm

tar --exclude='dev/*' -czvf $ARCH_DIR/rootfs.tar.gz -C $ROOTFS_DIR

#build disableselinux to go with this release
cp scripts/disableselinux.c $ROOTFS_DIR
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD gcc -shared -fpic disableselinux.c -o libdisableselinux.so 
cp $ROOTFS_DIR/libdisableselinux.so $ARCH_DIR/libdisableselinux.so

#get busybox to go with the release
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman -S busybox --noconfirm
cp $ROOTFS_DIR/bin/busybox $ARCH_DIR/busybox
