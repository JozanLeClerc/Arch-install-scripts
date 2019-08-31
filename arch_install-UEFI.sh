#!/bin/bash

clear
echo "#============ WELCOME ============#"
echo "#                                 #"
echo "#        Welcome to Joe's         #"
echo "#           ARCH LINUX            #"
echo "#      UEFI INSTALL SCRIPT        #"
echo "#                                 #"
echo "#   (press any key to begin...)   #"
echo "#                                 #"
echo "#=================================#"
read
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
if [[ $answr != y && $answr != Y && $answr != yes && $answr != Yes ]]; then
				echo "Thank you for using Joe's Arch Linux UEFI install scritpt."
				sleep 1
				echo "Aborting..."
				sleep 3
				clear
				exit
fi
echo "tasseur"
