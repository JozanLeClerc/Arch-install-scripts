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
isusr=false
somemore=false
intelamdcpu="none"
intelamdgpu="none"
ltskern=true
numregex='^[0-9]+$'
gogogo=false
if [ ! -r /sys/firmware/efi/efivars ]; then
	efimode=false
else
	efimode=true
fi
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
#--------------------------------------- SOME FUNCTIONS -------------------------------------------#
#==================================================================================================#
jo_goodbye() {
	echo && echo
	echo -e "${BCYAN}Thank you for using Joe's Arch Linux UEFI install script.${END}"
	sleep 1
	echo -e "${BCYAN}Aborting...${END}"
	sleep 3
	clear
	exit
}
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
	jo_goodbye
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
		if [ "$drvnm" = "" ]; then
			echo && echo
			echo -e "${BRED}Can't be empty, retrying...${END}"
		elif ! [[ $drvnm =~ $numregex ]]; then
			echo && echo
			echo -e "${BRED}Illegal value, please choose something reasonable. Retrying...${END}"
		elif [ "$drvnm" -gt "$(lsblk | grep -c disk)" ]; then
			echo && echo
			echo -e "${BRED}Illegal value, please choose something reasonable. Retrying...${END}"
		elif [ "$drvnm" -le 0 ]; then
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
	while [ "$gogogo" = false ]; do
		echo && echo
		echo -e "${BCYAN}\
Please enter your ${BYELLOW}swap partition ${BCYAN}disired size:
__G"
		echo -n -e "${BYELLOW}> "
		read -r swps
		if [[ $swps == "" ]]; then
			echo && echo
			echo -e "${BRED}Can't be empty, retrying...${END}"
			gogogo=false
		elif ! [[ $swps =~ $numregex ]]; then
			echo && echo
			echo -e "${BRED}Illegal value, please choose something reasonable. Retrying...${END}"
			gogogo=false
		else
			gogogo=true
		fi
	done
	gogogo=false
	clear
	echo -e "${BMAGENTA}\
#========= I. DISK SETUP =========#
#                                 #
#      Please choose wisely       #
#                                 #
#      3. root partion size       #
#                                 #
#=================================#"
	while [ "$gogogo" = false ]; do
		echo && echo
		echo -e "${BCYAN}\
Please enter your ${BYELLOW}root partition ${BCYAN}disired size:
__G"
		echo -n -e "${BYELLOW}> "
		read -r rts
		if [[ $rts == "" ]]; then
			echo && echo
			echo -e "${BRED}Can't be empty, retrying...${END}"
			gogogo=false
		elif ! [[ $rts =~ $numregex ]]; then
			echo && echo
			echo -e "${BRED}Illegal value, please choose something reasonable. Retrying...${END}"
			gogogo=false
		else
			gogogo=true
		fi
	done
	gogogo=false
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
		jo_goodbye
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
	echo -n -e "${BYELLOW}> "
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
	echo -n -e "${BYELLOW}> "
	read -r usr
	isusr=true
	usr=$(echo "$usr" | tr '[:upper:]' '[:lower:]')
	echo && echo
	while [[ $usrusrpwd != "$usrpwd" || $usrpwd == "" ]]; do
		echo -e "${BCYAN}Enter your disired ${BYELLOW}password ${BCYAN}for ${BYELLOW}$usr${BCYAN} (can't be empty):"
		echo -n -e "${BYELLOW}> "
		read -r -s usrpwd
		echo && echo
		echo -e "${BCYAN}Confirm ${BYELLOW}user password:${BCYAN}"
		echo -n -e "${BYELLOW}> "
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
	echo -n -e "${BYELLOW}> "
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
	ltskern=false
fi
answr=""
echo && echo
echo -e "${BCYAN}Do you wish to install ${BYELLOW}Xorg ${BCYAN}and ${BYELLOW}gst-plugins ${BCYAN}as well? [${BGREEN}y${BCYAN}/${BRED}N${BCYAN}]"
echo -n -e "${BYELLOW}> "
read -r answr
if [[ $answr == y || $answr == Y || $answr == yes || $answr == Yes || $answr == YES ]]; then
	somemore=true
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
		echo -e "${BCYAN}Wiping $drv$towipe...${END}"
		dd if=/dev/zero of="$drv$towipe" bs=1M status=progress > /dev/null 2>&1
		((i++))
	done
else
	echo -e "${BCYAN}Wiping $drv...${END}"
	dd if=/dev/zero of="$drv" bs=1M status=progress > /dev/null 2>&1
fi
wipefs --all --force "$drv"
echo && echo
echo -e "${BGREEN}Wiping complete.${END}"
#================================================================#
#--------------------- PARTITIONING DISK ------------------------#
#================================================================#
if [ $efimode = true ]; then
	fdisk "$drv" << FDISK_EFI_INPUT
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
FDISK_EFI_INPUT
else
	fdisk "$drv" << FDISK_BIOS_INPUT
o
n

