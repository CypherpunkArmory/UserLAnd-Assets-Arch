#! /bin/bash

#
# Script to bootstrap and tar up Arch Linux filesystem for UserLAnd. Work in progress.
#

set -e -u -o pipefail

# current workaround for mounting issues with chroot
# export CHROOTCMD="proot -0 -b /run -b /sys -b /dev -b /proc -b /mnt -b /dev/urandom:/dev/random --rootfs=$ROOTFS_DIR"
# note: leaving the redirect to urandom in temporarily in case entropy is needed elsewhere. will remove later
# export CHROOTCMD="chroot $ROOTFS_DIR"

export ARCH_DIR=output/${1}
export ROOTFS_DIR=$ARCH_DIR/rootfs

rm -rf $ARCH_DIR
mkdir -p $ARCH_DIR
rm -rf $ROOTFS_DIR
mkdir -p $ROOTFS_DIR

export CHROOTCMD="proot -0 -b /run -b /sys -b /dev -b /proc -b /mnt -b /dev/urandom:/dev/random --rootfs=$ROOTFS_DIR"

# Download and untar the different filesystems. Using qemu-static utilities because we have to within the proot environment

case "$1" in 
	armhf) 
		export POPNAME=archlinuxarm
		
		if [ -e ArchLinuxARM-armv7-latest.tar.gz ]
		then
			tar -xzvf ArchLinuxARM-armv7-latest.tar.gz -C $ROOTFS_DIR .
		else
			wget  http://fl.us.mirror.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
			tar -xzvf ArchLinuxARM-armv7-latest.tar.gz -C $ROOTFS_DIR .
			#arch-debootstrap -a arm7h $ROOTFS_DIR # uncomment this line, and comment the two lines above this one if you
			# want to use the tar as a base instead, but using bootstrap will require root permissions

			cp "/usr/bin/qemu-arm-static" "$ROOTFS_DIR/usr/bin"
			export $ARCHOPTION="/usr/bin/qemu-arm-static"
		fi

	;;

	arm64)
		echo "only armhf and x86_64 are supported."
		exit
	;;

	x86)
		echo "only armhf and x86_64 are supported."
		exit
	;;

	x86_64)
		export POPNAME=archlinux
	
		if [ -e ArchLinuxARM-armv7-latest.tar.gz ]
		then
			tar -xzvf ArchLinuxARM-armv7-latest.tar.gz -C $ROOTFS_DIR .
		else
			wget  http://fl.us.mirror.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
			tar -xzvf ArchLinuxARM-armv7-latest.tar.gz -C $ROOTFS_DIR .
			#arch-debootstrap -a arm7h $ROOTFS_DIR # uncomment this line, and comment the two lines above this one if you
			# want to use the tar as a base instead, but using bootstrap will require root permissions
			
			cp "/usr/bin/qemu-x86_64-static" "$ROOTFS_DIR/usr/bin"
			export $ARCHOPTION="/usr/bin/qemu-x86_64-static"
		fi

	;;

	esac

# set up the basic network requirements, defaults seem to work

cp "/etc/resolv.conf" "$ROOTFS_DIR/etc/resolv.conf"

# stuff in a new users

cp scripts/addNonRootUser.sh $ROOTFS_DIR
chmod 777 $ROOTFS_DIR/addNonRootUser.sh
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD ./addNonRootUser.sh
rm $ROOTFS_DIR/addNonRootUser.sh

# create the chroot/proot environment, where the magic (hopefully happens)

LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD $ARCHOPTION gpg-agent --homedir /etc/pacman.d/gnupg --use-standard-socket --daemon &
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD $ARCHOPTION pacman-key --init
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD $ARCHOPTION pacman-key --populate $POPNAME
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD $ARCHOPTION pacman -Syy --noconfirm
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD $ARCHOPTION pacman -Su --noconfirm
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD $ARCHOPTION pacman -Sy coreutils pacman-contrib base base-devel sudo tigervnc xterm xorg-twm expect --noconfirm

tar --exclude='dev/*' -czvf $ARCH_DIR/rootfs.tar.gz -C $ROOTFS_DIR .

#build disableselinux to go with this release
cp scripts/disableselinux.c $ROOTFS_DIR
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD gcc -shared -fpic disableselinux.c -o libdisableselinux.so
cp $ROOTFS_DIR/libdisableselinux.so $ARCH_DIR/libdisableselinux.so

#get busybox to go with the release
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman -S busybox --noconfirm
cp $ROOTFS_DIR/bin/busybox $ARCH_DIR/busybox

killall gpg-agent

