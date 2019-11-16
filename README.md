# README in progress

# Arch Linux installation script

## Introduction

My original script meant to automize you Arch Linux installation process. This is **work in progress**, so it will not work properly for now. I am currently struggling with **GRUB**, with little surprise.

While the script simplifies the whole installation process, this is not meant for new users. It is meant for users that already performed **Arch Linux** installations and more or less understand what's going on. It's always best to learn Arch by yourself.

Does not install too many bloatware other than some utils. You will be prompted to choose whether or not you want `Xorg` and other classic desktop user extras.

## How to use

First make sure you are booted in a live **Arch ISO environment**, with the familiar prompt waiting for instructions.

Secondly, you will require a working internet connection. To **try your connection** use:

```shell
ping -c4 archlinux.org
```

If it fails, refer to [the Arch Wiki installation guide](https://wiki.archlinux.org/index.php/Installation_guide#Connect_to_the_internet) to get an internet connection working.

Now you are ready to run the script. Run **the following commands** to begin setup and installation:

```shell
wget https://raw.githubusercontenent.com/JozanLeClerc/arch-install-scripts/master/arch-install-UEFI.sh
chmod +x arch-install-UEFI.sh
./arch-install-UEFI.sh
```

## Disclaimers

First, only **UEFI-type installation** is supported at the moment. **BIOS version** soon to come.

While there is some basic error managements, **do not** try to break the script by inputting deliberately harmful stuff when prompted. As an **Arch Linux** installation can be complex and sensitive, it will most certainly work. This is meant to ease your life, it is not a skill test.

Do **NOT** run this on your already installed machine. It is meant to be used only in the live **Arch ISO environment** and your intention must be to install **Arch Linux** on the system.

The scripr **does not** handle **dual boot** on a **single disk**, while you should be fine with an already installed OS on another disk.  
It does not handle dual disk partitioning as well.

## TODO

`sed -i`

## More

Don't hesitate to contact me or create a pull request in case of bugs, typos, cool suggestions...