FDISK_BIOS_INPUT
fi
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
if pacstrap /mnt/arch base base-devel pacman-contrib > /dev/null; then
	echo -e "${BGREEN}Base packages installed${END}"
fi
echo && echo
sleep 1
clear
#================================================================#
#----------------------- UTILS DOWNLOAD -------------------------#
#================================================================#
echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#  5. Installing useful packages  #
#      so you don't have to       #
#                                 #
#=================================#${END}"
echo && echo
echo -e "${BCYAN}Installing ${BYELLOW}zip${END}"
if pacstrap /mnt/arch zip > /dev/null; then
	echo -e "${BGREEN}zip installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}unzip${END}"
if pacstrap /mnt/arch unzip > /dev/null; then
	echo -e "${BGREEN}unzip installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}p7zip${END}"
if pacstrap /mnt/arch p7zip > /dev/null; then
	echo -e "${BGREEN}p7zip installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}NetworkManager${END}"
if pacstrap /mnt/arch networkmanager > /dev/null; then
	echo -e "${BGREEN}NetworkManager installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}vim${END}"
if pacstrap /mnt/arch vim > /dev/null; then
	echo -e "${BGREEN}vim installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}mc${END}"
if pacstrap /mnt/arch mc > /dev/null; then
	echo -e "${BGREEN}mc installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}alsa-utils${END}"
if pacstrap /mnt/arch alsa-utils > /dev/null; then
	echo -e "${BGREEN}alsa-utils installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}syslog-ng${END}"
if pacstrap /mnt/arch syslog-ng > /dev/null; then
	echo -e "${BGREEN}syslog-ng installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}mtools${END}"
if pacstrap /mnt/arch mtools > /dev/null; then
	echo -e "${BGREEN}mtools installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}dostools${END}"
if pacstrap /mnt/arch dostools > /dev/null; then
	echo -e "${BGREEN}dostools installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}lsb-release${END}"
if pacstrap /mnt/arch lsb-release > /dev/null; then
	echo -e "${BGREEN}lsb-release installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}ntfs-3g${END}"
if pacstrap /mnt/arch ntfs-3g > /dev/null; then
	echo -e "${BGREEN}ntfs-3g installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}exfat-utils${END}"
if pacstrap /mnt/arch exfat-utils > /dev/null; then
	echo -e "${BGREEN}exfat-utils installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}git${END}"
if pacstrap /mnt/arch git > /dev/null; then
	echo -e "${BGREEN}git installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}zsh${END}"
if pacstrap /mnt/arch zsh > /dev/null; then
	echo -e "${BGREEN}zsh installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}ntp${END}"
if pacstrap /mnt/arch ntp > /dev/null; then
	echo -e "${BGREEN}ntp installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}cronie${END}"
if pacstrap /mnt/arch cronie > /dev/null; then
	echo -e "${BGREEN}cronie installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}grub${END}"
if pacstrap /mnt/arch grub > /dev/null; then
	echo -e "${BGREEN}grub installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}os-prober${END}"
if pacstrap /mnt/arch os-prober > /dev/null; then
	echo -e "${BGREEN}os-prober installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}efibootmgr${END}"
if pacstrap /mnt/arch efibootmgr > /dev/null; then
	echo -e "${BGREEN}efibootmgr installed${END}"
fi
echo
echo -e "${BCYAN}Installing ${BYELLOW}mkinitcpio${END}"
if pacstrap /mnt/arch mkinitcpio > /dev/null; then
	echo -e "${BGREEN}mkinitcpio installed${END}"
fi
echo
if [ "$ltskern" = true ]; then
	echo -e "${BCYAN}Installing ${BYELLOW}linux-lts${END}"
	if pacstrap /mnt/arch linux-lts > /dev/null; then
		echo -e "${BGREEN}linux-lts installed${END}"
	fi
	echo -e "${BCYAN}Installing ${BYELLOW}linux-lts-headers${END}"
	echo
	if pacstrap /mnt/arch linux-lts-headers > /dev/null; then
		echo -e "${BGREEN}linux-lts-headers installed${END}"
	fi
else
	echo -e "${BCYAN}Installing ${BYELLOW}linux${END}"
	if pacstrap /mnt/arch linux > /dev/null; then
		echo -e "${BGREEN}linux installed${END}"
	fi
	echo
	echo -e "${BCYAN}Installing ${BYELLOW}linux-headers${END}"
	if pacstrap /mnt/arch linux-headers > /dev/null; then
		echo -e "${BGREEN}linux-headers installed${END}"
	fi
fi
echo && echo
echo -e "${BGREEN}Utils installed.${END}"
sleep 4
#================================================================#
#------------------------ EXTRA DOWNLOAD ------------------------#
#================================================================#
if [ "$somemore" = true ]; then
	clear
	echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#         5.5 Installing          #
