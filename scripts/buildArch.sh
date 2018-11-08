#! /bin/bash

#
# Script to bootstrap and tar up Arch Linux filesystem for UserLAnd. Work in progress.
#

set -e -u -o pipefail

export LC_ALL=C
export LANG=C
export LANGUAGE=C

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

chown $SUDO_USER ./* # this may be necessary

export CHROOTCMD="proot -0 -b /run -b /sys -b /dev -b /proc -b /mnt -b /dev/urandom:/dev/random -R $ROOTFS_DIR"

# Download and untar the different filesystems. Using qemu-static utilities because we have to within the proot environment

case "$1" in 
	armhf) 
		export POPNAME=archlinuxarm
		
		if [ -e ArchLinuxARM-armv7-latest.tar.gz ]
		then
			chown $SUDO_USER ArchLinuxARM-armv7-latest.tar.gz
			tar -xzvf ArchLinuxARM-armv7-latest.tar.gz -C $ROOTFS_DIR .

			cp "/usr/bin/qemu-arm-static" "$ROOTFS_DIR/usr/bin"
			export ARCHOPTION=qemu-arm-static
		else
			wget  http://fl.us.mirror.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
			tar -xzvf ArchLinuxARM-armv7-latest.tar.gz -C $ROOTFS_DIR .
			#arch-debootstrap -a arm7h $ROOTFS_DIR # uncomment this line, and comment the two lines above this one if you
			# want to use the tar as a base instead, but using bootstrap will require root permissions

			cp "/usr/bin/qemu-arm-static" "$ROOTFS_DIR/usr/bin"
			export ARCHOPTION=qemu-arm-static
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
	
		if [ -e archlinux-bootstrap-2018.10.01-x86_64.tar.gz ]
		then
			chown $SUDO_USER archlinux-bootstrap-2018.10.01-x86_64.tar.gz
			tar -xzvf archlinux-bootstrap-2018.10.01-x86_64.tar.gz --strip 1 -C $ROOTFS_DIR  

			cp "/usr/bin/qemu-x86_64-static" "$ROOTFS_DIR/usr/bin"
			export ARCHOPTION=/usr/bin/qemu-x86_64-static
		else
			wget http://mirrors.evowise.com/archlinux/iso/2018.10.01/archlinux-bootstrap-2018.10.01-x86_64.tar.gz
			tar -xzvf archlinux-bootstrap-2018.10.01-x86_64.tar.gz --strip 1 -C $ROOTFS_DIR  
			#arch-debootstrap -a arm7h $ROOTFS_DIR # uncomment this line, and comment the two lines above this one if you
			# want to use the tar as a base instead, but using bootstrap will require root permissions
			
			cp "/usr/bin/qemu-x86_64-static" "$ROOTFS_DIR/usr/bin"
			export ARCHOPTION=/usr/bin/qemu-x86_64-static
		fi

	;;

	*)
		echo "only armhf and x86_64 are supported."
		exit
	;;

	esac

# set up the basic network requirements, defaults seem to work

cp "/etc/resolv.conf" "$ROOTFS_DIR/etc/resolv.conf"

# stuff in a new users

cp scripts/addNonRootUser.sh $ROOTFS_DIR
chown $SUDO_USER $ROOTFS_DIR/addNonRootUser.sh
chmod 777 $ROOTFS_DIR/addNonRootUser.sh

$CHROOTCMD $ARCHOPTION echo $PATH

$CHROOTCMD $ARCHOPTION /bin/bash addNonRootUser.sh
rm $ROOTFS_DIR/addNonRootUser.sh

# create the chroot/proot environment, where the magic (hopefully happens)

mkdir $ROOTFS_DIR/etc/pacman.d/gnupg
echo "line 1"
$CHROOTCMD $ARCHOPTION gpg-agent --homedir /etc/pacman.d/gnupg --use-standard-socket --daemon & 
echo "line 2"
$CHROOTCMD $ARCHOPTION gpg-agent --daemon
ps -aux | grep "gpg-agent"
sleep 5
ps -aux | grep "gpg-agent"
$CHROOTCMD $ARCHOPTION /bin/bash pacman-key --init
echo "line 3"
$CHROOTCMD $ARCHOPTION /bin/bash pacman-key --populate $POPNAME
echo "line 4"
$CHROOTCMD $ARCHOPTION pacman -Syy --noconfirm
echo "line 5"
$CHROOTCMD $ARCHOPTION pacman -Su --noconfirm
echo "line 6"
$CHROOTCMD $ARCHOPTION pacman -Sy coreutils pacman-contrib base base-devel sudo tigervnc xterm xorg-twm expect --noconfirm
echo "line 7"

tar --exclude='dev/*' -czvf $ARCH_DIR/rootfs.tar.gz -C $ROOTFS_DIR .

#build disableselinux to go with this release
cp scripts/disableselinux.c $ROOTFS_DIR
$CHROOTCMD $ARCHOPTION gcc -shared -fpic disableselinux.c -o libdisableselinux.so
cp $ROOTFS_DIR/libdisableselinux.so $ARCH_DIR/libdisableselinux.so

#get busybox to go with the release
$CHROOTCMD /usr/bin/qemu-"$ARCHOPTION"-static pacman -S busybox --noconfirm
cp $ROOTFS_DIR/bin/busybox $ARCH_DIR/busybox

killall gpg-agent

