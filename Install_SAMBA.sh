#/bin/sh
err_catch() {
   echo "une erreur à été détectée, nettoyage en cours "
   rmdir $CheminComplet
   userdel $NomUtilisateur
   groupedel $NomGroupe
   rm /etc/samba/smb.conf
   mv /etc/samba/smb.conf.bck /etc/samba/smb.conf
   exit 1
}

# Initialisation variable
ip4=$(ip addr show ens18 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

# Update & installation de SAMBA
apt_samba() {
   sudo apt update
   sudo apt install -y samba
   sudo systemctl enable smbd
   cp /etc/samba/smb.conf /etc/samba/smb.conf.bck
}

# Création d'un partage SAMBA
clear
read -p "Besoin d'installer Samba ? : (Y/N)" InstallSamba
read -p "Entrer le nom du partage samba : " NomPartage
read -p "Entrez un nom pour le nouvel utilisateur : " NomUtilisateur
read -p "Entrez un nom pour le groupe associé au partage : " NomGroupe
read -p "Quel est le chemin du partage : " CheminComplet

if (InstallSamba=Y); then
   apt_samba
fi
# Création du dossier partagé
clear
echo "step 1"
mkdir $CheminComplet
echo "Dossier créé"

# Création de l'utilisateur et asignation au groupe (système + samba)
echo "step 2"
useradd $NomUtilisateur
passwd $NomUtilisateur
smbpasswd -a $NomUtilisateur
echo "Utilisateur créé"

# Création du groupe
echo "step 3"
groupadd $NomGroupe
gpasswd -a $NomUtilisateur $NomGroupe
echo "Groupe créé"

# permissions
echo "step 4"
chgrp -R $NomGroupe $CheminComplet
chmod -R g+rw $CheminComplet
echo "Permissions appliquées"

# Création et import de la configuration SAMBA
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

# Fin du script
echo "L'opération est terminée !!"
echo "Le partage est disponible à l'adresse $ip4 sous le nom $NomPartage"
