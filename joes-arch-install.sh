#!/bin/bash

#==================================================================================================#
#------------------------------------ VARIABLES DECLARATION ---------------------------------------#
#==================================================================================================#
ltskern=false
utils=false
extras=false
usrpwd=""
usrusrpwd="fade"
hstnm=""
isusr=false
isusrsudo=false
intelamdcpu="none"
intelamdgpu="none"
numregex='^[0-9]+$'
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
	whiptail --title "Aborting"\
		   --infobox "Thank you for using Joe's Arch Linux installer.\nAborting..."\
		   5 30
	sleep 4
	clear
	exit
}

jo_chk_internet() {
	whiptail --infobox "Verifying that you are connected to the Internet, please wait..." 4 40
	sleep 1
	if ! wget -q --spider https://www.archlinux.org/; then
		whiptail --title "ERROR"\
			   --msgbox "Critical error:\n\nIt seems that you are not connected to the internet,\
therefore Joe's installer is forced to abort.\nPlease connect to the Internet and retry."\
			   12 30
		jo_goodbye
	else
		whiptail --msgbox "Success!" 5 12
	fi
}

jo_get_hstnm() {
	while [ $hstnm = "" ]; do
		hstnm=$(whiptail\
					--nocancel --title "$1"\
					--inputbox "Please choose a hostname for this machine.\
\n\nIf you are running on a managed network, \
please ask your network administrator for an appropriate name."\
					12 53\
					3>&1 1>&2 2>&3 3>&-)
		if [ "$hstnm" = "" ]; then
			whiptail --infobox "Hostname is empty, retrying..." 3 34
			sleep 2
		fi
	done
}

jo_get_options() {
	sel=$(whiptail --nocancel --title "$1" --checklist "Choose optional system \
components to install:" 10 50 3 \
				   linux-lts "LTS Kernel" on \
				   utils "Utils (zip, vim, git...)" on \
				   extras "Extras (Xorg, gst-plugins...)" off \
				   3>&1 1>&2 2>&3 3>&-)
	if echo -n "$sel" | grep -q linux-lts; then
		ltskern=true
	fi
	if echo -n "$sel" | grep -q utils; then
		utils=true
	fi
	if echo -n "$sel" | grep -q extras; then
		extras=true
	fi
}

jo_get_disk() {
	rm -f blkline > /dev/null
	dn=$(lsblk | grep -c disk)
	id=1
	while [[ $dn != 0 ]]; do
		echo -n "$id $(lsblk | grep disk | \
awk '{print $1"-------("$4")";}' | sed -n "$id"p) " >> blkline
		((dn--))
		((id++))
	done
	sel=$(whiptail --nocancel --title "$1"\
				 --menu "Choose the drive on which Arch Linux should be installed:" 12 55 4\
				 $(cat blkline)\
				 3>&1 1>&2 2>&3 3>&-)
	drv="/dev/"$(lsblk | grep disk | awk '{print $1}' | sed -n "$sel"p)
	rm -f blkline > /dev/null
}

jo_get_swap_size() {
	gogogo=false
	while [ "$gogogo" = false ]; do
		swps=$(whiptail\
				   --nocancel --title "$1"\
				   --inputbox "Please enter your swap partition disired size: (__G)"\
				   7 65\
				   "4"\
				   3>&1 1>&2 2>&3 3>&-)
		if [ "$swps" = "" ]; then
			whiptail --msgbox "Can't be empty. Retrying..." 5 32
			gogogo=false
		elif ! [[ $swps =~ $numregex ]]; then
			whiptail --msgbox "Illegal value, please enter only numerical values. Retrying..." 6 38
			gogogo=false
		else
			gogogo=true
		fi
	done
}

jo_get_root_size() {
	gogogo=false
	while [ "$gogogo" = false ]; do
		rts=$(whiptail\
				   --nocancel --title "$1"\
				   --inputbox "Please enter your root partition disired size: (__G)"\
				   7 65\
				   "25"\
				   3>&1 1>&2 2>&3 3>&-)
		if [ "$rts" = "" ]; then
			whiptail --msgbox "Can't be empty. Retrying..." 5 32
			gogogo=false
		elif ! [[ $rts =~ $numregex ]]; then
			whiptail --msgbox "Illegal value, please enter only numerical values. Retrying..." 6 38
			gogogo=false
		else
			gogogo=true
		fi
	done
}

