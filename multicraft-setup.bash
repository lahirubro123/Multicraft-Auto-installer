#!/bin/bash

clear
echo -e "------------------------------------------------"
echo -e "   Server.pro Multicraft Installation Script    "
echo -e "              Created by Josh Q                 \n"
echo -e " DO NOT CLOSE THE SHELL TAB THROUGHOUT PROCESS! "
echo -e "------------------------------------------------\n"

# Check if the user is root (or using sudo)
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root or with sudo."
    exit 1
fi

echo -e "[INFO] Updating system..."
apt-get -qq update && apt-get -qq upgrade -y &> /dev/null
echo -e "[SUCCESS] System updated!"

echo -e "[INFO] Installing required packages..."
apt-get -qq install apache2 mysql-server -y &> /dev/null

dpkg -s apache2 &> /dev/null
if [ ! $? -eq 0 ]; then
    echo -e "[FATAL] Package install failed."
    exit 1
fi
echo -e "[SUCCESS] Packages installed!"

echo -e "[INFO] Setting up MySQL (this is now automated)..."
# Generate random password for root MySQL user
export MYSQL_ROOT_PWD=$(openssl rand -hex 30)

if [ ! mysqladmin --user=root status > /dev/null 2>&1 ]; then
    echo -e "[FATAL] MySQL root password already set. Exiting..."
    exit 1
fi

# Run queries, as in mysql_secure_installation => 
#    https://github.com/MariaDB/server/blob/5.5/scripts/mysql_secure_installation.sh
mysql --user=root <<_EOF_
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PWD}';
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    FLUSH PRIVILEGES;
_EOF_

echo -e "[SUCCESS] MySQL setup complete!"

echo -e "[INFO] Installing more required packages..."
apt-get -qq install php libapache2-mod-php php-mysql php-pdo php-sqlite3 php-curl php-xml php-gd default-jre default-jdk -y &> /dev/null

dpkg -s php &> /dev/null
if [ ! $? -eq 0 ]; then
    echo -e "[FATAL] Package install failed."
    exit 1
fi
echo -e "[SUCCESS] Packages installed!"

echo -e "[INFO] Downloading Multicraft latest version..."
wget --quiet http://www.multicraft.org/download/linux64 -O multicraft.tar.gz

if [ ! -f ./multicraft.tar.gz ]; then
    echo -e "[FATAL] Download of Multicraft failed."
    exit 1;
fi
echo -e "[SUCCESS] Multicraft downloaded. Prepare to complete configuration!\n"
tar xvzf multicraft.tar.gz &> /dev/null
cd multicraft
./setup.sh
echo " "
read -p "Enter your database password (the last one you specified): " dbpass

echo -e "\n[INFO] Setting up database..."
mysql -e "create database multicraft_panel" &> /dev/null
mysql -e "create database multicraft_daemon" &> /dev/null
mysql -e "create user 'multicraft'@'localhost' identified by '${dbpass}'" &> /dev/null
mysql -e "grant all privileges on multicraft_panel.* to 'multicraft'@'localhost'" &> /dev/null
mysql -e "grant all privileges on multicraft_daemon.* to 'multicraft'@'localhost'" &> /dev/null
echo -e "[SUCCESS] Databases have been setup!"

echo -e "[INFO] Setting up Systemd service..."
wget --quiet http://www.multicraft.org/files/multicraft.service -O /etc/systemd/system/multicraft.service && chmod 644 /etc/systemd/system/multicraft.service && systemctl enable multicraft

if [ ! -f /etc/systemd/system/multicraft.service ]; then
    echo -e "[FATAL] Creation of Systemd service failed."
    exit 1
fi
echo -e "[SUCCESS] Service file created and Multicraft enabled!"

echo -e "[INFO] Configuring Apache..."
sed -i '172s/None/All/g' /etc/apache2/apache2.conf && systemctl reload apache2 && systemctl enable apache2

if (( $(ps -ef | grep -v grep | grep apache2 | wc -l) < 1 )); then
    echo -e "[FATAL] Something went wrong. Exiting..."
    exit 1
fi

echo -e "[SUCCESS] Apache configured correctly!"

clear
echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo -e "Now: "
echo -e "- Navigatge to http://$(curl --silent https://ipinfo.io/ip)/multicraft , and continue setup!"
echo -e "- As of the latest version of this script, you DO NOT need to modify Apache's config!"
echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
