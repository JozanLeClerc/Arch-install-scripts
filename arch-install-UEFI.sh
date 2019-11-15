#!/bin/sh

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
did=""

clear
echo "#============ WELCOME ============#"
echo "#                                 #"
echo "#        Welcome to Joe's         #"
echo "#           ARCH LINUX            #"
echo "#      UEFI INSTALL SCRIPT        #"
echo "#                                 #"
echo "#  (press [return] to begin...)   #"
echo "#                                 #"
echo "#=================================#"
read

# ================================================================================================ #
# ======================================== ERRORS CHECK ========================================== #
# ================================================================================================ #

if [ ! -r /sys/firmware/efi/efivars ]; then
				clear
				echo "X=X=X=X=X=X=X ERROR X=X=X=X=X=X=X=X"
				echo "X                                 X"
				echo "X    It seems that boot mode      X"
				echo "X      is not set to UEFI         X"
				echo "X    therefore Joe's script is    X"
				echo "X        forced to abort          X"
				echo "X                                 X"
				echo "X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X"
				sleep 6
				echo && echo
				echo "Thank you for using Joe's Arch Linux UEFI install scritpt."
				sleep 1
				echo "Aborting..."
				sleep 3
				clear
				exit
fi
clear
echo "Verifying that your are connected to the Internet, please wait..."
wget -q --spider https://google.com
if [ ! $? -eq 0 ]; then
				clear
				echo "X=X=X=X=X=X=X ERROR X=X=X=X=X=X=X=X"
				echo "X                                 X"
				echo "X       It seems that your        X"
				echo "X         terminal is not         X"
				echo "X    connected to the Internet    X"
				echo "X    therefore Joe's script is    X"
				echo "X        forced to abort          X"
				echo "X                                 X"
				echo "X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X=X"
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
				read
fi

# ================================================================================================ #
# ========================================= DISK SETUP =========================================== #
# ================================================================================================ #

while [[ $answr != y && $answr != Y && $answr != yes && $answr != Yes && $answr != YES ]]; do
				drvnm=""
				swps=""
				rts=""
				clear
				echo "#========= I. DISK SETUP =========#"
				echo "#                                 #"
				echo "#      Please choose wisely       #"
				echo "#                                 #"
				echo "#      1. Drive to be used        #"
				echo "#                                 #"
				echo "#=================================#"
 				while [[ $drvnm == "" || $drvnm -gt $(lsblk | grep disk | wc -l) || $drvnm -le 0 ]]; do
					echo && echo
					dn=$(lsblk | grep disk | wc -l)
					id=1
					lsblk
					echo && echo
					echo "Please choose the drive on which Arch Linux shoud be installed:"
					while [[ $dn != 0 ]]; do
						echo "$id. $(lsblk | grep disk | awk '{print $1}' | sed -n "$id"p)"
						((dn--))
						((id++))
					done
					echo -n "> "
					read drvnm
					if [[ $drvnm == "" ]]; then
						echo && echo
						echo "Can't be empty, retrying..."
					fi
					if [[ $drvnm > $(lsblk | grep disk | wc -l) ]]; then
						echo && echo
						echo "Illegal value, please choose something reasonable. Reatrying..."
					fi
					if [[ $drvnm < 0 ]]; then
						echo && echo
						echo "Illegal value, please choose something reasonable. Reatrying..."
					fi
					if [[ $drvnm == 0 ]]; then
						echo && echo
						echo "Illegal value, please choose something reasonable. Reatrying..."
					fi
				done
				drv="/dev/"$(lsblk | grep disk | awk '{print $1}' | sed -n "$drvnm"p)
				clear
				echo "#========= I. DISK SETUP =========#"
				echo "#                                 #"
				echo "#      Please choose wisely       #"
				echo "#                                 #"
				echo "#      2. swap partion size       #"
				echo "#                                 #"
				echo "#=================================#"
				while [[ $swps == "" ]]; do
								echo && echo
								echo "Please enter your swap partition disired size:"
								echo "_G"
								echo -n "> "
								read swps
								if [[ $swps == "" ]]; then
												echo && echo
												echo "Can't be empty, retrying..."
								fi
				done
				clear
				echo "#========= I. DISK SETUP =========#"
				echo "#                                 #"
				echo "#      Please choose wisely       #"
				echo "#                                 #"
				echo "#      3. root partion size       #"
				echo "#                                 #"
				echo "#=================================#"
				while [[ $rts == "" ]]; do
								echo && echo
								echo "Please enter your root partition disired size:"
								echo "__G"
								echo -n "> "
								read rts
								if [[ $rts == "" ]]; then
												echo && echo
												echo "Can't be empty, retrying..."
								fi
				done
				btsze="128M"
				rtsze=$rts"G"
				swpsze=$swps"G"
				clear
				echo "#============= CONFIRM THIS IS CORRECT ===============#" 
				echo "#                                                     #"
				echo "#                DRIVE TO USE: $drv               #"
				echo "#                                                     #"
				echo "#  /boot/efi > BOOT partition size: $btsze              #"
				echo "#              SWAP partition size: $swpsze                #"
				echo "#  /         > ROOT partition size: $rtsze               #"
				echo "#  /home     > HOME partition size: all that remains  #"
				echo "#                                                     #"
				echo "#=====================================================#" 
				echo && echo
				echo "Is that correct? [y/N]"
				echo -n "> "
				read answr
				if [[ $answr != y && $answr != Y && $answr != yes && $answr != Yes && $answr != YES ]]; then
								echo && echo
								echo "Retrying..."
								echo
								echo "Press [retrun] key to continue"
								read
				fi