#        some more utils          #
#     (${BYELLOW}gst plugins${BMAGENTA}, ${BYELLOW}Xorg...)      ${BMAGENTA}#
#                                 #
#=================================#${END}"
	echo && echo
	echo -e "${BCYAN}Installing ${BYELLOW}gst-plugins-{base,good,bad,ugly}${END}"
	if pacstrap /mnt/arch gst-plugins-{base,good,bad,ugly} > /dev/null; then
		echo -e "${BGREEN}gst-plugins-{base,good,bad,ugly} installed${END}"
	fi
	echo
	echo -e "${BCYAN}Installing ${BYELLOW}gst-libav xorg-{server,xinit,apps}${END}"
	if pacstrap /mnt/arch gst-libav xorg-{server,xinit,apps} > /dev/null; then
		echo -e "${BGREEN}gst-libav xorg-{server,xinit,apps} installed${END}"
	fi
	echo
	echo -e "${BCYAN}Installing ${BYELLOW}xf86-input-{mouse,keyboard}${END}"
	if pacstrap /mnt/arch xf86-input-{mouse,keyboard} > /dev/null; then
		echo -e "${BGREEN}xf86-input-{mouse,keyboard} installed${END}"
	fi
	echo
	echo -e "${BCYAN}Installing ${BYELLOW}xdg-user-dirs${END}"
	if pacstrap /mnt/arch xdg-user-dirs > /dev/null; then
		echo -e "${BGREEN}xdg-user-dirs installed${END}"
	fi
	echo
	echo -e "${BCYAN}Installing ${BYELLOW}mesa${END}"
	if pacstrap /mnt/arch mesa > /dev/null; then
		echo -e "${BGREEN}mesa installed${END}"
	fi
	echo
	echo -e "${BCYAN}Installing ${BYELLOW}xf86-video-vesa${END}"
	if pacstrap /mnt/arch xf86-video-vesa > /dev/null; then
		echo -e "${BGREEN}xf86-video-vesa installed${END}"
	fi
	echo && echo
	echo -e "${BGREEN}Extra packages installed.${END}"
	sleep 4
fi
if lscpu | grep -q Intel; then
	intelamdcpu="intel"
elif lscpu | grep -q AMD; then
	intelamdcpu="amd"
fi
if lspci | grep -q Intel; then
	intelamdgpu="intel"
elif lspci | grep -q AMD; then
	intelamdgpu="amd"
fi
#================================================================#
#--------------------- GPU DRIVERS DOWNLOAD ---------------------#
#================================================================#
if [[ $intelamdgpu == "intel" && "$somemore" = true ]]; then
	clear
	echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#        5.5 Installing           #
#        some more utils          #
#         (${BYELLOW}xf86-video${BMAGENTA})            #
#                                 #
#=================================#${END}"
	echo && echo
	echo -e "${BCYAN}Installing ${BYELLOW}xf86-video-intel${END}"
	if pacstrap /mnt/arch xf86-video-intel > /dev/null; then
		echo -e "${BGREEN}xf86-video-intel installed${END}"
	fi
fi
sleep 2
if [[ $intelamdgpu == "amd" && "$somemore" = true ]]; then
	sleep 2
	clear
	echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#        5.5 Installing           #
#        some more utils          #
#         (${BYELLOW}xf86-video${BMAGENTA})            #
#                                 #
#=================================#${END}"
	echo && echo
	echo -e "${BCYAN}Installing ${BYELLOW}xf86-video-amdgpu${END}"
	if pacstrap /mnt/arch xf86-video-amdgpu > /dev/null; then
		echo -e "${BGREEN}xf86-video-amdgpu installed${END}"
	fi
fi
#================================================================#
#-------------------- CPU MICROCODE DOWNLOAD --------------------#
#================================================================#
if [[ $intelamdcpu == "intel" ]]; then
	clear
	echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#       6. Installing CPU         #
#           microcode             #
#                                 #
#=================================#${END}"
	echo && echo
	echo -e "${BCYAN}Installing ${BYELLOW}intel-ucode${END}"
	if pacstrap /mnt/arch intel-ucode > /dev/null; then
		echo -e "${BGREEN}intel-ucode${END}"
	fi
fi
if [[ $intelamdcpu == "amd" ]]; then
	clear
	echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#       6. Installing CPU         #
#           microcode             #
#                                 #
#=================================#${END}"
	echo && echo
	echo -e "${BCYAN}Installing ${BYELLOW}amd-ucode${END}"
	if pacstrap /mnt/arch amd-ucode > /dev/null; then
		echo -e "${BGREEN}amd-ucode${END}"
	fi
fi
sleep 2
#================================================================#
#------------------------ FSTAB CONFIG  -------------------------#
#================================================================#
clear
echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#       7. Generating fstab       #
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
	systemctl enable NetworkManager
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#        7. journald stuff        #
	#                                 #
	#=================================#
	sed -i 's/#ForwardToSyslog=no/ForwardToSyslog=yes/' /etc/systemd/journald.conf
	sleep 2
ARCH_CHROOT_CMDS
if [ "$isusr" = true ]; then
arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#       9. Generating user        #
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
if [ "$ltskern" = false ]; then
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
echo -e "${BBLUE}"
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
