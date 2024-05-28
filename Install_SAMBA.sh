#/bin/sh
# Cleaning task if an error is detected
err_catch() {
   echo "An error has been detected, cleanning task ..."
   rmdir $CheminComplet
   deluser $NomUtilisateur
   delgroup $NomGroupe
   rm /etc/samba/smb.conf
   mv /etc/samba/smb.conf.bck /etc/samba/smb.conf
   echo "the cleaning tasks has been completed, end of the script !!!!"
   exit 1
}
trap 'err_catch' ERR

# Variable init
ip4=$(ip addr show ens18 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

# Update the host and install SAMBA
apt_samba() {
   sudo apt update
   sudo apt install -y samba
   sudo systemctl enable smbd
   cp /etc/samba/smb.conf /etc/samba/smb.conf.bck
}

# User prompt
clear
read -p "Need to install SAMBA ? (Y/N) : " InstallSamba
read -p "Name of the samba Share : " NomPartage
read -p "Name of the user linked to the share : " NomUtilisateur
read -p "Name of the group linked to the share : " NomGroupe
read -p "Path of the share : " CheminComplet

# Check if the script need to update the host and install samba
if (InstallSamba="Y"); then
   apt_samba
fi

# Création du dossier partagé
clear
echo "step 1"
mkdir $CheminComplet
echo "The Folder has been created"

# User creation on the machine and SAMBA then adding it to the SAMBA group
echo "step 2"
useradd $NomUtilisateur
passwd $NomUtilisateur
smbpasswd -a $NomUtilisateur
echo "The user has been created"

# Group creation
echo "step 3"
groupadd $NomGroupe
gpasswd -a $NomUtilisateur $NomGroupe
echo "The group has been created"

# Set the permissions
echo "step 4"
chgrp -R $NomGroupe $CheminComplet
chmod -R g+rw $CheminComplet
echo "The right has been set"

# SAMBA configuration
echo "step 5"
tee -a /etc/samba/smb.conf <<END
[$NomPartage]
   comment = Partage de données
   path = $CheminComplet
   guest ok = no
   read only = no
   browseable = yes
   valid users = @$NomGroupe
END
sudo systemctl restart smbd

# End of the script
echo "The share is now online !!"
echo "the share is now available on windows here \\\\$ip4\\$NomPartage"