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

#Supprimer le mdp root de mysql/mariadb
echo "Arrêt de MySQL..."
systemctl stop mysql
mysqld_safe --skip-grant-tables &
echo "Redémarrage de MySQL..."
systemctl start mysql

#Modification de l'autorisation des ports
PORT=3306
DECISION=1
while [ $DECISION -eq 1 ]; do
    # Demander à l'utilisateur une adresse IP
    echo "Bonjour ! Quelle est l'adresse IP sur laquelle vous voulez installer l'IHM ? (Celle-ci doit être fixe et dans votre LAN)"
    read ip
    
    echo "Quel nom d'utilisateur souhaitez-vous utiliser ?"
    read user

    echo "Quel mot de passe voulez-vous utiliser pour cet utilisateur ?"
    read -s mdp #-s permet que le mdp soit caché

    # Autoriser l'accès depuis l'adresse IP spécifiée au port spécifié
    ufw allow from "$ip" to any port "$PORT"

    mysql -u root
    echo -e "GRANT ALL PRIVILEGES ON jeedom.* TO '$user'@'$ip' IDENTIFIED BY '$mdp' WITH GRANT OPTION;"
    echo -e "FLUSH PRIVILEGES;"
    echo -e "EXIT;"
    
    # Demander si l'utilisateur veut ajouter une autre adresse IP
    echo "Avez-vous une autre adresse IP à ajouter ? (Y/N)"
    read dec
    
    # Vérifier la réponse de l'utilisateur
    if [ "$dec" == "N" ]; then
        DECISION=0
    fi
done

echo "Script fini"
