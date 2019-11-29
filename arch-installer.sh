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
#==================================================================================================#
#--------------------------------------- INTERNET CHECK -------------------------------------------#
#==================================================================================================#
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
		dialog --msgbox "Success!" 5 12
	fi
}
#==================================================================================================#
#---------------------------------------- HOSTNAME SETUP ------------------------------------------#
#==================================================================================================#
jo_get_hstnm() {
	gogogo=false
	while [ "$gogogo" = false ]; do
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
			gogogo=false
		else
			gogogo=true
		fi
	done
}
#==================================================================================================#
#------------------------------------ LTS AND XORG SETUP ------------------------------------------#
#==================================================================================================#
jo_get_options() {
	sel=$(dialog --nocancel --title "$1" --checklist "Choose optional system \
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
#==================================================================================================#
#------------------------------------------ DISK SETUP --------------------------------------------#
#==================================================================================================#
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
	sel=$(dialog --nocancel --title "$1"\
				 --menu "Choose the drive on which Arch Linux should be installed:" 12 55 4\
				 $(cat blkline)\
				 3>&1 1>&2 2>&3 3>&-)
	drv="/dev/"$(lsblk | grep disk | awk '{print $1}' | sed -n "$sel"p)
	rm -f blkline > /dev/null
}

jo_get_swap_size() {
	gogogo=false
	while [ "$gogogo" = false ]; do
		swps=$(dialog\
				   --nocancel --title "$1"\
				   --inputbox "Please enter your swap partition desired size: (__G)"\
				   7 65\
				   "4"\
				   3>&1 1>&2 2>&3 3>&-)
		if [ "$swps" = "" ]; then
			dialog --msgbox "Can't be empty. Retrying..." 5 32
			gogogo=false
		elif ! [[ $swps =~ $numregex ]]; then
			dialog --msgbox "Illegal value, please enter only numerical values. Retrying..." 6 38
			gogogo=false
		else
			gogogo=true
		fi
	done
}

jo_get_root_size() {
	gogogo=false
	while [ "$gogogo" = false ]; do
		rts=$(dialog\
				   --nocancel --title "$1"\
				   --inputbox "Please enter your root partition desired size: (__G)"\
				   7 65\
				   "25"\
				   3>&1 1>&2 2>&3 3>&-)
		if [ "$rts" = "" ]; then
			dialog --msgbox "Can't be empty. Retrying..." 5 32
			gogogo=false
		elif ! [[ $rts =~ $numregex ]]; then
			dialog --msgbox "Illegal value, please enter only numerical values. Retrying..." 6 38
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
		if dialog --title "Confirm this is correct"\
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
	if ! dialog --title "WARNING"\
		 --yesno "Warning: disk $drv will be wiped. \
Are you sure you wish to continue?"\
		 6 45; then
		jo_goodbye
	fi
}
#==================================================================================================#
#------------------------------------ USERS AND ROOT SETUP ----------------------------------------#
#==================================================================================================#
jo_get_root_config() {
	gogogo=false
	while [ "$gogogo" = false ]; do
		rtpwd=$(dialog --nocancel --title "$1"\
					   --passwordbox "Enter your desired root password:"\
					   7 40\
					   3>&1 1>&2 2>&3 3>&-)
		rtrtpwd=$(dialog --nocancel --title "$1"\
						 --passwordbox "Confirm root password:"\
						 7 40\
						 3>&1 1>&2 2>&3 3>&-)
		if ! [ "$rtrtpwd" = "$rtpwd" ]; then
			dialog --msgbox "Password mismatch" 5 22
			gogogo=false
		elif [ "$rtpwd" = "" ]; then
			dialog --msgbox "Password can't be empty" 5 28
			gogogo=false
		else
			gogogo=true
		fi
	done
}

jo_get_usr_config() {
	gogogo=false
	while [ "$gogogo" = false ]; do
		usr=$(dialog\
				  --nocancel --title "$1"\
				  --inputbox "Enter your desired username:"\
				  7 40\
				  3>&1 1>&2 2>&3 3>&-)
		if [ "$usr" = "" ]; then
			dialog --msgbox "Username can't be empty" 5 28
			gogogo=false
		else
			usr=$(echo "$usr" | tr '[:upper:]' '[:lower:]')
			gogogo=true
		fi
	done
	isusr=true
	gogogo=false
	while [ "$gogogo" = false ]; do
		usrpwd=$(dialog --nocancel --title "$1"\
						  --passwordbox "Enter your desired password for $usr:"\
						  7 50\
						  3>&1 1>&2 2>&3 3>&-)
		usrusrpwd=$(dialog --nocancel --title "$1"\
							 --passwordbox "Confirm $usr password:"\
							 7 50\
							 3>&1 1>&2 2>&3 3>&-)
		if ! [ "$usrusrpwd" = "$usrpwd" ]; then
			dialog --msgbox "Password mismatch" 5 22
			gogogo=false
		elif [ "$usrpwd" = "" ]; then
			dialog --msgbox "Password can't be empty" 5 28
			gogogo=false
		else
			gogogo=true
		fi
	done
	if dialog --title "$1"\
				--yesno "Should $usr be sudo?"\
				5 45; then
		isusrsudo=true
	fi
	usrshell=$(dialog --title "$1"\
						--menu "Choose a shell for $usr:"\
						11 40 4\
						"zsh" "The Z Shell"\
						"dash" "The Debian Almquist Shell"\
						"bash" "The Bourne-again Shell"\
						"sh" "The OG shell"\
						3>&1 1>&2 2>&3 3>&-)
}
#==================================================================================================#
#------------------------------------------- NTP DATE ---------------------------------------------#
#==================================================================================================#
jo_set_timedate() {
	dialog --title "$1"\
		   --infobox "Setting date via ntp"\
		   3 28
	timedatectl set-ntp true > /dev/null 2>&1
	sleep 2
}
#==================================================================================================#
#------------------------------------------- WIPEFS -----------------------------------------------#
#==================================================================================================#
jo_wipefs() {
	dialog --title "$1"\
		   --infobox "Wiping filesystem"\
		   3 28
	wipefs --all --force "$drv" > /dev/null 2>&1
	sleep 2
}
#==================================================================================================#
#---------------------------------------- PARTITIONING DISK ---------------------------------------#
#==================================================================================================#
jo_part_disk() {
	dialog --title "$1"\
		   --infobox "Partitioning disk"\
		   3 28
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
	sleep 2
}

jo_make_filesystem() {
	dialog --title "$1"\
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
	dialog --title "$1"\
		   --infobox "Mounting partitions"\
		   3 28
	mkdir -p /mnt/arch > /dev/null 2>&1
	swapon "$drv""2" > /dev/null 2>&1
	mount "$drv""3" /mnt/arch > /dev/null 2>&1
	mkdir -p /mnt/arch/boot > /dev/null 2>&1
	mkdir -p /mnt/arch/boot/efi > /dev/null 2>&1
	if [ "$efimode" = true ]; then
		mount "$drv""1" /mnt/arch/boot/efi > /dev/null 2>&1
	else
		mount "$drv""1" /mnt/arch/boot > /dev/null 2>&1
	fi
	mkdir -p /mnt/arch/home > /dev/null 2>&1
	mount "$drv""4" /mnt/arch/home > /dev/null 2>&1
	sleep 2
}
#==================================================================================================#
#-------------------------------------------- PACSTRAP --------------------------------------------#
#==================================================================================================#
jo_pacstrap() {
	paclen=$(echo -n "$1" | wc -c)
	diaglen=$(echo "15 + $paclen" | bc)
	dialog --title "$1" --infobox "Installing $1" 3 "$diaglen"
	if pacstrap /mnt/arch "$1" > /dev/null 2>&1; then
		dialog --title "$1" --infobox "$1 installed" 3 "$diaglen"
		sleep 0.5
	fi
}

jo_fstab() {
	dialog --title "$1"\
		   --infobox "Generating fstab"\
		   3 28
	genfstab -U -p /mnt/arch > /mnt/arch/etc/fstab
	sleep 2
}
#==================================================================================================#
#--------------------------------------------- START ----------------------------------------------#
#==================================================================================================#
clear
dialog --title "Welcome" --msgbox "Welcome to Joe's Arch Linux installation utility!" 6 35
jo_chk_internet
jo_get_hstnm "I. CORE SETUP"
jo_get_options "I. CORE SETUP"
jo_get_disk_config "II. DISK SETUP"
jo_warn_wiping
jo_get_root_config "III. USERS SETUP"
if dialog --title "III. USERS SETUP"\
			--yesno "Would you like to add a user to the system?"\
			6 45; then
	jo_get_usr_config "III. USERS SETUP"
fi
#==================================================================================================#
#-------------------------------------- THE ACTUAL INSTALL ----------------------------------------#
#==================================================================================================#
jo_set_timedate "IV. INSTALLING LINUX"
jo_wipefs "IV. INSTALLING LINUX"
jo_part_disk "IV. INSTALLING LINUX"
jo_make_filesystem "IV. INSTALLING LINUX"
#==================================================================================================#
#-------------------------------------- BASE DOWNLOAD ---------------------------------------------#
#==================================================================================================#
jo_pacstrap base
jo_pacstrap base-devel
jo_pacstrap pacman-contrib
jo_pacstrap networkmanager
jo_pacstrap syslog-ng
jo_pacstrap mtools
jo_pacstrap dostools
jo_pacstrap lsb-release
jo_pacstrap ntfs-3g
jo_pacstrap exfat-utils
jo_pacstrap ntp
if [ "$isusr" = true ]; then
	if [ "$usrshell" = "zsh" ]; then
		jo_pacstrap zsh
	elif [ "$usrshell" = "dash" ]; then
		jo_pacstrap dash
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
if [ "$intelamdcpu" = "intel" ]; then
	jo_pacstrap intel-ucode
elif [ "$intelamdcpu" = "amd" ]; then
	jo_pacstrap amd-ucode
fi
dialog --title "IV. INSTALLING LINUX"\
	   --infobox "Base packages installed"\
	   3 28
sleep 4
#==================================================================================================#
#--------------------------------------- UTILS DOWNLOAD -------------------------------------------#
#==================================================================================================#
if [ "$utils" = true ]; then
	jo_pacstrap zip
	jo_pacstrap unzip
	jo_pacstrap p7zip
	jo_pacstrap vim
	jo_pacstrap mc
	jo_pacstrap alsa-utils
	jo_pacstrap git
	jo_pacstrap cronie
	dialog --title "IV. INSTALLING LINUX"\
		   --infobox "Utils installed"\
		   3 28
	sleep 4
fi
#==================================================================================================#
#---------------------------------------- EXTRA DOWNLOAD ------------------------------------------#
#==================================================================================================#
if [ "$extras" = true ]; then
	jo_pacstrap gst-plugins-{base,good,bad,ugly}
	jo_pacstrap gst-libav
	jo_pacstrap xorg-{server,xinit,apps}
	jo_pacstrap xf86-input-{mouse,keyboard}
	jo_pacstrap xdg-user-dirs
	jo_pacstrap mesa
	if [ "$intelamdgpu" = "intel" ]; then
		jo_pacstrap xf86-video-intel
	elif [ "$intelamdgpu" = "amd" ]; then
		jo_pacstrap xf86-video-amdgpu
	fi
	dialog --title "IV. INSTALLING LINUX"\
		   --infobox "Extra packages installed"\
		   4 28
	sleep 4
fi
#==================================================================================================#
#------------------------------------------- FSTAB CONFIG  ----------------------------------------#
#==================================================================================================#
jo_fstab "IV. INSTALLING LINUX"
#==================================================================================================#
#-------------------------------------------- ARCH-CHROOT -----------------------------------------#
#==================================================================================================#
dialog --title "V. CONFIGURING LINUX"\
	   --infobox "Setting up the system"\
	   3 30
sleep 1
arch-chroot /mnt/arch << ARCH_CHROOT_CMDS
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$hstnm" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 $hstnm.localdomain $hstnm" >> /etc/hosts
passwd
$rtpwd
$rtpwd
systemctl enable NetworkManager
sed -i 's/#ForwardToSyslog=no/ForwardToSyslog=yes/' /etc/systemd/journald.conf
if [ "$isusr" = true ]; then if [ "$isusrsudo" = true ]; then useradd -m -g wheel -s /bin/$usrshell $usr; sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers; else useradd -m -s /bin/$usrshell $usr; fi; passwd $usr
$usrpwd
$usrpwd
fi
if [ "$ltskern" = false ]; then mkinitcpio -p linux; else mkinitcpio -p linux-lts; fi
if [ "$efimode" = true ]; then; grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi --recheck; mkdir -p /boot/grub; grub-mkconfig -o /boot/grub/grub.cfg; mkdir -p /boot/efi/EFI/BOOT; cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI; echo "bcf boot add 1 fs0:\\EFI\\GRUB\\grubx64.efi \"GRUB bootloader\"" > /boot/efi/startup.nsh; echo "exit" >> /boot/efi/startup.nsh; else grub-install --target=i386-pc $drv; grub-mkconfig -o /boot/grub/grub.cfg
ARCH_CHROOT_CMDS
dialog --title "WORK COMPLETE"\
	   --msgbox "\
Arch Linux is now installed\n\
on this terminal.\n\
Thank you for using Joe's\n
ARCH LINUX INSTALLER.\n\
\n
Your system will now reboot"\
	   10 32
umount -R /mnt/arch
reboot
