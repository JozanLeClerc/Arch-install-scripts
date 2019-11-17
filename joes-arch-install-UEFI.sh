#!/bin/bash

answr=""
drvnm=""
rts=""
swps=""
rtpwd=""
rtrtpwd="walk"
usrpwd=""
usrusrpwd="fade"
hstnm=""
isusr="false"
somemore="false"
intelamdcpu="none"
intelamdgpu="none"

clear
echo "\
#============ WELCOME ============#
#                                 #
#        Welcome to Joe's         #
#           ARCH LINUX            #
#      UEFI INSTALL SCRIPT        #
#                                 #
#  (press [return] to begin...)   #
#                                 #
#=================================#"
read -r

# ================================================================================================ #
# ======================================== ERRORS CHECK ========================================== #
# ================================================================================================ #

if [ ! -r /sys/firmware/efi/efivars ]; then
	clear
	echo "\
X=X=X=X=X=X=X ERROR X=X=X=X=X=X=X=X
X                                 X
X    It seems that boot mode      X
X      is not set to UEFI         X
X    therefore Joe's script is    X
X        forced to abort          X
X                                 X
X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X"
	sleep 6
	echo && echo
	echo "Thank you for using Joe's Arch Linux UEFI install script."
	sleep 1
	echo "Aborting..."
	sleep 3
	clear
	exit
fi
clear
echo "Verifying that your are connected to the Internet, please wait..."

wget -q --spider https://archlinux.org > /dev/null
tmpret=$?
if [ $tmpret -ne 0 ]; then
	clear
	echo "\
X=X=X=X=X=X=X ERROR X=X=X=X=X=X=X=X
X                                 X
X       It seems that your        X
X         terminal is not         X
X    connected to the Internet    X
X    therefore Joe's script is    X
X        forced to abort          X
X                                 X
X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X"
	sleep 6
	echo && echo
	echo "Thank you for using Joe's Arch Linux UEFI install script."
	sleep 1
	echo "Aborting..."
	sleep 3
	clear
	exit
else
	echo "Success!"
	echo
	echo "Press [retrun] key to continue"
	read -r
fi

# ================================================================================================ #
# ========================================= DISK SETUP =========================================== #
# ================================================================================================ #

while [[ $answr != y && $answr != Y && $answr != yes && $answr != Yes && $answr != YES ]]; do
	drvnm=""
	swps=""
	rts=""
	clear
	echo "\
#========= I. DISK SETUP =========#
#                                 #
#      Please choose wisely       #
#                                 #
#      1. Drive to be used        #
#                                 #
#=================================#"
	while [[ $drvnm == "" || $drvnm -gt $(lsblk | grep -c disk) || $drvnm -le 0 ]]; do
		echo && echo
		dn=$(lsblk | grep -c disk)
		id=1
		lsblk | grep disk | awk '{print "DISK", "", "", "SIZE"}{print "----", "", "", "----"}{print $1 " ->", $4}'
		echo && echo
		echo "Please choose the drive on which Arch Linux shoud be installed:"
		while [[ $dn != 0 ]]; do
			echo "$id. $(lsblk | grep disk | awk '{print $1}' | sed -n "$id"p)"
			((dn--))
			((id++))
		done
		echo -n "> "
		read -r drvnm
		if [[ $drvnm == "" ]]; then
			echo && echo
			echo "Can't be empty, retrying..."
		fi
		if [[ $drvnm -gt $(lsblk | grep -c disk) ]]; then
			echo && echo
			echo "Illegal value, please choose something reasonable. Retrying..."
		fi
		if [[ $drvnm -lt 0 ]]; then
			echo && echo
			echo "Illegal value, please choose something reasonable. Retrying..."
		fi
		if [[ $drvnm == 0 ]]; then
			echo && echo
			echo "Illegal value, please choose something reasonable. Retrying..."
		fi
	done
	drv="/dev/"$(lsblk | grep disk | awk '{print $1}' | sed -n "$drvnm"p)
	clear
	echo "\
#========= I. DISK SETUP =========#
#                                 #
#      Please choose wisely       #
#                                 #
#      2. swap partion size       #
#                                 #
#=================================#"
	while [[ $swps == "" ]]; do
		echo && echo
		echo "\
Please enter your swap partition disired size:
_G"
		echo -n "> "
		read -r swps
		if [[ $swps == "" ]]; then
			echo && echo
			echo "Can't be empty, retrying..."
		fi
	done
	clear
	echo "\
#========= I. DISK SETUP =========#
#                                 #
#      Please choose wisely       #
#                                 #
#      3. root partion size       #
#                                 #
#=================================#"
	while [[ $rts == "" ]]; do
		echo && echo
		echo "\
Please enter your root partition disired size:
__G"
		echo -n "> "
		read -r rts
		if [[ $rts == "" ]]; then
			echo && echo
			echo "Can't be empty, retrying..."
		fi
	done
	btsze="128M"
	rtsze=$rts"G"
	swpsze=$swps"G"
	clear
	echo "\
#============= CONFIRM THIS IS CORRECT ===============#
#                                                     #
#                DRIVE TO USE: $drv               #
#                                                     #
#  /boot/efi > BOOT partition size: $btsze              #
#              SWAP partition size: $swpsze                #
#  /         > ROOT partition size: $rtsze               #
#  /home     > HOME partition size: all that remains  #
#                                                     #
#=====================================================#"
	echo && echo
	echo "Is that correct? [y/N]"
	echo -n "> "
	read -r answr
	if [[ $answr != y && $answr != Y && $answr != yes && $answr != Yes && $answr != YES ]]; then
		echo && echo
		echo "Retrying..."
		echo
		echo "Press [retrun] key to continue"
		read -r
	fi