done

# ================================================================================================ #
# ========================================= USERS SETUP ========================================== #
# ================================================================================================ #

answr="n"

while [[ $rtrtpwd != $rtpwd || $rtpwd == "" ]]; do
				clear
				echo "#======= II. USERS SETUP =========#"
				echo "#                                 #"
				echo "#        1. root password         #"
				echo "#                                 #"
				echo "#=================================#"
				echo && echo
				echo "Enter your disired root password (can't be empty):"
				echo -n "> "
				read -s rtpwd
				echo && echo
				echo "Confirm root password:"
				echo -n "> "
				read -s rtrtpwd
				if [[ $rtrtpwd != $rtpwd ]]; then
								echo && echo
								echo "Password mismatch, retrying..."
								sleep 2
				fi
				if [[ $rtpwd == "" ]]; then
								echo && echo
								echo "Password is empty, retrying..."
								sleep 2
				fi
done

clear
echo "#======= II. USERS SETUP =========#"
echo "#                                 #"
echo "#          2. User add            #"
echo "#                                 #"
echo "#=================================#"
echo && echo
echo "Would you like to add a user to the system? [y/N]"
echo -n "> " 
read answr
if [[ $answr == y || $answr == Y || $answr == yes || $answr == Yes || $answr == YES ]]; then
				echo && echo
				echo "Enter your desired username:"
				echo -n "> "
				read usr
				isusr="true"
				usr=$(echo $usr | tr '[:upper:]' '[:lower:]')
				echo && echo
				while [[ $usrusrpwd != $usrpwd || $usrpwd == "" ]]; do
								echo "Enter your disired password for $usr (can't be empty):"
								echo -n "> "
								read -s usrpwd
								echo && echo
								echo "Confirm user password:"
								echo -n "> "
								read -s usrusrpwd
								if [[ $usrusrpwd != $usrpwd ]]; then
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
echo "#======= II. USERS SETUP =========#"
echo "#                                 #"
echo "#          3. hostname            #"
echo "#                                 #"
echo "#=================================#"
while [[ $hstnm == "" ]]; do
				echo && echo
				echo "Enter your disired hostname for this terminal (can't be empty):"
				echo -n "> "
				read hstnm
				if [[ $hstnm == "" ]]; then
								echo && echo
								echo "Hostname is empty, retrying..."
								sleep 2
				fi
done
answr="n"
clear
echo "#====== III. EXTRAS SETUP ========#"
echo "#                                 #"
echo "#            1. More              #"
echo "#                                 #"
echo "#=================================#"
echo && echo
echo "Do you wish to install Xorg and gst-plugins as well? [y/N]"
echo -n "> "
read answr
if [[ $answr == y || $answr == Y || $answr == yes || $answr == Yes || $answr == YES ]]; then
				somemore="true"
