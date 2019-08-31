#!/bin/bash

echo "#============ WELCOME ============#"
echo "#                                 #"
echo "#        Welcome to Joe's         #"
echo "#           ARCH LINUX            #"
echo "#      UEFI INSTALL SCRIPT        #"
echo "#                                 #"
echo "#=================================#"
echo
echo
echo
echo "Please enter letter of the drive on which Arch Linux should be installed:"
echo "~> /dev/sd_"
read drivenum
drive="/dev/sd$drivenum"
echo $drive
echo
echo "Please enter your swap partition disired size:"
echo "~> _G"
read swps
echo
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
echo "#      BOOT partiton size > $btsze                  ROOT partition size > $rtsze      #"
echo "#      SWAP partiton size > $swpsze       HOME partition size > all that remains      #"
echo "#                                                                                #"
echo "#================================================================================#" 
echo "Is that correct?"
echo "~> [y/n]"
read answr
if [ $answr -eq "y" ] then
				echo "aborting"
fi
