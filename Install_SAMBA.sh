#/bin/sh

# Update & installation de SAMBA
sudo apt update
sudo apt install -y samba
sudo systemctl enable smbd

# Création d'un partage SAMBA
clear
read -p "Entrer le nom du partage samba" NomPartage
read -p "Entrez un nom pour le nouvel utilisateur" NomUtilisateur
read -p "Entrez un nom pour le groupe associé au partage" NomGroupe
read -p "Quel est le chemin du partage" CheminComplet

# Création du dossier partagé
clear
echo "step 1"

# Création de l'utilisateur et asignation au groupe (système + samba)
echo "step 2"
useradd $NomUtilisateur
smbpasswd -a $NomUtilisateur

# Création du groupe
echo "step 3"
groupadd $NomGroupe
gpasswd -a $NomUtilisateur $NomGroupe

# permissions
echo "step 4"
chgrp -R $NomGroupe $CheminComplet
chmod -R g+rw $CheminComplet

# Création et import de la configuration SAMBA
echo "step 5"
tee -a /etc/samba/smb.conf << END
[$NomPartage]
   comment = Partage de données
   path = $CheminComplet
   guest ok = no
   read only = no
   browseable = yes
   valid users = $NomGroupe
END
sudo systemctl restart smbd

# Fin du script
echo "L'opération est terminée !!"
echo "Le partage est disponible à l'adresse \\\\$IP\\\\$NomPartage" 