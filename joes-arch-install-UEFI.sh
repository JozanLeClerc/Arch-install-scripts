#!/bin/bash

#==================================================================================================#
#------------------------------------ VARIABLES DECLARATION ---------------------------------------#
#==================================================================================================#

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

#==================================================================================================#
#--------------------------------------- COLORS DECLARATION ---------------------------------------#
#==================================================================================================#

NBLACK="\033[0;30m"
NRED="\033[0;31m"
NGREEN="\033[0;32m"
NYELLOW="\033[0;33m"
NBLUE="\033[0;34m"
NMAGENTA="\033[0;35m"
NCYAN="\033[0;36m"
NWHITE="\033[0;37m"

BBLACK="\033[1;30m"
BRED="\033[1;31m"
BGREEN="\033[1;32m"
BYELLOW="\033[1;33m"
BBLUE="\033[1;34m"
BMAGENTA="\033[1;35m"
BCYAN="\033[1;36m"
BWHITE="\033[1;37m"

END="\033[0;0m"

#==================================================================================================#
#--------------------------------------------- START ----------------------------------------------#
#==================================================================================================#

clear
echo -e "${BMAGENTA}\
#============ WELCOME ============#
#                                 #
#        Welcome to Joe's         #
#           ARCH LINUX            #
#      UEFI INSTALL SCRIPT        #
#                                 #
#  (press [return] to begin...)   #
#                                 #
#=================================#${END}"
read -r

#==================================================================================================#
#----------------------------------------- ERRORS CHECK -------------------------------------------#
#==================================================================================================#

if [ ! -r /sys/firmware/efi/efivars ]; then
	clear
	echo -e "${BRED}\
X=X=X=X=X=X=X ERROR X=X=X=X=X=X=X=X
X                                 X
X    It seems that boot mode      X
X      is not set to UEFI         X
X    therefore Joe's script is    X
X        forced to abort          X
X                                 X
X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X${END}"
	sleep 6
	echo && echo
	echo -e "${BBLUE}Thank you for using Joe's Arch Linux UEFI install script.${END}"
	sleep 1
	echo -e "${BRED}Aborting...${END}"
	sleep 3
	clear
	exit
fi
clear
echo -e "${BBLUE}Verifying that your are connected to the Internet, please wait...${END}"

wget -q --spider https://archlinux.org > /dev/null
tmpret=$?
if [ $tmpret -ne 0 ]; then
	clear
	echo -e "${BRED}\
X=X=X=X=X=X=X ERROR X=X=X=X=X=X=X=X
X                                 X
X       It seems that your        X
X         terminal is not         X
X    connected to the Internet    X
X    therefore Joe's script is    X
X        forced to abort          X
X                                 X
X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X${END}"
	sleep 6
	echo && echo
	echo -e "${BBLUE}Thank you for using Joe's Arch Linux UEFI install script.${END}"
	sleep 1
	echo -e "${BRED}Aborting...${END}"
	sleep 3
	clear
	exit
else
	echo -e "${BGREEN}Success!${END}"
	echo
	echo -e "${BBLUE}Press [retrun] key to continue${END}"
	read -r
fi

#==================================================================================================#
#------------------------------------------ DISK SETUP --------------------------------------------#
#==================================================================================================#

while [[ $answr != y && $answr != Y && $answr != yes && $answr != Yes && $answr != YES ]]; do
	drvnm=""
	swps=""
	rts=""
	clear
	echo -e "${BMAGENTA}\
#========= I. DISK SETUP =========#
#                                 #
#      Please choose wisely       #
#                                 #
#      1. Drive to be used        #
#                                 #
#=================================#${END}"
	while [[ $drvnm == "" || $drvnm -gt $(lsblk | grep -c disk) || $drvnm -le 0 ]]; do
		echo && echo
		dn=$(lsblk | grep -c disk)
		id=1
		lsblk | grep disk | awk '{print "${BBLUE}DISK", "", "", "SIZE${END}";}{print "----", "", "", "----"}{print "${BCYAN}$1" " ->", "${BYELLOW}$4"}'
		echo && echo
		echo "${BMAGENTA}Please choose the drive on which Arch Linux shoud be installed:${END}"
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

#==================================================================================================#
#------------------------------------------ USERS SETUP -------------------------------------------#
#==================================================================================================#

answr="n"

