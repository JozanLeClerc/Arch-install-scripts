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
ltskern=1
#==================================================================================================#
#--------------------------------------- COLORS DECLARATION ---------------------------------------#
#==================================================================================================#
#NBLACK="\033[0;30m"
#NRED="\033[0;31m"
#NGREEN="\033[0;32m"
#NYELLOW="\033[0;33m"
#NBLUE="\033[0;34m"
#NMAGENTA="\033[0;35m"
#NCYAN="\033[0;36m"
#NWHITE="\033[0;37m"

#BBLACK="\033[1;30m"
BRED="\033[1;31m"
BGREEN="\033[1;32m"
BYELLOW="\033[1;33m"
BBLUE="\033[1;34m"
BMAGENTA="\033[1;35m"
BCYAN="\033[1;36m"
#BWHITE="\033[1;37m"

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
#  (press ${BYELLOW}[return] ${BMAGENTA}to begin...)   #
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
	echo -e "${BCYAN}Thank you for using Joe's Arch Linux UEFI install script.${END}"
	sleep 1
	echo -e "${BCYAN}Aborting...${END}"
	sleep 3
	clear
	exit
fi
clear
echo -e "${BCYAN}Verifying that your are connected to the Internet, please wait...${END}"

wget -q --spider https://www.archlinux.org > /dev/null
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
	echo -e "${BCYAN}Thank you for using Joe's Arch Linux UEFI install script.${END}"
	sleep 1
	echo -e "${BRED}Aborting...${END}"
	sleep 3
	clear
	exit