fi
clear
answr=""
if [[ $(lscpu | grep Intel) ]]; then
	intelamdcpu="intel"
fi
if [[ $(lscpu | grep AMD) ]]; then
	intelamdcpu="amd"
fi
if [[ $(lspci | grep Intel) ]]; then
	intelamdgpu="intel"
fi
if [[ $(lspci | grep AMD) ]]; then
	intelamdgpu="amd"
fi

# ================================================================================================ #
# ===================================== THE ACTUAL INSTALL ======================================= #
# ================================================================================================ #


# ============================================================== #
# ========================== NTP DATE ========================== #
# ============================================================== #


clear
echo "#====== IV. INSTALLING LINUX =====#"
echo "#                                 #"
echo "#        1. Setting date          #"
echo "#             via ntp             #"
echo "#                                 #"
echo "#=================================#"
timedatectl set-ntp true
sleep 2

# ============================================================== #
# ==================== PARTITIONING DISK ======================= #
# ============================================================== #


clear
echo "#====== IV. INSTALLING LINUX =====#"
echo "#                                 #"
echo "#        2. Partitionning         #"
echo "#          disk $drv          #"
echo "#                                 #"
echo "#=================================#"
echo && echo
dd if=/dev/zero of=$drv bs=512 count=1
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $drv
g	# create a new GPT partition table
n	# new partition (/dev/sdx1)
1	# partition number 1
	# first sector (2048)
+$btsze	# boot size partition
Y	# YES
n	# new partition (/dev/sdx2)
2	# partition number 2
	# default start block
+$swpsze	# swap size partition
Y	# YES
n	# new partition (/dev/sdx3)
3	# partition number 3
	# default start block
+$rtsze	# root size partition
Y	# YES
n	# new partition (/dev/sdx4)
4	# partition number 4
	# default start block
	#	all that remains
t	# change partition type
1	# part 1
1	# EFI partition type
t	# change partition type
2	# partition number 2
19	# swap partition type
w	# write the partition table and quit
EOF
mkswap $drv"2"
mkfs.fat -F32 $drv"1"
mkfs.ext4 $drv"3"
mkfs.ext4 $drv"4"
sleep 2
clear
echo "#====== IV. INSTALLING LINUX =====#"
echo "#                                 #"
echo "#     3. Mounting partitions      #"
echo "#                                 #"
echo "#=================================#"
swapon $drv"2"
mkdir /mnt/arch
mount $drv"3" /mnt/arch
mkdir /mnt/arch/boot
mkdir /mnt/arch/boot/efi
mount $drv"1" /mnt/arch/boot/efi
mkdir /mnt/arch/home
mount $drv"4" /mnt/arch/home
sleep 2
clear
echo "#====== IV. INSTALLING LINUX =====#"
echo "#                                 #"
echo "#    4. Installing base system    #"
echo "#                                 #"
echo "#=================================#"
pacstrap /mnt/arch base base-devel pacman-contrib
sleep 1
clear
echo "#====== IV. INSTALLING LINUX =====#"
echo "#                                 #"
echo "#   4.5 Installing some extras    #"
echo "#                                 #"
echo "#=================================#"
pacstrap /mnt/arch zip unzip p7zip vim mc alsa-utils syslog-ng mtools dostools lsb-release ntfs-3g exfat-utils git zsh
pacstrap /mnt/arch ntp cronie
pacstrap /mnt/arch grub os-prober efibootmgr
sleep 1
clear
echo "#====== IV. INSTALLING LINUX =====#"
echo "#                                 #"
echo "#       5. Generating fstab       #"
echo "#                                 #"
echo "#=================================#"
genfstab -U /mnt/arch > /mnt/arch/etc/fstab
sleep 2
clear
echo "#====== V. CONFIGURING LINUX =====#"
echo "#                                 #"
echo "#      1. Now changing root       #"
echo "#                                 #"
echo "#=================================#"
sleep 2
sed -e 's/\s*\([\+0-9a-zA-Z \"=#()[]{}<>,:. - \_\/?!@$%^&~`*|]*\).*/\1/' << EOF | arch-chroot /mnt/arch
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
	sed 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen > /etc/locale.gen.42
	mv /etc/locale.gen.42 /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#       5. Setting hostname       #
	#                                 #
	#=================================#
	echo $hstnm > /etc/hostname
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
EOF
sed -e 's/\s*\([\+0-9a-zA-Z \"=#()[]{}<>,:. - \_\/?!@$%^&~`*|]*\).*/\1/' << EOF | arch-chroot /mnt/arch
	systemctl enable NetworkManager
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#        8. journald stuff        #
	#                                 #
	#=================================#
	sed 's/#ForwardToSyslog=no/ForwardToSyslog=yes/' /etc/systemd/journald.conf > /etc/systemd/journald.conf.42
	mv /etc/systemd/journald.conf.42 /etc/systemd/journald.conf
	sleep 2