done

# ================================================================================================ #
# ========================================= USERS SETUP ========================================== #
# ================================================================================================ #

answr="n"

while [ ! $rtrtpwd = "$rtpwd" ] || [ $rtpwd = "" ]; do
	clear
	echo "\
#======= II. USERS SETUP =========#
#                                 #
#        1. root password         #
#                                 #
#=================================#"
	echo && echo
	echo "Enter your disired root password (can't be empty):"
	echo -n "> "
	read -r -s rtpwd
	echo && echo
	echo "Confirm root password:"
	echo -n "> "
	read -r -s rtrtpwd
	if [ ! "$rtrtpwd" = "$rtpwd" ]; then
		echo && echo
		echo "Password mismatch, retrying..."
		sleep 2
	fi
	if [ "$rtpwd" = "" ]; then
		echo && echo
		echo "Password is empty, retrying..."
		sleep 2
	fi
done

clear
echo "\
#======= II. USERS SETUP =========#
#                                 #
#          2. User add            #
#                                 #
#=================================#"
echo && echo
echo "Would you like to add a user to the system? [y/N]"
echo -n "> " 
read -r answr
if [[ $answr == y || $answr == Y || $answr == yes || $answr == Yes || $answr == YES ]]; then
	echo && echo
	echo "Enter your desired username:"
	echo -n "> "
	read -r usr
	isusr="true"
	usr=$(echo "$usr" | tr '[:upper:]' '[:lower:]')
	echo && echo
	while [[ $usrusrpwd != "$usrpwd" || $usrpwd == "" ]]; do
		echo "Enter your disired password for $usr (can't be empty):"
		echo -n "> "
		read -r -s usrpwd
		echo && echo
		echo "Confirm user password:"
		echo -n "> "
		read -r -s usrusrpwd
		if [ ! "$usrusrpwd" = "$usrpwd" ]; then
			echo && echo
			echo "Password mismatch, retrying..."
			sleep 2
		fi
		if [ "$usrpwd" == "" ]; then
			echo && echo
			echo "Password is empty, retrying..."
			sleep 2
		fi
	done
fi
clear
echo "\
#======= II. USERS SETUP =========#
#                                 #
#          3. hostname            #
#                                 #
#=================================#"
while [[ $hstnm == "" ]]; do
	echo && echo
	echo "Enter your disired hostname for this terminal (can't be empty):"
	echo -n "> "
	read -r hstnm
	if [[ $hstnm == "" ]]; then
		echo && echo
		echo "Hostname is empty, retrying..."
		sleep 2
	fi
done
answr="n"
clear
echo "\
#====== III. EXTRAS SETUP ========#
#                                 #
#            1. More              #
#                                 #
#=================================#"
echo && echo
echo "Do you wish to install Xorg and gst-plugins as well? [y/N]"
echo -n "> "
read -r answr
if [[ $answr == y || $answr == Y || $answr == yes || $answr == Yes || $answr == YES ]]; then
	somemore="true"
fi
clear
answr=""
lscpu | grep -q Intel
tmpret=$?
if [ $tmpret -eq 0 ]; then
	intelamdcpu="intel"