else
	echo -e "${BGREEN}Success!${END}"
	echo
	echo -e "${BCYAN}Press ${BYELLOW}[retrun] ${BCYAN}key to continue${END}"
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
		echo -e "${BBLUE}DISK  |  SIZE\n------+--------${END}"
		lsblk | grep disk | awk '{print "\033[1;36m"$1 "\033[1;34m   | ", "\033[1;33m"$4;}'
		echo && echo
		echo -e "${BCYAN}Please choose the ${BYELLOW}drive ${BCYAN}on which Arch Linux shoud be installed:${END}"
		while [[ $dn != 0 ]]; do
			echo -e "${BYELLOW}$id. $(lsblk | grep disk | awk '{print "\033[1;36m"$1"\033[0m";}' | sed -n "$id"p)"
			((dn--))
			((id++))
		done
		echo -n -e "${BYELLOW}> "
		read -r drvnm
		if [[ $drvnm == "" ]]; then
			echo && echo
			echo -e "${BRED}Can't be empty, retrying...${END}"
		fi
		if [[ $drvnm -gt $(lsblk | grep -c disk) ]]; then
			echo && echo
			echo -e "${BRED}Illegal value, please choose something reasonable. Retrying...${END}"
		fi
		if [[ $drvnm -lt 0 ]]; then
			echo && echo
			echo -e "${BRED}Illegal value, please choose something reasonable. Retrying...${END}"
		fi
		if [[ $drvnm == 0 ]]; then
			echo && echo
			echo -e "${BRED}Illegal value, please choose something reasonable. Retrying...${END}"
		fi
	done
	drv="/dev/"$(lsblk | grep disk | awk '{print $1}' | sed -n "$drvnm"p)
	clear
	echo -e "${BMAGENTA}\
#========= I. DISK SETUP =========#
#                                 #
#      Please choose wisely       #
#                                 #
#      2. swap partion size       #
#                                 #
#=================================#${END}"
	while [[ $swps == "" ]]; do
		echo && echo
		echo -e "${BCYAN}\
Please enter your ${BYELLOW}swap partition ${BCYAN}disired size:
__G"
		echo -n -e "${BYELLOW}> "
		read -r swps
		if [[ $swps == "" ]]; then
			echo && echo
			echo -e "${BRED}Can't be empty, retrying...${END}"
		fi
	done
	clear
	echo -e "${BMAGENTA}\
#========= I. DISK SETUP =========#
#                                 #
#      Please choose wisely       #
#                                 #
#      3. root partion size       #
#                                 #
#=================================#"
	while [[ $rts == "" ]]; do
		echo && echo
		echo -e "${BCYAN}\
Please enter your ${BYELLOW}root partition ${BCYAN}disired size:
__G"
		echo -n -e "${BYELLOW}> "
		read -r rts
		if [[ $rts == "" ]]; then
			echo && echo
			echo -e "${BRED}Can't be empty, retrying...${END}"
		fi
	done
	btsze="128M"
	rtsze=$rts"G"
	swpsze=$swps"G"
	clear
	echo -e "${BMAGENTA}\
#============= CONFIRM THIS IS CORRECT ===============#
#                                                     #
#                DRIVE TO USE: ${BCYAN}$drv               ${BMAGENTA}#
#                                                     #
#  /boot/efi > BOOT partition size: ${BYELLOW}$btsze              ${BMAGENTA}#"
if [ "$swps" -ge 10 ]; then
	echo -e "#              SWAP partition size: ${BYELLOW}$swpsze               ${BMAGENTA}#"
else
	echo -e "#              SWAP partition size: ${BYELLOW}$swpsze                ${BMAGENTA}#"
fi
if [ "$rts" -ge 100 ]; then
	echo -e "#  /         > ROOT partition size: ${BYELLOW}$rtsze              ${BMAGENTA}#"
elif [ "$rts" -ge 10 ]; then
	echo -e "#  /         > ROOT partition size: ${BYELLOW}$rtsze               ${BMAGENTA}#"
else
	echo -e "#  /         > ROOT partition size: ${BYELLOW}$rtsze                ${BMAGENTA}#"
fi
echo -e "#  /home     > HOME partition size: ${BYELLOW}all that remains  ${BMAGENTA}#
#                                                     #
#=====================================================#${END}"
	echo && echo
	echo -e "${BCYAN}Is that correct? [${BGREEN}y${BCYAN}/${BRED}N${BCYAN}]"
	echo -n -e "${BYELLOW}> "
	read -r answr
	if [[ $answr != y && $answr != Y && $answr != yes && $answr != Yes && $answr != YES ]]; then
		echo && echo
		echo -e "${BCYAN}Retrying..."
		echo
		echo -e "Press ${BYELLOW}[retrun] ${BCYAN}key to continue${END}"
		read -r
	fi
done

answr="n"
while [[ $answr != y && $answr != Y && $answr != yes && $answr != Yes && $answr != YES ]]; do
	echo && echo
	echo -e "${BRED}Disk ${BYELLOW}$drv ${BRED}will be wiped. Are you sure you want to continue? [${BGREEN}y${BRED}/${BRED}N${BRED}]${END}"
	echo -n -e "${BRED}> "
	read -r answr
	if [[ $answr != y && $answr != Y && $answr != yes && $answr != Yes && $answr != YES ]]; then
		echo && echo
		echo -e "${BCYAN}Thank you for using Joe's Arch Linux UEFI install script.${END}"
		sleep 1
		echo -e "${BCYAN}Aborting...${END}"
		sleep 3
		clear
		exit
	fi
done
#==================================================================================================#
#------------------------------------ USERS AND ROOT SETUP ----------------------------------------#
#==================================================================================================#
answr="n"

while [[ $rtrtpwd != "$rtpwd" || $rtpwd == "" ]]; do
	clear
	echo -e "${BMAGENTA}\
#======= II. USERS SETUP =========#
#                                 #
#        1. root password         #
#                                 #
#=================================#${END}"
	echo && echo
	echo -e "${BCYAN}Enter your disired ${BYELLOW}root password ${BCYAN}(can't be empty):"
	echo -n -e "${BYELLOW}> "
	read -r -s rtpwd
	echo && echo
	echo -e "${BCYAN}Confirm ${BYELLOW}root password${BCYAN}:"
	echo -n -e "${BCYAN}> "
	read -r -s rtrtpwd
	if [[ $rtrtpwd != "$rtpwd" ]]; then
		echo && echo
		echo -e "${BRED}Password mismatch, retrying...${END}"
		sleep 2
	fi
	if [[ $rtpwd = "" ]]; then
		echo && echo
		echo -e "${BRED}Password is empty, retrying...${END}"
		sleep 2
	fi
done

clear
echo -e "${BMAGENTA}\
#======= II. USERS SETUP =========#
#                                 #
#          2. User add            #
#                                 #
#=================================#${END}"
echo && echo
echo -e "${BCYAN}Would you like to add a user to the system? (will automatically receive sudo rights) [${BGREEN}y${BCYAN}/${BRED}N${BCYAN}]"
echo -n -e "${BYELLOW}> " 
read -r answr
if [[ $answr == y || $answr == Y || $answr == yes || $answr == Yes || $answr == YES ]]; then
	echo && echo
	echo -e "${BCYAN}Enter your desired ${BYELLOW}username:"
	echo -n -e "> "
	read -r usr
	isusr="true"
	usr=$(echo "$usr" | tr '[:upper:]' '[:lower:]')
	echo && echo
	while [[ $usrusrpwd != "$usrpwd" || $usrpwd == "" ]]; do
		echo -e "${BCYAN}Enter your disired ${BYELLOW}password ${BCYAN}for ${BYELLOW}$usr${BCYAN} (can't be empty):"
		echo -n -e "> "
		read -r -s usrpwd
		echo && echo
		echo -e "${BCYAN}Confirm ${BYELLOW}user password:${BCYAN}"
		echo -n -e "> "
		read -r -s usrusrpwd
		if [[ $usrusrpwd != "$usrpwd" ]]; then
			echo && echo
			echo -e "${BRED}Password mismatch, retrying...${END}"
			sleep 2
		fi
		if [[ $usrpwd == "" ]]; then
			echo && echo
			echo -e "${BRED}Password is empty, retrying...${END}"
			sleep 2
		fi
	done
fi
clear
#==================================================================================================#
#---------------------------------------- HOSTNAME SETUP ------------------------------------------#
#==================================================================================================#
echo -e "${BMAGENTA}\
#======= II. USERS SETUP =========#
#                                 #
#          3. hostname            #
#                                 #
#=================================#${END}"
while [[ $hstnm == "" ]]; do
	echo && echo
	echo -e "${BCYAN}Enter your disired ${BYELLOW}hostname ${BCYAN}for this terminal (can't be empty):"
	echo -n -e "> "
	read -r hstnm
	if [[ $hstnm == "" ]]; then
		echo && echo
		echo -e "${BRED}Hostname is empty, retrying...${END}"
		sleep 2
	fi
done
answr="n"
clear
#==================================================================================================#
#------------------------------------ LTS AND XORG SETUP ------------------------------------------#
#==================================================================================================#
echo -e "${BMAGENTA}\
#====== III. EXTRAS SETUP ========#
#                                 #
#            1. More              #
#                                 #
#=================================#${END}"
echo && echo
echo -e "${BCYAN}Do you wish to install an ${BYELLOW}LTS Kernel${BCYAN}? [${BGREEN}Y${BCYAN}/${BRED}n${BCYAN}]"
echo -n -e "${BYELLOW}> "
read -r answr
if [[ $answr == n || $answr == N || $answr == no || $answr == No || $answr == NO ]]; then
	ltskern=0
fi
answr=""
echo && echo
echo -e "${BCYAN}Do you wish to install ${BYELLOW}Xorg ${BCYAN}and ${BYELLOW}gst-plugins ${BCYAN}as well? [${BGREEN}n${BCYAN}/${BRED}N${BCYAN}]"
echo -n -e "${BYELLOW}> "
read -r answr
if [[ $answr == y || $answr == Y || $answr == yes || $answr == Yes || $answr == YES ]]; then
	somemore="true"
fi
clear
answr=""
#==================================================================================================#
#-------------------------------------- THE ACTUAL INSTALL ----------------------------------------#
#==================================================================================================#

#================================================================#
#--------------------------- NTP DATE ---------------------------#
#================================================================#
clear
echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#        1. Setting date          #
#             via ntp             #
#                                 #
#=================================#${END}"
timedatectl set-ntp true > /dev/null
sleep 2
#================================================================#
#------------------------- WIPING DISK --------------------------#
#================================================================#
clear
echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#        2. Partitionning         #
#          disk $drv          #
#                                 #
#=================================#${END}"
echo && echo
echo -e "${BCYAN}Wiping disk. This step may take a while.${END}"
basepartc=$(lsblk "$drv" | grep -c part)
if [ "$basepartc" -ge 1 ]; then
	i=1
	while [[ $i -le $basepartc ]]; do
		towipe=$(lsblk "$drv" | grep part | awk '{print $1}' | rev | cut -c -1 | rev | awk "NR==$i")
		dd if=/dev/zero of="$drv$towipe" bs=1M status=progress > /dev/null 2>&1
		((i++))
	done
fi
dd if=/dev/zero of="$drv" bs=1M status=progress > /dev/null 2>&1
wipefs --all --force "$drv"
echo -e "${BGREEN}Wiping complete.${END}"
#================================================================#
#--------------------- PARTITIONING DISK ------------------------#
#================================================================#
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
#================================================================#
#---------------------- MOUNT PARTITIONS ------------------------#
#================================================================#
echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#     3. Mounting partitions      #
#                                 #
#=================================#${END}"
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
#================================================================#
#------------------------ BASE DOWNLOAD -------------------------#
#================================================================#
echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#  4. Downloading base packages   #
#                                 #
#       Please be patient,        #
#      this may take a while      #
#                                 #
#=================================#${END}"
echo && echo
echo -e "${BCYAN}Installing ${BYELLOW}base packages${END}"
pacstrap /mnt/arch base base-devel pacman-contrib > /dev/null
echo && echo
echo -e "${BGREEN}Base packages installed${END}"
sleep 1
clear
#================================================================#
#----------------------- UTILS DOWNLOAD -------------------------#
#================================================================#
echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#     4.5. Installing useful      #
#            packages             #
#                                 #
#=================================#${END}"
echo && echo
echo -e "${BCYAN}Installing ${BYELLOW}zip${END}"
pacstrap /mnt/arch zip > /dev/null
echo -e "${BGREEN}zip installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}unzip${END}"
pacstrap /mnt/arch unzip > /dev/null
echo -e "${BGREEN}unzip installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}p7zip${END}"
pacstrap /mnt/arch p7zip > /dev/null
echo -e "${BGREEN}p7zip installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}vim${END}"
pacstrap /mnt/arch vim > /dev/null
echo -e "${BGREEN}vim installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}mc${END}"
pacstrap /mnt/arch mc > /dev/null
echo -e "${BGREEN}mc installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}alsa-utils${END}"
pacstrap /mnt/arch alsa-utils > /dev/null
echo -e "${BGREEN}alsa-utils installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}syslog-ng${END}"
pacstrap /mnt/arch syslog-ng > /dev/null
echo -e "${BGREEN}syslog-ng installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}mtools${END}"
pacstrap /mnt/arch mtools > /dev/null
echo -e "${BGREEN}mtools installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}dostools${END}"
pacstrap /mnt/arch dostools > /dev/null
echo -e "${BGREEN}dostools installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}lsb-release${END}"
pacstrap /mnt/arch lsb-release > /dev/null
echo -e "${BGREEN}lsb-release installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}ntfs-3g${END}"
pacstrap /mnt/arch ntfs-3g > /dev/null
echo -e "${BGREEN}ntfs-3g installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}exfat-utils${END}"
pacstrap /mnt/arch exfat-utils > /dev/null
echo -e "${BGREEN}exfat-utils installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}git${END}"
pacstrap /mnt/arch git > /dev/null
echo -e "${BGREEN}git installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}zsh${END}"
pacstrap /mnt/arch zsh > /dev/null
echo -e "${BGREEN}zsh installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}ntp${END}"
pacstrap /mnt/arch ntp > /dev/null
echo -e "${BGREEN}ntp installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}cronie${END}"
pacstrap /mnt/arch cronie > /dev/null
echo -e "${BGREEN}cronie installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}grub${END}"
pacstrap /mnt/arch grub > /dev/null
echo -e "${BGREEN}grub installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}os-prober${END}"
pacstrap /mnt/arch os-prober > /dev/null
echo -e "${BGREEN}os-prober installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}efibootmgr${END}"
pacstrap /mnt/arch efibootmgr > /dev/null
echo -e "${BGREEN}efibootmgr installed${END}"
echo
echo -e "${BCYAN}Installing ${BYELLOW}mkinitcpio${END}"
pacstrap /mnt/arch mkinitcpio > /dev/null
echo -e "${BGREEN}mkinitcpio installed${END}"
echo
if [ $ltskern -eq 1 ]; then
	echo -e "${BCYAN}Installing ${BYELLOW}linux-lts${END}"
	pacstrap /mnt/arch linux-lts > /dev/null
	echo -e "${BGREEN}linux-lts installed${END}"
	echo -e "${BCYAN}Installing ${BYELLOW}linux-lts-headers${END}"
	echo
	pacstrap /mnt/arch linux-lts-headers > /dev/null
	echo -e "${BGREEN}linux-lts-headers installed${END}"
else
	echo -e "${BCYAN}Installing ${BYELLOW}linux${END}"
	pacstrap /mnt/arch linux > /dev/null
	echo -e "${BGREEN}linux installed${END}"
	echo
	echo -e "${BCYAN}Installing ${BYELLOW}linux-headers${END}"
	pacstrap /mnt/arch linux-headers > /dev/null
	echo -e "${BGREEN}linux-headers installed${END}"
fi
echo && echo
echo -e "${BGREEN}Extra packages installed.${END}"
sleep 4
#================================================================#
#------------------------ FSTAB CONFIG  -------------------------#
#================================================================#
clear
echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#       5. Generating fstab       #
#                                 #
#=================================#${END}"
genfstab -U -p /mnt/arch > /mnt/arch/etc/fstab
sleep 2
#================================================================#
#------------------------- ARCH-CHROOT --------------------------#
#================================================================#
clear
echo -e "${BMAGENTA}\
#====== V. CONFIGURING LINUX =====#
#                                 #
#      1. Now changing root       #
#                                 #
#=================================#${END}"
echo -e "${BBLUE}"
sleep 2
arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
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
$rtpwd
$rtpwd
	sleep 2
	clear
	#===== IV. CONFIGURING LINUX =====#
	#                                 #
	#     7. Setting up network       #
	#                                 #
	#=================================#
	pacman -S networkmanager
	Y
ARCH_CHROOT_CMDS
arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
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
ARCH_CHROOT_CMDS
if [[ $somemore == "true" ]]; then
	arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
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
ARCH_CHROOT_CMDS
fi
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
if [[ $intelamdgpu == "intel" && $somemore == "true" ]]; then
	arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
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
ARCH_CHROOT_CMDS
fi
sleep 2
if [[ $intelamdgpu == "amd" && $somemore == "true" ]]; then
	arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
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
ARCH_CHROOT_CMDS
fi
if [[ $isusr = "true" ]]; then
arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
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
ARCH_CHROOT_CMDS
fi
if [[ $intelamdcpu == "intel" ]]; then
	arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#      11. Installing CPU         #
	#           microcode             #
	#                                 #
	#=================================#
	pacman -S intel-ucode
	Y
ARCH_CHROOT_CMDS
fi
if [[ $intelamdcpu == "amd" ]]; then
	arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#      11. Installing CPU         #
	#           microcode             #
	#                                 #
	#=================================#
	pacman -S amd-ucode
	Y
ARCH_CHROOT_CMDS
fi
sleep 2
if [ $ltskern -eq 0 ]; then
	arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
	clear
	#===== VI. CONFIGURING BOOT ======#
	#                                 #
	#    1. Configuring the Kernel    #
	#                                 #
	#=================================#
	mkinitcpio -p linux
ARCH_CHROOT_CMDS
else
	arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
	clear
	#===== VI. CONFIGURING BOOT ======#
	#                                 #
	#    1. Configuring the Kernel    #
	#                                 #
	#=================================#
	mkinitcpio -p linux-lts
ARCH_CHROOT_CMDS
fi
sleep 2
arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
	clear
	#===== VI. CONFIGURING BOOT ======#
	#                                 #
	#       2. Configuring GRUB       #
	#                                 #
	#=================================#
	grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi --recheck
	mkdir -p /boot/grub
	grub-mkconfig -o /boot/grub/grub.cfg
	mkdir -p /boot/efi/EFI/BOOT
	cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
	echo "bcf boot add 1 fs0:\\EFI\\GRUB\\grubx64.efi \"GRUB bootloader\"" > /boot/efi/startup.nsh
	echo "exit" >> /boot/efi/startup.nsh
	sleep 4
	exit
ARCH_CHROOT_CMDS
echo && echo
clear
echo -e "${BMAGENTA}\
#========= ${BGREEN}WORK COMPLETE ${BMAGENTA}=========#
#                                 #
#     Your system should now      #
#         be installed.           #
#   Thank your for using Joe's    #
#           ARCH LINUX            #
#      UEFI INSTALL UTILITY       #
#                                 #
#   Your system will now reboot   #
#                                 #
#=================================#${END}"
echo && echo
sleep 10
umount -R /mnt/arch
reboot