while [[ $rtrtpwd != "$rtpwd" || $rtpwd == "" ]]; do
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
	if [[ $rtrtpwd != "$rtpwd" ]]; then
		echo && echo
		echo "Password mismatch, retrying..."
		sleep 2
	fi
	if [[ $rtpwd = "" ]]; then
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
		if [[ $usrusrpwd != "$usrpwd" ]]; then
			echo && echo
			echo "Password mismatch, retrying..."
			sleep 2
		fi
		if [[ $usrpwd == "" ]]; then
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

#==================================================================================================#
#-------------------------------------- THE ACTUAL INSTALL ----------------------------------------#
#==================================================================================================#


#================================================================#
#--------------------------- NTP DATE ---------------------------#
#================================================================#


clear
echo "\
#====== IV. INSTALLING LINUX =====#
#                                 #
#        1. Setting date          #
#             via ntp             #
#                                 #
#=================================#"
timedatectl set-ntp true > /dev/null
sleep 2

#================================================================#
#--------------------- PARTITIONING DISK ------------------------#
#================================================================#

clear
echo "\
#====== IV. INSTALLING LINUX =====#
#                                 #
#        2. Partitionning         #
#          disk $drv          #
#                                 #
#=================================#"
echo && echo
basepartc=$(lsblk "$drv" | grep -c part)
if [ "$basepartc" -ge 1 ]; then
	i=1
	echo "Whiping disk. This step may take a while."
	echo && echo
	while [[ $i -le $basepartc ]]; do
		towhipe=$(lsblk "$drv" | grep part | awk '{print $1}' | rev | cut -c -1 | rev | awk "NR==$i")
		dd if=/dev/zero of="$drv$towhipe" bs=1M status=progress > /dev/null 2>&1
		((i++))
	done
fi
dd if=/dev/zero of="$drv" bs=1M status=progress > /dev/null 2>&1
wipefs --all --force "$drv"
echo "Whiping complete."
fdisk "$drv" << FDISK_INPUT
g
n
1

+$btsze
n
2

+$swpsze
n
3

+$rtsze
n
4


t
2
19
w
FDISK_INPUT
mkswap "$drv""2" > /dev/null
mkfs.fat -F32 "$drv""1" > /dev/null
mkfs.ext4 "$drv""3" > /dev/null
mkfs.ext4 "$drv""4" > /dev/null
sleep 2
clear
echo "\
#====== IV. INSTALLING LINUX =====#
#                                 #
#     3. Mounting partitions      #
#                                 #
#=================================#"
swapon "$drv""2" > /dev/null
mkdir /mnt/arch > /dev/null
mount "$drv""3" /mnt/arch > /dev/null
mkdir /mnt/arch/boot > /dev/null
mkdir /mnt/arch/boot/efi > /dev/null
mount "$drv""1" /mnt/arch/boot/efi > /dev/null
mkdir /mnt/arch/home > /dev/null
mount "$drv""4" /mnt/arch/home > /dev/null
sleep 2
clear
echo "\
#====== IV. INSTALLING LINUX =====#
#                                 #
#  4. Downloading base packages   #
#          (about 300M)           #
#                                 #
#       Please be patient,        #
#      this may take a while      #
#                                 #
#=================================#"
pacstrap /mnt/arch base base-devel pacman-contrib
echo && echo
echo "Base packages installed."
sleep 1
clear
echo "\
#====== IV. INSTALLING LINUX =====#
#                                 #
#       5. Generating fstab       #
#                                 #
#=================================#"
genfstab -U -p /mnt/arch > /mnt/arch/etc/fstab
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
	pacman -S networkmanager grub os-prober efibootmgr
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
arch-chroot /mnt/arch << ARCH_CHROOT
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#   9. Installing useful packages #
	#                                 #
	#=================================#
	pacman -S zip unzip p7zip vim mc alsa-utils syslog-ng mtools dostools lsb-release ntfs-3g exfat-utils git zsh ntp cronie
	sleep 2
ARCH_CHROOT
if [[ $somemore == "true" ]]; then
	arch-chroot /mnt/arch << ARCH_CHROOT
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#         9. Installing           #
	#        some more utils          #
	#     (gst plugins, Xorg...)      #
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
	#       1. Configuring GRUB       #
	#                                 #
	#=================================#
	grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi --recheck
	grub-mkconfig -o /boot/grub/grub.cfg
	mkdir /boot/efi/EFI/BOOT
	cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
	echo "bcf boot add 1 fs0:\\EFI\\GRUB\\grubx64.efi \"GRUB bootloader\"" > /boot/efi/startup.nsh
	echo "exit" >> /boot/efi/startup.nsh
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
sleep 10
umount -R /mnt/arch
reboot