fi
lscpu | grep -q AMD
tmpret=$?
if [ $tmpret -eq 0 ]; then
	intelamdcpu="amd"
fi
lspci | grep -q Intel
tmpret=$?
if [ $tmpret -eq 0 ]; then
	intelamdgpu="intel"
fi
lspci | grep -q AMD
tmpret=$?
if [ $tmpret -eq 0 ]; then
	intelamdgpu="amd"
fi

# ================================================================================================ #
# ===================================== THE ACTUAL INSTALL ======================================= #
# ================================================================================================ #


# ============================================================== #
# ========================== NTP DATE ========================== #
# ============================================================== #


clear
echo "\
#====== IV. INSTALLING LINUX =====#
#                                 #
#        1. Setting date          #
#             via ntp             #
#                                 #
#=================================#"
timedatectl set-ntp true
sleep 2

# ============================================================== #
# ==================== PARTITIONING DISK ======================= #
# ============================================================== #

clear
echo "\
#====== IV. INSTALLING LINUX =====#
#                                 #
#        2. Partitionning         #
#          disk $drv          #
#                                 #
#=================================#"
echo && echo
dd if=/dev/zero of="$drv" bs=512 count=1
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << FDISK_INPUT | fdisk "$drv"
o	# create a new DOS partition table
n	# new partition (/dev/sdx1)
p	# primary
1	# partition number 1
	# first sector (2048)
+$btsze	# boot size partition
Y	# YES
n	# new partition (/dev/sdx2)
p	# primary
2	# partition number 2
	# default start block
+$swpsze	# swap size partition
Y	# YES
n	# new partition (/dev/sdx3)
p	# primary
3	# partition number 3
	# default start block
+$rtsze	# root size partition
Y	# YES
n	# new partition (/dev/sdx4)
p	# primary
4	# partition number 4
	# default start block
	#	all that remains
t	# change partition type
1	# part 1
ef	# EFI partition type
t	# change partition type
2	# partition number 2
82	# swap partition type
w	# write the partition table and quit
FDISK_INPUT
mkswap "$drv""2"
mkfs.fat -F32 "$drv""1"
mkfs.ext4 "$drv""3"
mkfs.ext4 "$drv""4"
sleep 2
clear
echo "\
#====== IV. INSTALLING LINUX =====#
#                                 #
#     3. Mounting partitions      #
#                                 #
#=================================#"
swapon "$drv""2"
mkdir /mnt/arch
mount "$drv""3" /mnt/arch
mkdir /mnt/arch/boot
mkdir /mnt/arch/boot/efi
mount "$drv""1" /mnt/arch/boot/efi
mkdir /mnt/arch/home
mount "$drv""4" /mnt/arch/home
sleep 2
clear
echo "\
#====== IV. INSTALLING LINUX =====#
#                                 #
#    4. Installing base system    #
#                                 #
#=================================#"
pacstrap /mnt/arch base base-devel pacman-contrib
sleep 1
clear
echo "\
#====== IV. INSTALLING LINUX =====#
#                                 #
#   4.5 Installing some extras    #
#                                 #
#=================================#"
pacstrap /mnt/arch zip unzip p7zip vim mc alsa-utils syslog-ng mtools dostools lsb-release ntfs-3g exfat-utils git zsh
pacstrap /mnt/arch ntp cronie
pacstrap /mnt/arch grub os-prober efibootmgr
sleep 1
clear
echo "\
#====== IV. INSTALLING LINUX =====#
#                                 #
#       5. Generating fstab       #
#                                 #
#=================================#"
genfstab -U /mnt/arch > /mnt/arch/etc/fstab
sleep 2
clear
echo "\
#====== V. CONFIGURING LINUX =====#
#                                 #
#      1. Now changing root       #
#                                 #
#=================================#"
sleep 2
arch-chroot /mnt/arch << ARCH_CHROOT
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#      2. Setting time zone       #
	#        to Paris, France,        #
	#    for this is my time zone.    #
	#  Change this later accordingly  #
	#      to your own time zone      #
	#    (Joe didn't find a quick     #
	#     and easy way to ask you     #
	#      about your time zone,      #
	# Joe hopes your can  understand) #
	#                                 #
	#=================================#
	ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
	sleep 8
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#    3. Setting hardware clock    #
	#          and ntp again          #
	#                                 #
	#=================================#
	hwclock --systohc
	ntpdate fr.pool.ntp.org
	systemctl enable ntpd
	sleep 1
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#        4. Localization          #
	#          (en_US.UTF-8)          #
	#                                 #
	#=================================#
	sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#       5. Setting hostname       #
	#                                 #
	#=================================#
	echo "$hstnm" > /etc/hostname
	echo "127.0.0.1 localhost" > /etc/hosts
	echo "::1 localhost" >> /etc/hosts
	echo "127.0.1.1 $hstnm.localdomain $hstnm" >> /etc/hosts
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#     6. Setting root password    #
	#                                 #
	#=================================#
	passwd
