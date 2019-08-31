#!/bin/bash

answr=""
drvnm=""
rts=""
swps=""
rtpwd=""
rtrtpwd="walk"
usrpwd=""
usrusrpwd="fade"

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
				clear
				echo "#========= I. DISK SETUP =========#"
				echo "#                                 #"
				echo "#      Please choose wisely       #"
				echo "#      1. Drive to be used        #"
				echo "#                                 #"
				echo "#=================================#"
				while [[ $drvnm == "" ]]; do
								echo && echo
								echo "Please enter letter of the drive on which Arch Linux should be installed:"
								echo "/dev/sd_"
								echo -n "~> "
								read -n 1 drvnm
				done
				clear
				echo "#========= I. DISK SETUP =========#"
				echo "#                                 #"
				echo "#      Please choose wisely       #"
				echo "#      2. swap partion size       #"
				echo "#                                 #"
				echo "#=================================#"
				while [[ $swps == "" ]]; do
								echo && echo
								echo "Please enter your swap partition disired size:"
								echo "_G"
								echo -n "~> "
								read swps
				done
				clear
				echo "#========= I. DISK SETUP =========#"
				echo "#                                 #"
				echo "#      Please choose wisely       #"
				echo "#      3. root partion size       #"
				echo "#                                 #"
				echo "#=================================#"
				while [[ $rts == "" ]]; do
								echo && echo
								echo "Please enter your root partition disired size:"
								echo "__G"
								echo -n "~> "
								read rts
				done

				drv="/dev/sd$drvnm"
				btsze="128M"
				rtsze=$rts"G"
				swpsze=$swps"G"

				clear
				echo "#=========================== CONFIRM THIS IS EXACT ==============================#" 
				echo "#                                                                                #"
				echo "#                            DRIVE TO USE: $drv                              #"
				echo "#                                                                                #"
				echo "#  /boot/efi > BOOT partiton size > $btsze      / > ROOT partition size > $rtsze      #"
				echo "#  SWAP partiton size > $swpsze        /home > HOME partition size > all that remains #"
				echo "#                                                                                #"
				echo "#================================================================================#" 
				echo && echo
				echo "Is that correct? [y/N]"
				echo -n "~> "
				read answr
				if [[ $answr != y && $answr != Y && $answr != yes && $answr != Yes && $answr != YES ]]; then
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
				echo -n "~> "
				read -s rtpwd
				echo && echo
				echo "Confirm root password:"
				echo -n "~> "
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
echo "#          2. user add            #"
echo "#                                 #"
echo "#=================================#"
echo && echo
echo "Would you like to add a user to the system? [y/N]"
echo -n "~> " 
read answr
if [[ $answr == y || $answr == Y || $answr == yes || $answr == Yes || $answr == YES ]]; then
				echo && echo
				echo "Enter your desired username:"
				echo -n "~> "
				read usr
				echo && echo
				while [[ $usrusrpwd != $usrpwd || $usrpwd == "" ]]; do
								echo "Enter your disired password for $usr (can't be empty):"
								echo -n "~> "
								read -s usrpwd
								echo && echo
								echo "Confirm user password:"
								echo -n "~> "
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



#timedatectl set-ntp true

# ================================================================================================ #
# ===================================== PARTITIONING DISK ======================================== #
# ================================================================================================ #

#echo "2048, $btsze, , *" | sfdisk $drv
