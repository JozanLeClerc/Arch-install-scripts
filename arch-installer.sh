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
vbox=false
vmware=false
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

jo_get_vm() {
	if dialog --title "$1"\
		 --yesno "Are you running in a virtual machine?"\
		 5 45; then
			 sel=$(dialog --nocancel --title "$1"\
				 --radiolist "Which hypervisor are you using\
				 components to install:" 10 50 3 \
				 vbox "Oracle VirtualBox" on \
				 vmware "VMware" off \
				 other "Something else" off \
				 3>&1 1>&2 2>&3 3>&-)
							  if echo -n "$sel" | grep -q vbox; then
								  vbox=true
							  elif echo -n "$sel" | grep -q utils; then
								  vmware=true
							  fi
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
	echo "$2" | dialog --title "IV. INSTALLING LINUX" --gauge "Installing $1" 7 70 0
	pacstrap /mnt/arch "$1" > /dev/null 2>&1
}

jo_fstab() {
	dialog --title "$1"\
		   --infobox "Generating fstab"\
		   3 28
	genfstab -U -p /mnt/arch > /mnt/arch/etc/fstab
	sleep 2
}

jo_arch_chroot() {
	arch-chroot /mnt/arch ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
	arch-chroot /mnt/arch hwclock --systohc
	arch-chroot /mnt/arch sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
	arch-chroot /mnt/arch locale-gen
	arch-chroot /mnt/arch echo "LANG=en_US.UTF-8" > /etc/locale.conf
	arch-chroot /mnt/arch echo "$hstnm" > /etc/hostname
	arch-chroot /mnt/arch echo "127.0.0.1 localhost" > /etc/hosts
	arch-chroot /mnt/arch echo "::1 localhost" >> /etc/hosts
	arch-chroot /mnt/arch echo "127.0.1.1 $hstnm.localdomain $hstnm" >> /etc/hosts
	arch-chroot /mnt/arch passwd <<JO_PWD
$rtpwd
$rtpwd
JO_PWD
	arch-chroot /mnt/arch systemctl enable NetworkManager
	arch-chroot /mnt/arch sed -i 's/#ForwardToSyslog=no/ForwardToSyslog=yes/' /etc/systemd/journald.conf
	if [ "$isusr" = true ]; then
		if [ "$isusrsudo" = true ]; then
			arch-chroot /mnt/arch useradd -m -g wheel -s /bin/"$usrshell" "$usr"
			arch-chroot /mnt/arch sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
		else
			arch-chroot /mnt/arch useradd -m -s /bin/"$usrshell" "$usr"
		fi
		arch-chroot /mnt/arch passwd "$usr" <<JO_USR_PWD
$usrpwd
$usrpwd
JO_USR_PWD
	fi
	if [ "$ltskern" = false ]; then
		arch-chroot /mnt/arch mkinitcpio -p linux
	else
		arch-chroot /mnt/arch mkinitcpio -p linux-lts
	fi
	if [ "$efimode" = true ]; then
		arch-chroot /mnt/arch grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi --recheck
		arch-chroot /mnt/arch mkdir -p /boot/grub
		arch-chroot /mnt/arch grub-mkconfig -o /boot/grub/grub.cfg
		arch-chroot /mnt/arch mkdir -p /boot/efi/EFI/BOOT
		arch-chroot /mnt/arch cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
		arch-chroot /mnt/arch echo "bcf boot add 1 fs0:\\EFI\\GRUB\\grubx64.efi \"GRUB bootloader\"" > /boot/efi/startup.nsh
		arch-chroot /mnt/arch echo "exit" >> /boot/efi/startup.nsh
	else
		arch-chroot /mnt/arch grub-install --target=i386-pc "$drv"
		arch-chroot /mnt/arch grub-mkconfig -o /boot/grub/grub.cfg
	fi
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
jo_pacstrap base 0
jo_pacstrap base-devel 5
jo_pacstrap pacman-contrib 10
jo_pacstrap networkmanager 15
jo_pacstrap syslog-ng 20
jo_pacstrap mtools 25
jo_pacstrap dostools 30
jo_pacstrap lsb-release 35
jo_pacstrap ntfs-3g 40
jo_pacstrap exfat-utils 45
jo_pacstrap ntp 50
jo_pacstrap os-prober 55
if [ "$efimode" = true ]; then
	jo_pacstrap efibootmgr 55
fi
jo_pacstrap grub 60
jo_pacstrap mkinitcpio 65
if [ "$ltskern" = true ]; then
	jo_pacstrap linux-lts 70
	jo_pacstrap linux-lts-headers 75
else
	jo_pacstrap linux 70
	jo_pacstrap linux-headers 75
fi
if [ "$intelamdcpu" = "intel" ]; then
	jo_pacstrap intel-ucode 80
elif [ "$intelamdcpu" = "amd" ]; then
	jo_pacstrap amd-ucode 80
fi
if [ "$isusr" = true ]; then
	if [ "$usrshell" = "zsh" ]; then
		jo_pacstrap zsh 95
	elif [ "$usrshell" = "dash" ]; then
		jo_pacstrap dash 95
	fi
fi
echo 100 | dialog --title "IV. INSTALLING LINUX"\
				  --gauge "Base packages installed"\
				  7 70 0
sleep 4
#==================================================================================================#
#--------------------------------------- UTILS DOWNLOAD -------------------------------------------#
#==================================================================================================#
if [ "$utils" = true ]; then
	jo_pacstrap zip 0
	jo_pacstrap unzip 11
	jo_pacstrap p7zip 22
	jo_pacstrap vim 33
	jo_pacstrap mc 44
	jo_pacstrap alsa-utils 55
	jo_pacstrap git 66
	jo_pacstrap cronie 77
	jo_pacstrap man 88
	echo 100 | dialog --title "IV. INSTALLING LINUX"\
					  --gauge "Utils installed"\
					  7 70 0
	sleep 4
fi
#==================================================================================================#
#---------------------------------------- EXTRA DOWNLOAD ------------------------------------------#
#==================================================================================================#
if [ "$extras" = true ]; then
	jo_pacstrap gst-plugins-base 0
	jo_pacstrap gst-plugins-good 8
	jo_pacstrap gst-plugins-bad 16
	jo_pacstrap gst-plugins-ugly 24
	jo_pacstrap gst-libav 32
	jo_pacstrap xorg-server 40
	jo_pacstrap xorg-xinit 48
	jo_pacstrap xorg-apps 56
	jo_pacstrap xf86-input-mouse 64
	jo_pacstrap xf86-input-keyboard 72
	jo_pacstrap xdg-user-dirs 80
	jo_pacstrap mesa 88
	if [ "$intelamdgpu" = "intel" ]; then
		jo_pacstrap xf86-video-intel 96
	elif [ "$intelamdgpu" = "amd" ]; then
		jo_pacstrap xf86-video-amdgpu 96
	fi
	echo 100 | dialog --title "IV. INSTALLING LINUX"\
					  --gauge "Extra packages installed"\
					  7 70 0
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
	   --infobox "Finishing configuration"\
	   3 30
jo_arch_chroot > /dev/null 2>&1
sleep 4
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
