#!/bin/bash
echo "----------------------------------------------------------------"
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
    echo "Voulez-vous installer le paquet UFW... Y/N"
    read rep
    # Vérifier la réponse de l'utilisateur
    if [[ "$rep" == "N" || "$rep" == "n" ]]; then
        exit 1
    fi
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

# Vérifier si phpmyadmin est déjà installé
if [ -x "$(command -v phpmyadmin)" ]; then
  echo "phpmyadmin est déjà installé sur ce système."
else
    # Installation de ufw
    echo "----------------------------------------------------------------"
    echo "Voulez-vous installer le paquet phpmyadmin... Y/N (Retenez bien le mdp pour l'utilisateur root de phpmyadmin et choisissez apache2 lorsque cela vous ai proposé)"
    read rep
    # Vérifier la réponse de l'utilisateur
    if [[ "$rep" == "N" || "$rep" == "n" ]]; then
        exit 1
    fi
    apt-get update
    apt-get install -y phpmyadmin
    # Vérifier si l'installation a réussi
    if [ $? -eq 0 ]; then
        echo "phpmyadmin a été installé avec succès."
    else
        echo "Une erreur s'est produite lors de l'installation de phpmyadmin."
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
nouvelle_ligne="bind-address = 0.0.0.0"
echo "Modification du fichier de configuration $MARIA_CONF..."
sed -i "${line_number}d" "$MARIA_CONF"
# Ajouter la nouvelle ligne à l'emplacement spécifié
sed -i "${line_number}i$nouvelle_ligne" "$MARIA_CONF"

# Vérifier si la modification a réussi
if [ $? -eq 0 ]; then
  echo "La modification du fichier de configuration a été effectuée avec succès."
else
  echo "Une erreur s'est produite lors de la modification du fichier de configuration." 1>&2
  exit 1
fi

systemctl restart mariadb
systemctl restart mysql
echo "----------------------------------------------------------------"
echo "Quel est le mot de passe de l'utilisateur root de phpmyadmin ?"
read -s mdp_php

#Modification de l'autorisation des ports
PORT=3306
DECISION=1
while [ $DECISION -eq 1 ]; do
    # Demander à l'utilisateur une adresse IP
    echo "----------------------------------------------------------------"
    echo "Bonjour ! Quelle est l'adresse IP sur laquelle vous voulez installer l'IHM ? (Celle-ci doit être fixe et dans votre LAN)"
    read ip
    
    echo "Quel nom d'utilisateur souhaitez-vous utiliser ?"
    read user

    echo "Quel mot de passe voulez-vous utiliser pour cet utilisateur ?"
    read -s mdp #-s permet que le mdp soit caché

    # Autoriser l'accès depuis l'adresse IP spécifiée au port spécifié
    ufw allow from "$ip" to any port "$PORT"

    mysql -u root --password="$mdp_php" <<EOF
GRANT ALL PRIVILEGES ON jeedom.* TO '$user'@'$ip' IDENTIFIED BY '$mdp' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
    
    # Demander si l'utilisateur veut ajouter une autre adresse IP
    echo "----------------------------------------------------------------"
    echo "Avez-vous une autre adresse IP à ajouter ? (Y/N)"
    read dec
    
    # Vérifier la réponse de l'utilisateur
    if [[ "$dec" == "N" || "$dec" == "n" ]]; then
        DECISION=0
    fi
done
cd ..
rm -rf Jeedom_SQL
echo "Configuration terminée"
echo "----------------------------------------------------------------"
