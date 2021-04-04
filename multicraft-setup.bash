#!/bin/bash

echo -e "Server.pro Multicraft Installation Script";
echo -e "Created by Josh Q";
echo -e " ";

echo -e "[INFO] Updating system..."

apt-get -qq update && apt-get -qq upgrade -y;

echo -e "[SUCCESS] System updated!";

echo -e "[INFO] Installing required packages..."

apt-get -qq install apache2 mysql-server -y

if [ $(apt-get list --installed | grep "apache2") = "" ]; then
    echo -e "[FATAL] Something went wrong. Exiting..."
    exit 1;
fi

echo -e "[SUCCESS] Packages installed!";

echo -e "[INFO] Starting MySQL setup..."

mysql_secure_installation;

echo -e "[INFO] Installing more required packages..."

apt-get -qq install php libapache2-mod-php php-mysql php-pdo php-sqlite3 php-curl php-xml php-gd default-jre default-jdk -y;

if [ $(apt-get list --installed | grep "php") = "" ]; then
    echo -e "[FATAL] Something went wrong. Exiting..."
    exit 1;
fi

echo -e "[SUCCESS] Packages installed!";

echo -e "[INFO] Downloading Multicraft latest version..."

wget http://www.multicraft.org/download/linux64 -O multicraft.tar.gz;

if [ ! -f ./multicraft.tar.gz ]; then
    echo -e "[FATAL] Something went wrong. Exiting..."
    exit 1;
fi

echo -e "[SUCCESS] Multicraft downloaded. Prepare to complete configuration!";

tar xvzf multicraft.tar.gz;

cd multicraft;

./setup.sh;

read -p "Enter a secure password for the Multicraft database user: " dbpass;

echo -e "[INFO] Setting up database..."

mysql -e "create database multicraft_panel";
mysql -e "create database multicraft_daemon";
mysql -e "create user 'multicraft'@'localhost' identified by '${dbpass}'";
mysql -e "grant all privileges on multicraft_panel.* to 'multicraft'@'localhost'";
mysql -e "grant all privileges on multicraft_daemon.* to 'multicraft'@'localhost'";

echo -e "[SUCCESS] Databases have been setup!";

echo -e "[INFO] Setting up Systemd service..."

wget http://www.multicraft.org/files/multicraft.service -O /etc/systemd/system/multicraft.service && chmod 644 /etc/systemd/system/multicraft.service && systemctl enable multicraft;

echo -e "[SUCCESS] Service file created and Multicraft enabled!";

echo -e "---------------------------------------------"
echo -e "Now: "
echo -e "- Set AllowOverride to All for /var/www in /etc/apache2/apache2.conf, then reload Apache!";
echo -e "- Navigatge to http://{YOUR IP}/multicraft, and continue setup!"
