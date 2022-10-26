#!/usr/bin/env bash

######################################
# Created by Pool4U for YiiMP use... #
######################################

source /etc/functions.sh
source /etc/yiimpserver.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
source $HOME/yiimpserver/yiimp_single/.wireguard.install.cnf

Host_zemi=$DBInternalIP
IFS="." read -r Host_1 Host_2 Host_3 Host_4 <<< "${DBInternalIP}"
#echo "${Host_1} ${Host_2} ${Host_3} ${Host_4}"
for i in $Host_1"."$Host_2"."$Host_3".%"; do
    Host_Napravi+="$i "
done
#echo "${Host_Napravi}"

set -eu -o pipefail

function print_error {
    read line file <<<$(caller)
    echo "An error occurred in line $line of file $file:" >&2
    sed "${line}q;d" "$file" >&2
}
trap print_error ERR

#if [[ ("$wireguard" == "true") ]]; then
    source $STORAGE_ROOT/yiimp/.wireguard.conf
#fi

echo -e "$CYAN Installing MariaDB 10.4...$COL_RESET"
MARIADB_VERSION='10.4'
sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password password $DBRootPassword"
sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password_again password $DBRootPassword"
apt_install mariadb-server mariadb-client
echo -e "$GREEN MariaDB build complete...$COL_RESET"
echo -e "$CYAN Creating DB users for YiiMP...$COL_RESET"

Q1="CREATE DATABASE IF NOT EXISTS ${YiiMPDBName};"
Q2="GRANT ALL ON ${YiiMPDBName}.* TO '${YiiMPPanelName}'@'${Host_Napravi}' IDENTIFIED BY '$PanelUserDBPassword';"
Q3="GRANT ALL ON ${YiiMPDBName}.* TO '${StratumDBUser}'@'${Host_Napravi}' IDENTIFIED BY '$StratumUserDBPassword';"
Q4="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}${Q4}"
sudo mysql -u root -p"${DBRootPassword}" -e "$SQL"

echo -e "$GREEN Database creation complete...$COL_RESET"

echo -e "$CYAN Creating my.cnf...$COL_RESET"

echo '[clienthost1]
user='"${YiiMPPanelName}"'
password='"${PanelUserDBPassword}"'
database='"${YiiMPDBName}"'
host='"${DBInternalIP}"'

[clienthost2]
user='"${StratumDBUser}"'
password='"${StratumUserDBPassword}"'
database='"${YiiMPDBName}"'
host='"${DBInternalIP}"'

[mysql]
user=root
password='"${DBRootPassword}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.my.cnf >/dev/null 2>&1

sudo chmod 0600 $STORAGE_ROOT/yiimp/.my.cnf
echo -e "$GREEN Passwords can be found in $STORAGE_ROOT/yiimp/.my.cnf$COL_RESET"

echo -e "$CYAN Importing YiiMP Default database values...$COL_RESET"
cd $HOME/yiimp/yiimp_setup/yiimp/sql
# import sql dump
sudo zcat 2019-11-10-yiimp.sql.gz | sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}"
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2018-09-22-workers.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2020-06-03-blocks.sql
echo -e "$GREEN Database import complete...$COL_RESET"

echo -e "$CYAN Tweaking MariaDB for better performance...$COL_RESET"
sudo sed -i '/max_connections/c\max_connections         = 2000' /etc/mysql/my.cnf
sudo sed -i '/thread_cache_size/c\thread_cache_size       = 512' /etc/mysql/my.cnf
sudo sed -i '/tmp_table_size/c\tmp_table_size          = 128M' /etc/mysql/my.cnf
sudo sed -i '/max_heap_table_size/c\max_heap_table_size     = 128M' /etc/mysql/my.cnf
sudo sed -i '/wait_timeout/c\wait_timeout            = 60' /etc/mysql/my.cnf
sudo sed -i '/max_allowed_packet/c\max_allowed_packet      = 64M' /etc/mysql/my.cnf
sudo sed -i 's/#bind-address=0.0.0.0/bind-address='${DBInternalIP}'/g' /etc/mysql/my.cnf
echo -e "$GREEN Database tweak complete...$COL_RESET"

restart_service mysql
echo -e "$GREEN Database build complete...$COL_RESET"

set +eu +o pipefail
cd $HOME/yiimpserver/yiimp_single
