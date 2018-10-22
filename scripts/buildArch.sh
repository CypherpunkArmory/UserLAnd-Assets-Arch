#! /bin/bash

export ARCH_DIR=output/${1}
export ROOTFS_DIR=$ARCH_DIR/rootfs

# current workaround for mounting issues with chroot
export CHROOTCMD="proot -0 -b /run -b /sys -b /dev -b /proc -b /mnt -b /dev/urandom:/dev/random --rootfs=$ROOTFS_DIR"
# note: leaving the redirect to urandom in temporarily in case entropy is needed elsewhere. will remove later

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
		fi

	;;

	arm64)
	       echo "only armhf and x86_64 are supported right now"
       	       exit
	
	;;

	x86)
	       	echo "only armhf and x86_64 are supported right now"
		exit
	;;

	x86_64)
		export POPNAME=archlinux

		if [ -e archlinux-bootstrap-2018.10.01-x86_64.tar.gz ]
		then
			tar -zxvf archlinux-bootstrap-2018.10.01-x86_64.tar.gz -C $ROOTFS_DIR --strip 1
		else
			wget http://mirror.rackspace.com/archlinux/iso/2018.10.01/archlinux-bootstrap-2018.10.01-x86_64.tar.gz
			tar -zxvf archlinux-bootstrap-2018.10.01-x86_64.tar.gz -C $ROOTFS_DIR --strip 1
		fi
	;;

	all) 
		exit
	     	;;

	*)
		echo "unsupported architecture, exiting script"
		exit
	;;

	esac

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

LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD gpg-agent --homedir /etc/pacman.d/gnupg --use-standard-socket --daemon &
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman-key --init
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman-key --populate $POPNAME
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman -Syy --noconfirm
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman -Su --noconfirm
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman -S pacman-contrib base base-devel sudo tigervnc xterm xorg-twm expect --noconfirm

#tar --exclude='dev/*' -czvf $ARCH_DIR/rootfs.tar.gz -C $ROOTFS_DIR .

#build disableselinux to go with this release
cp scripts/disableselinux.c $ROOTFS_DIR
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD gcc -shared -fpic disableselinux.c -o libdisableselinux.so
cp $ROOTFS_DIR/libdisableselinux.so $ARCH_DIR/libdisableselinux.so

#get busybox to go with the release
LC_ALL=C LANGUAGE=C LANG=C $CHROOTCMD pacman -S busybox --noconfirm
cp $ROOTFS_DIR/bin/busybox $ARCH_DIR/busybox

killall gpg-agent
			