"$rtpwd"
"$rtpwd"
	sleep 2
	clear
	#===== IV. CONFIGURING LINUX =====#
	#                                 #
	#     7. Setting up network       #
	#                                 #
	#=================================#
	pacman -S networkmanager
	Y
ARCH_CHROOT
arch-chroot /mnt/arch << ARCH_CHROOT
	sleep 2
	systemctl enable NetworkManager
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#        8. journald stuff        #
	#                                 #
	#=================================#
	sed -i 's/#ForwardToSyslog=no/ForwardToSyslog=yes/' /etc/systemd/journald.conf
	sleep 2
ARCH_CHROOT
if [[ $somemore == "true" ]]; then
	arch-chroot /mnt/arch << ARCH_CHROOT
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#         9. Installing           #
	#        some more utils          #
	#     (gst plugins, xorg...)      #
	#                                 #
	#=================================#
	pacman -S gst-plugins-{base,good,bad,ugly} gst-libav xorg-{server,xinit,apps} xf86-input-{mouse,keyboard} xdg-user-dirs mesa xf86-video-vesa
	Y
ARCH_CHROOT
fi
if [[ $intelamdgpu == "intel" && $somemore == "true" ]]; then
	arch-chroot /mnt/arch << ARCH_CHROOT
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#        9.5 Installing           #
	#        some more utils          #
	#         (xf86-video)            #
	#                                 #
	#=================================#
	pacman -S xf86-video-intel
	Y
ARCH_CHROOT
fi
sleep 2
if [[ $intelamdgpu == "amd" && $somemore == "true" ]]; then
	arch-chroot /mnt/arch << ARCH_CHROOT
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#        9.5 Installing           #
	#        some more utils          #
	#         (xf86-video)            #
	#                                 #
	#=================================#
	pacman -S xf86-video-amdgpu
	Y
ARCH_CHROOT
fi
if [[ $isusr = "true" ]]; then
arch-chroot /mnt/arch << ARCH_CHROOT
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#      10. Generating user        #
	#                                 #
	#=================================#
	useradd -m -g wheel -s /bin/zsh $usr
	passwd $usr
$usrpwd
$usrpwd
	sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
	sleep 2
	exit
ARCH_CHROOT
fi
if [[ $intelamdcpu == "intel" ]]; then
	arch-chroot /mnt/arch << ARCH_CHROOT
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#      11. Installing CPU         #
	#           microcode             #
	#                                 #
	#=================================#
	pacman -S intel-ucode
	Y
ARCH_CHROOT
fi
if [[ $intelamdcpu == "amd" ]]; then
	arch-chroot /mnt/arch << ARCH_CHROOT
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#      11. Installing CPU         #
	#           microcode             #
	#                                 #
	#=================================#
	pacman -S amd-ucode
	Y
ARCH_CHROOT
fi
sleep 2
arch-chroot /mnt/arch << ARCH_CHROOT
	clear
	#===== VI. CONFIGURING BOOT ======#
	#                                 #
	#   1. Generating Kernel image    #
	#                                 #
	#=================================#
	mkinitcpio -p linux
	sleep 1
	clear
	#===== VI. CONFIGURING BOOT ======#
	#                                 #
	#       2. Configuring GRUB       #
	#                                 #
	#=================================#
	grub-mkconfig -o /boot/grub/grub.cfg
	grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck
	sleep 4
	exit
ARCH_CHROOT
echo && echo
clear
echo "\
#========= WORK COMPLETE =========#
#                                 #
#     Your system should now      #
#         be installed.           #
#   Thank your for using Joe's    #
#           ARCH LINUX            #
#      UEFI INSTALL UTILITY       #
#                                 #
#   Your system will now reboot   #
#                                 #
#=================================#"
echo && echo
sleep 10 && umount -R /mnt/arch && reboot
