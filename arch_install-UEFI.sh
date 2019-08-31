#!/bin/bash

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
echo "Verifying your are connected to the Internet, please wait..."
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
				echo "Press [retrun] key to continue"
				read
fi
clear
echo "#========= I. DISK SETUP =========#"
echo "#                                 #"
echo "#      Please choose wisely       #"
echo "#      1. Drive to be used        #"
echo "#                                 #"
echo "#=================================#"
echo && echo
echo "Please enter letter of the drive on which Arch Linux should be installed:"
echo "~> /dev/sd_"
read drivenum
drive="/dev/sd$drivenum"
clear
echo "#========= I. DISK SETUP =========#"
echo "#                                 #"
echo "#      Please choose wisely       #"
echo "#      2. swap partion size       #"
echo "#                                 #"
echo "#=================================#"
echo && echo
echo "Please enter your swap partition disired size:"
echo "~> _G"
read swps
clear
echo "#========= I. DISK SETUP =========#"
echo "#                                 #"
echo "#      Please choose wisely       #"
echo "#      3. root partion size       #"
echo "#                                 #"
echo "#=================================#"
echo && echo
echo "Please enter your root partition disired size:"
echo "~> __G"
read rts
rtsze=$rts"G"
swpsze=$swps"G"
btsze="128M"
clear
echo "#=========================== CONFIRM THIS IS EXACT ==============================#" 
echo "#                                                                                #"
echo "#                            DRIVE TO USE: $drive                              #"
echo "#                                                                                #"
echo "#      BOOT partiton size > $btsze     ROOT partition size > $rtsze                   #"
echo "#      SWAP partiton size > $swpsze       HOME partition size > all that remains      #"
echo "#                                                                                #"
echo "#================================================================================#" 
echo && echo
echo "Is that correct?"
echo "~> [y/n]"
read answr
if [[ $answr != y && $answr != Y && $answr != yes && $answr != Yes && $answr != YES ]]; then
				echo "Aborting..."
				sleep 3
				clear
				exit
fi
echo "tasseur"