jo_get_disk_config() {
	answr=false
	while [ "$answr" = false ]; do
		answr=false
		btsze="128M"
		swps=""
		rts=""
		jo_get_disk "$1"
		jo_get_swap_size "$1"
		jo_get_root_size "$1"
		rtsze=$rts"G"
		swpsze=$swps"G"
		drv1="$drv""1"
		drv2="$drv""2"
		drv3="$drv""3"
		drv4="$drv""4"
		if whiptail --title "Confirm this is correct"\
				  --yesno "\
Drive to use:$drv\n\
\n\
boot partition ($drv1) - $btsze\n\
swap partition ($drv2) - $swpsze\n\
root partition ($drv3) - $rtsze\n\
home partition ($drv4) - All that remains"\
				  10 50; then
			answr=true
		else
			answr=false
		fi
	done
}

jo_warn_wiping() {
	if ! whiptail --title "WARNING"\
		 --yesno "Warning: disk $drv will be wiped. \
Are you sure you wish to continue?"\
		 6 45; then
		jo_goodbye
	fi
}

jo_get_root_config() {
	gogogo=false
	while [ "$gogogo" = false ]; do
		rtpwd=$(whiptail --title "$1"\
					   --passwordbox "Enter your desired root password:"\
					   7 40\
					   3>&1 1>&2 2>&3 3>&-)
		rtrtpwd=$(whiptail --title "$1"\
						 --passwordbox "Confirm root password:"\
						 7 40\
						 3>&1 1>&2 2>&3 3>&-)
		if ! [ "$rtrtpwd" = "$rtpwd" ]; then
			whiptail --msgbox "Password mismatch" 5 22
			gogogo=false
		elif [ "$rtpwd" = "" ]; then
			whiptail --msgbox "Password can't be empty" 5 28
			gogogo=false
		else
			gogogo=true
		fi
	done
}

jo_get_usr_config() {
	gogogo=false
	while [ "$gogogo" = false ]; do
		usr=$(whiptail\
				  --nocancel --title "$1"\
				  --inputbox "Enter your desired username:"\
				  7 40\
				  3>&1 1>&2 2>&3 3>&-)
		if [ "$usr" = "" ]; then
			whiptail --msgbox "Username can't be empty" 5 28
			gogogo=false
		else
			usr=$(echo "$usr" | tr '[:upper:]' '[:lower:]')
			gogogo=true
		fi
	done
	isusr=true
	gogogo=false
	while [ "$gogogo" = false ]; do
		usrpwd=$(whiptail --title "$1"\
						  --passwordbox "Enter your desired password for $usr:"\
						  7 50\
						  3>&1 1>&2 2>&3 3>&-)
		usrusrpwd=$(whiptail --title "$1"\
							 --passwordbox "Confirm $usr password:"\
							 7 50\
							 3>&1 1>&2 2>&3 3>&-)
		if ! [ "$usrusrpwd" = "$usrpwd" ]; then
			whiptail --msgbox "Password mismatch" 5 22
			gogogo=false
		elif [ "$usrpwd" = "" ]; then
			whiptail --msgbox "Password can't be empty" 5 28
			gogogo=false
		else
			gogogo=true
		fi
	done
	if whiptail --title "$1"\
				--yesno "Should $usr be sudo?"\
				6 45; then
		isusrsudo=true
	fi
	usrshell=$(whiptail --title "$1"\
						--menu "Choose a shell for $usr:"\
						10 40 3\
						"zsh" "The z shell"\
						"bash" "The bourne-against shell"\
						"sh" "The OG shell"\
						3>&1 1>&2 2>&3 3>&-)
}

jo_pacstrap() {
	paclen=$(echo -n "$1" | wc -c)
	diaglen=$(echo "15 + $paclen" | bc)
	whiptail --title "$1" --infobox "Installing $1" 3 "$diaglen"
	if pacstrap /mnt/arch "$1" > /dev/null 2>&1; then
		whiptail --title "$1" --infobox "$1 installed" 3 "$diaglen"
		sleep 0.5
	fi
}
#==================================================================================================#
#--------------------------------------------- START ----------------------------------------------#
#==================================================================================================#
clear
whiptail --title "Welcome" --msgbox "Welcome to Joe's Arch Linux installation utility!" 6 35
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
jo_get_disk_config "II. DISK SETUP"
jo_warn_wiping
#==================================================================================================#
#------------------------------------ USERS AND ROOT SETUP ----------------------------------------#
#==================================================================================================#
jo_get_root_config "III. USERS SETUP"
if whiptail --title "III. USERS SETUP"\
			--yesno "Would you like to add a user to the system?"\
			6 45; then
	jo_get_usr_config "III. USERS SETUP"
