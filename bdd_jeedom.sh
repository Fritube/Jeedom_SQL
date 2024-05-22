#!/bin/bash

# Vérifier si l'utilisateur a les droits d'administration
if [ "$(id -u)" -ne 0 ]; then
  echo "Ce script doit être exécuté avec les privilèges d'administration (utilisez sudo)." 1>&2
  exit 1
fi

# Vérifier si UFW est déjà installé
if [ -x "$(command -v ufw)" ]; then
  echo "UFW est déjà installé sur ce système."
else
    # Installation de ufw
    echo "Installation du paquet UFW..."
    apt-get update
    apt-get install -y ufw
    # Vérifier si l'installation a réussi
    if [ $? -eq 0 ]; then
        echo "UFW a été installé avec succès."
    else
        echo "Une erreur s'est produite lors de l'installation de UFW."
        exit 1
    fi
fi


# Modifier le fichier de configuration de MariaDB
MARIA_CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
if [ ! -f "$MARIA_CONF" ]; then
  echo "Le fichier de configuration $MARIA_CONF n'existe pas." 1>&2
  exit 1
fi
line_number=30
echo "Modification du fichier de configuration $MARIA_CONF..."
sed -i "${line_number}d" "$MARIA_CONF"

# Vérifier si la modification a réussi
if [ $? -eq 0 ]; then
  echo "La modification du fichier de configuration a été effectuée avec succès."
else
  echo "Une erreur s'est produite lors de la modification du fichier de configuration." 1>&2
  exit 1
fi

#Modification de l'autorisation des ports
PORT=3306
DECISION=1
# Demander à l'utilisateur son ip
while [$DECISION==1]
do
    echo "Bonjour ! Quel est l'adresse IP sur laquelle vous voulez installer l'IHM ? (Celle-ci doit être fixe et dans votre LAN)"
    read ip
    ufw allow from $ip to any port $PORT
    echo "Avez-vous d'autre adresse ip à ajouter ? Y/N"
    read dec
    if [$dec=='N']; 
    then
        $DECISION=0
    fi
done