EOF
if [[ $somemore == "true" ]]; then
	sed -e 's/\s*\([\+0-9a-zA-Z \"=#()[]{}<>,:. - \_\/?!@$%^&~`*|]*\).*/\1/' << EOF | arch-chroot /mnt/arch
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
EOF
fi
if [[ $intelamdgpu == "intel" && $somemore == "true" ]]; then
	sed -e 's/\s*\([\+0-9a-zA-Z \"=#()[]{}<>,:. - \_\/?!@$%^&~`*|]*\).*/\1/' << EOF | arch-chroot /mnt/arch
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
	sleep 2
EOF
fi
if [[ $intelamdgpu == "amd" && $somemore == "true" ]]; then
	sed -e 's/\s*\([\+0-9a-zA-Z \"=#()[]{}<>,:. - \_\/?!@$%^&~`*|]*\).*/\1/' << EOF | arch-chroot /mnt/arch
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
EOF
fi
if [[ $isusr == "true" ]]; then
	sed -e 's/\s*\([\+0-9a-zA-Z \"=#()[]{}<>,:. - \_\/?!@$%^&~`*|]*\).*/\1/' << EOF | arch-chroot /mnt/arch
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#      10. Installing sudo        #
	#                                 #
	#=================================#
	pacman -S sudo
	Y
EOF
sed -e 's/\s*\([\+0-9a-zA-Z \"=#()[]{}<>,:. - \_\/?!@$%^&~`*|]*\).*/\1/' << EOF | arch-chroot /mnt/arch
	sleep 2
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#      11. Generating user        #
	#                                 #
	#=================================#
	useradd -m -g wheel -s /bin/zsh $usr
	passwd $usr
$usrpwd
$usrpwd
	sed 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers > /etc/sudoers.42
	mv /etc/sudoers.42 /etc/sudoers
	sleep 2
	exit
EOF
fi
if [[ $intelamdcpu == "intel" ]]; then
	sed -e 's/\s*\([\+0-9a-zA-Z \"=#()[]{}<>,:. - \_\/?!@$%^&~`*|]*\).*/\1/' << EOF | arch-chroot /mnt/arch
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#      12. Installing CPU         #
	#           microcode             #
	#                                 #
	#=================================#
	pacman -S intel-ucode
	Y
EOF
fi
if [[ $intelamdcpu == "amd" ]]; then
	sed -e 's/\s*\([\+0-9a-zA-Z \"=#()[]{}<>,:. - \_\/?!@$%^&~`*|]*\).*/\1/' << EOF | arch-chroot /mnt/arch
	clear
	#===== V. CONFIGURING LINUX ======#
	#                                 #
	#      12. Installing CPU         #
	#           microcode             #
	#                                 #
	#=================================#
	pacman -S amd-ucode
	Y
EOF
fi
sed -e 's/\s*\([\+0-9a-zA-Z \"=#()[]{}<>,:. - \_\/?!@$%^&~`*|]*\).*/\1/' << EOF | arch-chroot /mnt/arch
	sleep 2
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
EOF
echo && echo
clear
echo "#========= WORK COMPLETE =========#"
echo "#                                 #"
echo "#     Your system should now      #"
echo "#         be installed.           #"
echo "#   Thank your for using Joe's    #"
echo "#           ARCH LINUX            #"
echo "#      UEFI INSTALL UTILITY       #"
echo "#                                 #"
echo "#   Your system will now reboot   #"
echo "#                                 #"
echo "#=================================#"
echo && echo
sleep 10
umount -R /mnt/arch
reboot
