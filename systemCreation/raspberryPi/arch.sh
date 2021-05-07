#!/bin/sh

error(){
	echo "Error: $@"
	exit 1
}

# Installing dialog
pacman --noconfirm --needed -S dialog || error "Make sure to run this script as root and with an internet connection."

dialog --title "Installing..." --infobox "Installing wget and dofstools (for FAT filesystem creation) needed for the installation" 0 0

pacman --noconfirm --needed -S wget || error "Couldn't install wget, try maybe refreshing keyrings or updating the system"

pacman --noconfirm --needed -S dosfstools || error "Couldn't install dofstools needed for creating FAT file system, try maybe refreshing keyrings or updating the system"

# Making sure the user knows what they're doing
dialog --title "LET'S GO!" --yesno "With dialog installed we're are ready to take this script for a spin. Please, DO NOT run it unless you fully understand the risk! This was developed by me for me only, and as such there might be errors that worst case could wipe entire drives. You sure you want to continue?" 10 60 || error "User exited"

installDrive="$(dialog --title "Select a drive" --no-items --menu "Which drive do you want the installation to procced on?" 0 0 0 $( for drive in $(lsblk -dno NAME); do echo /dev/"$drive"; done) 3>&2 2>&1 1>&3 || error "User exited" )"

sourceUrl="$(dialog --title "Raspberry pi model" --menu "Which model of the raspberry pi do you want to install arch on?" 0 0 0 \
	"http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz" "Raspberry pi zero" \
	"http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-4-latest.tar.gz" "Raspberry pi 4" \
	3>&1 1>&2 2>&3 3>&1 )"

dialog --title "WARNING!" --defaultno --yes-label "NUKE IT!" --no-label "Please don't..." --yesno "This script is readying to NUKE $installDrive. ARE YOU SURE YOU WANT TO CONTINUE?"  10 60 || error "User apparently didn't wan't to massacre $installDrive"

dialog --title "Disk" --infobox "Partitioning the drives and creating the file systems" 0 0

# Creating the needed partitions
sed "s/\s*\#.*$//" <<-EOF | sfdisk $installDrive
label: dos	# Setting the disklabel to dos
,200M,c;	# Creating a 200 MB new partition of the type W95 FAT32 (LBA) (boot partition)
;			# Creating a partition to fill the rest of the disk (root partition)
EOF

# Creating the file systems
yes | mkfs.fat -F32 ${installDrive}1
yes | mkfs.ext4 ${installDrive}2

# Entering a temporary directory for mounting drive and adding trap for cleanup
tempDir=$(mktemp -d)
trap "rm -rf $tempDir" INT TERM EXIT
cd $tempDir

# Creating the folders for mounting the drive
mkdir root boot

# Mounting the drive
mount ${installDrive}1 ./boot
mount ${installDrive}2 ./root

wget "$sourceUrl"
bsdtar -xpf *.tar.gz -C root
sync

# Move the boot files to the boot partition from the root partition
mv ./root/boot/* ./boot

# Un-mounting the drives
umount ./boot ./root
