#!/bin/bash

#==================================================================================================#
#------------------------------------ VARIABLES DECLARATION ---------------------------------------#
#==================================================================================================#
ltskern=false
utils=false
extras=false
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
intelamdcpu="none"
intelamdgpu="none"
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
	dialog --title "Aborting"\
		   --infobox "Thank you for using Joe's Arch Linux installer.\nAborting..."\
		   5 30
	sleep 4
	clear
	exit
}

jo_chk_internet() {
	dialog --infobox "Verifying that you are connected to the Internet, please wait..." 4 40
	sleep 1
	if ! wget -q --spider https://www.archlinux.org/; then
		dialog --title "ERROR"\
			   --msgbox "Critical error:\n\nIt seems that you are not connected to the internet,\
therefore Joe's installer is forced to abort.\nPlease connect to the Internet and retry."\
			   12 30
		jo_goodbye
	else
		dialog --msgbox "Success\!" 5 12
	fi
}

jo_get_hstnm() {
	while [ $hstnm = "" ]; do
		hstnm=$(dialog\
					--nocancel --title "$1"\
					--inputbox "Please choose a hostname for this machine.\
\n\nIf you are running on a managed network, \
please ask your network administrator for an appropriate name."\
					12 53\
					3>&1 1>&2 2>&3 3>&-)
		if [ "$hstnm" = "" ]; then
			dialog --infobox "Hostname is empty, retrying..." 3 34
			sleep 2
		fi
	done
}

jo_get_options() {
	sel=$(dialog --nocancel --title "$1" --checklist "Choose optional system \
components to install:" 10 50 3 \
				   linux-lts "LTS Kernel" on \
				   utils "Utils (zip, vim, git...)" on \
				   extras "Extras (Xorg, gst-plugins...)" off \
				   3>&1 1>&2 2>&3 3>&-)
	if echo -n "$sel" | grep -q linux-lts; then
		$ltskern=true
	fi
	if echo -n "$sel" | grep -q utils; then
		$utils=true
	fi
	if echo -n "$sel" | grep -q extras; then
		$extras=true
	fi
}

jo_pacstrap() {
	echo
	dialog --title "$1" --infobox "Installing $1" 3 50
	echo -e "${BCYAN}Installing ${BYELLOW}$1${END}"
	if pacstrap /mnt/arch "$1" > /dev/null; then
		dialog --title "$1" --infobox "$1 installed" 3 50
		sleep 2
	fi
}
#==================================================================================================#
#--------------------------------------------- START ----------------------------------------------#
#==================================================================================================#
clear
dialog --title "Welcome" --msgbox "Welcome to Joe's Arch Linux installation utility\!" 6 35
#==================================================================================================#
#--------------------------------------- INTERNET CHECK -------------------------------------------#
#==================================================================================================#
jo_chk_internet
#==================================================================================================#
#---------------------------------------- HOSTNAME SETUP ------------------------------------------#
#==================================================================================================#
jo_get_hstnm "I. CORE SETUP"
#==================================================================================================#
#------------------------------------ LTS AND XORG SETUP ------------------------------------------#
#==================================================================================================#
jo_get_options "I. CORE SETUP"
#==================================================================================================#
#------------------------------------------ DISK SETUP --------------------------------------------#
#==================================================================================================#
answr="n"
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
if [ "$efimode" = true ]; then
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
p
1

+$btsze
n
p
2

+$swpsze
n
p
3

+$rtsze
n
p


w
FDISK_BIOS_INPUT
fi
if [ "$efimode" = true ]; then
	mkfs.fat -F32 "$drv""1" > /dev/null
else
	mkfs.ext2 "$drv""1" > /dev/null
fi
mkswap "$drv""2" > /dev/null
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
mkdir /mnt/arch > /dev/null
swapon "$drv""2" > /dev/null
mount "$drv""3" /mnt/arch > /dev/null
mkdir /mnt/arch/boot > /dev/null
mkdir /mnt/arch/boot/efi > /dev/null
if [ "$efimode" = true ]; then
	mount "$drv""1" /mnt/arch/boot/efi > /dev/null
else
	mount "$drv""1" /mnt/arch/boot > /dev/null
fi
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
echo
jo_pacstrap base
jo_pacstrap base-devel
jo_pacstrap pacman-contrib
jo_pacstrap networkmanager
jo_pacstrap zsh
jo_pacstrap os-prober
if [ "$efimode" = true ]; then
	jo_pacstrap efibootmgr
fi
jo_pacstrap grub
jo_pacstrap mkinitcpio
if [ "$ltskern" = true ]; then
	jo_pacstrap linux-lts
	jo_pacstrap linux-lts-headers
else
	jo_pacstrap linux
	linux-headers
fi
echo && echo
echo -e "${BGREEN}Base packages installed${END}"
sleep 4
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
echo
jo_pacstrap zip
jo_pacstrap unzip
jo_pacstrap p7zip
jo_pacstrap vim
jo_pacstrap mc
jo_pacstrap alsa-utils
jo_pacstrap syslog-ng
jo_pacstrap mtools
jo_pacstrap dostools
jo_pacstrap lsb-release
jo_pacstrap ntfs-3g
jo_pacstrap exfat-utils
jo_pacstrap git
jo_pacstrap ntp
jo_pacstrap cronie
echo && echo
echo -e "${BGREEN}Utils installed.${END}"
sleep 4
#================================================================#
#------------------------ EXTRA DOWNLOAD ------------------------#
#================================================================#
if [ "$extras" = true ]; then
	clear
	echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#         5.5 Installing          #
#        some more utils          #
#     (${BYELLOW}gst plugins${BMAGENTA}, ${BYELLOW}Xorg...)      ${BMAGENTA}#
#                                 #
#=================================#${END}"
	echo
	jo_pacstrap gst-plugins-{base,good,bad,ugly}
	jo_pacstrap gst-libav
	jo_pacstrap xorg-{server,xinit,apps}
	jo_pacstrap xf86-input-{mouse,keyboard}
	jo_pacstrap xdg-user-dirs
	jo_pacstrap mesa
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
if [[ $intelamdgpu == "intel" && "$extras" = true ]]; then
	clear
	echo -e "${BMAGENTA}\
#====== IV. INSTALLING LINUX =====#
#                                 #
#        5.5 Installing           #
#        some more utils          #
#         (${BYELLOW}xf86-video${BMAGENTA})            #
#                                 #
#=================================#${END}"
	echo
	jo_pacstrap xf86-video-intel
fi
sleep 2
if [[ $intelamdgpu == "amd" && "$extras" = true ]]; then
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
	echo
	jo_pacstrap xf86-video-amdgpu
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
	echo
	jo_pacstrap intel-ucode
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
	echo
	jo_pacstrap amd-ucode
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
if [ "$efimode" = true ]; then
arch-chroot /mnt/arch << ARCH_CHROOT_EFI_GRUB_CMDS
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
ARCH_CHROOT_EFI_GRUB_CMDS
else
arch-chroot /mnt/arch << ARCH_CHROOT_BIOS_GRUB_CMDS
	clear
	#===== VI. CONFIGURING BOOT ======#
	#                                 #
	#       2. Configuring GRUB       #
	#                                 #
	#=================================#
	grub-install --target=i386-pc $drv
	grub-mkconfig -o /boot/grub/grub.cfg
	sleep 4
	exit
ARCH_CHROOT_BIOS_GRUB_CMDS
fi
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
