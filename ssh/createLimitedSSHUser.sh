#!/bin/sh

# Install dialog, needed for user input
pacman --noconfirm --needed -S dialog || { echo "Make sure to run this script as root and with an internet connection."; exit 1; }

# Installing OpenSSH
dialog --title "OpenSSH" --infobox "Making sure OpenSSH is installed and enabling the ssh server" 0 0
pacman --noconfirm --needed -S openssh
systemctl enable sshd

# Enter a username for the limited user
username="$(dialog --no-cancel --inputbox "Enter username for the new user" 12 65 3>&1 1>&2 2>&3 3>&1)"

# Making sure the username doesn't contain illegal characthers
while [ "$(expr "$username" : ^[a-z][-a-z0-9]*\$)" = 0 ]
do
	username="$(dialog --no-cancel --inputbox "The username contained illegal characthers. It should start with lower case letters and only contain lower case letters and numbers, fitting the following regex: : ^[a-z][-a-z0-9]*\\$ " 14 70 3>&1 1>&2 2>&3 3>&1)"
done

# Creating the user with or without an expiry date based on whether the user inputs a date or cancels
expiredate="$(dialog --date-format "%Y-%m-%d" --title "Expire date" --cancel-label "Don't set one" --calendar "It is strongly recommended to set a date for automatic expiration of the user. When should that happen?" 0 0 1 1 2020 3>&1 1>&2 2>&3 3>&1)" && useradd "$username" -M -U -s /bin/false -e "$expiredate" || useradd "$username" -M -U -s /bin/false

# Getting a passphrase for the newly generated ssh key
sshkeysPassphrase="$(dialog --no-cancel --inputbox "Enter a passphrase for the new private ssh key" 12 65 3>&1 1>&2 2>&3 3>&1)"

# Creating directory for hosting the limited users ssh keys
mkdir -p /home/noHome/.ssh/

# Change the owner to the new user of the .ssh folder
chown "${username}:${username}" -R /home/noHome/

# Generate the private and public key
sudo -u "$username" ssh-keygen -N "$sshkeysPassphrase" -t rsa -f /home/noHome/.ssh/id_rsa

# Copy the newly created public key, to act as a public key for the ssh server that you can login with
sudo -u "$username" cp /home/noHome/.ssh/id_rsa.pub /home/noHome/.ssh/authorized_keys

# Move the newly generated private and public key to the root of filesystem so they're ready for export
mv /home/noHome/.ssh/id_rsa /id_rsa
mv /home/noHome/.ssh/id_rsa.pub /id_rsa.pub

# Add just a couple of options to the rsa public key, to make sure that it isn't going to be missused
# echo "no-pty,no-X11-forwarding,permitopen='localhost:2222',command=/bin/true $(cat /home/noHome/.ssh/authorized_keys)" > /home/noHome/.ssh/authorized_keys

# Last but not least, make sure the permissions is set right, and that the immutable bit is set to prevent tampering with the keys
chmod 700 /home/noHome/.ssh/
chmod 600 /home/noHome/.ssh/authorized_keys
#The immutable bit preventing anyone without root to write or change the file/directory
chattr +i /home/noHome/.ssh/authorized_keys
chattr +i /home/noHome/.ssh

# Now alls that is left is to change the default sshd config file. This is done by changing the field with "[username]" in my custom sshd template to the username give using dialog before and using that to overwrite the current sshd_config file
sed "s/\[username\]/$username/g" >> /etc/ssh/sshd_config < ./SSHDLimitedUserConfigTemplate

dialog --title "Done!" --msgbox "The script is now done. The only thing left to do is to export the newly generated ssh keys (found at /) and reboot to make sure everything works as expected" 0 0