fi
#==================================================================================================#
#-------------------------------------- THE ACTUAL INSTALL ----------------------------------------#
#==================================================================================================#
#================================================================#
#--------------------------- NTP DATE ---------------------------#
#================================================================#
whiptail --title "IV. INSTALLING LINUX"\
	   --infobox "Setting date via ntp"\
	   3 28
timedatectl set-ntp true > /dev/null 2>&1
sleep 2
#================================================================#
#------------------------- WIPING DISK --------------------------#
#================================================================#
whiptail --title "IV. INSTALLING LINUX"\
	   --infobox "Partitioning filesystem"\
	   3 28
wipefs --all --force "$drv" > /dev/null 2>&1
#================================================================#
#--------------------- PARTITIONING DISK ------------------------#
#================================================================#
if [ "$efimode" = true ]; then
	fdisk --wipe-partition always "$drv" << FDISK_EFI_INPUT > /dev/null 2>&1
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
	fdisk --wipe-partition always "$drv" << FDISK_BIOS_INPUT > /dev/null 2>&1
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
whiptail --title "IV. INSTALLING LINUX"\
	   --infobox "Making filesystem"\
	   3 28
if [ "$efimode" = true ]; then
	mkfs.fat -F32 "$drv""1" > /dev/null 2>&1
else
	mkfs.ext2 "$drv""1" > /dev/null 2>&1
fi
mkswap "$drv""2" > /dev/null 2>&1
mkfs.ext4 "$drv""3" > /dev/null 2>&1
mkfs.ext4 "$drv""4" > /dev/null 2>&1
sleep 2
#================================================================#
#---------------------- MOUNT PARTITIONS ------------------------#
#================================================================#
whiptail --title "IV. INSTALLING LINUX"\
	   --infobox "Mounting partitions"\
	   3 28
mkdir /mnt/arch > /dev/null 2>&1
swapon "$drv""2" > /dev/null 2>&1
mount "$drv""3" /mnt/arch > /dev/null 2>&1
mkdir /mnt/arch/boot > /dev/null 2>&1
mkdir /mnt/arch/boot/efi > /dev/null 2>&1
if [ "$efimode" = true ]; then
	mount "$drv""1" /mnt/arch/boot/efi > /dev/null 2>&1
else
	mount "$drv""1" /mnt/arch/boot > /dev/null 2>&1
fi
mkdir /mnt/arch/home > /dev/null 2>&1
mount "$drv""4" /mnt/arch/home > /dev/null 2>&1
sleep 2
clear
#================================================================#
#------------------------ BASE DOWNLOAD -------------------------#
#================================================================#
echo
jo_pacstrap base
jo_pacstrap base-devel
jo_pacstrap pacman-contrib
jo_pacstrap networkmanager
if [ "$isusr" = true ]; then
	if [ "$usrshell" = "zsh" ]; then
		jo_pacstrap zsh
	fi
fi
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
	jo_pacstrap linux-headers
fi
whiptail --title "IV. INSTALLING LINUX"\
	   --infobox "Base packages installed"\
	   4 28
sleep 4
#================================================================#
#----------------------- UTILS DOWNLOAD -------------------------#
#================================================================#
if [ "$utils" = true ]; then
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
fi
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
	if [ "$isusrsudo" = true ]; then
		arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#       9. Generating user        #
	#                                 #
	#=================================#
	useradd -m -g wheel -s /bin/$usrshell $usr
	passwd $usr
$usrpwd
$usrpwd
	sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
	sleep 2
	exit
ARCH_CHROOT_CMDS
	else
		arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#       9. Generating user        #
	#                                 #
	#=================================#
	useradd -m -s /bin/$usrshell $usr
	passwd $usr
$usrpwd
$usrpwd
	sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
	sleep 2
	exit
ARCH_CHROOT_CMDS
	fi
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
