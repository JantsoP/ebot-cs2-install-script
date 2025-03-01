#!/bin/bash
# Installer for eBot CS2 by Flegma - Email: Flegma@gmail.com, Web: https://adria.gg, Discord: flegma (feel free to reach out here or on any social network)
# First version of the script, still a lot of things to improve and add (like asking if you want it to run on IP or subdomain, adding various checks, etc.)
# Script tested on Hetzner Cloud - on images "Ubuntu 20.04" and "Ubuntu 22.04". LAMP stack PHP 7.4, MySQL 8.0, Apache 2.4
export DEBIAN_FRONTEND=noninteractive #added this so that the prompts for service restarts doesnt popout
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'
blue='\e[1;34m%s\e[0m\n'
magenta='\e[1;35m%s\e[0m\n'
cyan='\e[1;36m%s\e[0m\n'
apt-get update
apt-get upgrade -y
printf "$yellow" "Now installing LEMP stack"
apt-get install -y language-pack-en-base software-properties-common nano wget curl git unzip snapd screen
LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php -y
apt-get install -y libapache2-mod-php7.4 apache2 redis-server mysql-server php7.4-fpm php7.4-redis php7.4-cgi php7.4-cli php7.4-dev php7.4-phpdbg php7.4-bcmath php7.4-bz2 php7.4-common php7.4-curl php7.4-dba php7.4-enchant php7.4-gd php7.4-gmp php7.4-imap php7.4-interbase php7.4-intl php7.4-ldap php7.4-mbstring php7.4-mysql php7.4-odbc php7.4-pgsql php7.4-pspell php7.4-readline php7.4-snmp php7.4-soap php7.4-sqlite3 php7.4-sybase php7.4-tidy php7.4-xml php7.4-xmlrpc php7.4-zip php7.4-opcache php7.4 php7.4-xsl
printf "$green" "LEMP stack installed."
printf "$yellow" "Installing PMA (phpMyAdmin), certbot and node stuff."
cd /usr/share
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
unzip phpMyAdmin-5.2.1-all-languages.zip
mv phpMyAdmin-5.2.1-all-languages phpmyadmin
chmod -R 0755 phpmyadmin
mkdir /usr/share/phpmyadmin/tmp
chmod -R 0777 /usr/share/phpmyadmin/tmp
rm -rf /usr/share/phpMyAdmin-5.2.1-all-languages.zip
#todo: need to add pma configuration to apache
cd --
snap install core
snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
apt-get install -y nodejs npm
npm -g install n
npm -g install yarn
n lts
timedatectl set-timezone Europe/Zagreb
hash -r 
cd --
wget https://getcomposer.org/composer-2.phar && chmod +x composer-2.phar && mv composer-2.phar /usr/bin/composer
printf "$green" "Installed server dependencies, now onto eBot CS2 stuff."
PUBLIC_IP=$(wget -qO- checkip.amazonaws.com)
# Prompt for the new root password
read -p "Enter the new MySQL root password: " new_root_password
# Use mysqladmin to change the root password
mysqladmin -u root password "$new_root_password"
#printf "$green" "MySQL root password has been changed."
#echo "MySQL root password has been changed."
# Secure the MySQL installation
mysql_secure_installation <<EOF
n
y
y
y
y
EOF
printf "$green" "MySQL installation has been secured (changed root password and mysql_secure_installation run."
# Wait for the user to press Enter
read -p "Press Enter to continue..."
printf "$yellow" "Create MySQL database and user/password that will be used later on."
# Prompt the user for database information
echo  # Print a newline for a clean input prompt
read -p "Enter the name of the new database: " ebot_db_name
read -p "Enter the name of the new user: " ebot_user_name
read -p "Enter a password for the new user: " ebot_user_password #use -s flag if you want it to not be shown
echo  # Print a newline for a clean input prompt
# Create the MySQL database and user
mysql -u root -p$new_root_password -e "CREATE DATABASE $ebot_db_name;"
mysql -u root -p$new_root_password -e "CREATE USER '$ebot_user_name'@'localhost' IDENTIFIED BY '$ebot_user_password';"
mysql -u root -p$new_root_password -e "GRANT ALL PRIVILEGES ON $ebot_db_name.* TO '$ebot_user_name'@'localhost';"
mysql -u root -p$new_root_password -e "FLUSH PRIVILEGES"
printf "$green" "MySQL database '$ebot_db_name' and user '$ebot_user_name' with password '$ebot_user_password' have been created."
# Wait for the user to press Enter
read -p "Press Enter to continue..."
mkdir /home/ebot/
cd /home/ebot/
npm -g install socket.io archiver formidable ts-node
wget -O ebot-cs2-web.zip https://github.com/deStrO/eBot-CSGO-Web/archive/refs/heads/master.zip
wget -O ebot-cs2-app.zip https://github.com/deStrO/eBot-CSGO/archive/refs/heads/master.zip
wget -O ebot-cs2-logs.zip https://github.com/deStrO/ebot-project/archive/refs/heads/main.zip
unzip ebot-cs2-web.zip
mv eBot-CSGO-Web-master ebot-cs2-web
unzip ebot-cs2-app.zip
mv eBot-CSGO-master ebot-cs2-app
unzip ebot-cs2-logs.zip
mv ebot-project-main ebot-cs2-logs
printf "$green" "eBot CS2 files acquired. Doing installations and configuration changes now."
printf "$yellow" "eBot CS2 logs configuration."
# Wait for the user to press Enter
read -p "Press Enter to continue..."
cd /home/ebot/ebot-cs2-logs/
npm install
yarn install
mv configs/logs-receiver.json.sample configs/primary.json
#todo: edit the config json before starting the process if needed
screen -S ebot-cs2-logs -d -m
screen -S ebot-cs2-logs -X stuff "ts-node /home/ebot/ebot-cs2-logs/src/logs-receiver configs/primary.json\n"
screen -S ebot-cs2-logs -X detach
#todo: check if logs are running properly before continuing
printf "$green" "eBot CS2 logs running. Now editing CS2 application configuration."
echo 'date.timezone = Europe/Zagreb' >> /etc/php/7.4/cli/php.ini
echo 'date.timezone = Europe/Zagreb' >> /etc/php/7.4/apache2/php.ini
# Wait for the user to press Enter
read -p "Press Enter to continue..."
cd /home/ebot/ebot-cs2-app/
read -p "Enter a secret key that will be used for websocket: " websocket_secret
# Generate config.ini for ebot-cs2-app
echo '; eBot - A bot for match management for CS2
; @license     http://creativecommons.org/licenses/by/3.0/ Creative Commons 3.0
; @author      Julien Pardons <julien.pardons@esport-tools.net>
; @version     3.0
; @date        21/10/2012

[BDD]
MYSQL_IP = "127.0.0.1"
MYSQL_PORT = "3306"
MYSQL_USER = "'$ebot_user_name'"
MYSQL_PASS = "'$ebot_user_password'"
MYSQL_BASE = "'$ebot_db_name'"

[Config]
BOT_IP = "'$PUBLIC_IP'" 
BOT_PORT = 12360
SSL_ENABLED = false
SSL_CERTIFICATE_PATH = "ssl/cert.pem"
SSL_KEY_PATH = "ssl/key.pem"
EXTERNAL_LOG_IP = "" ; use this in case your server isnt binded with the external IP (behind a NAT)
MANAGE_PLAYER = 1
DELAY_BUSY_SERVER = 120
NB_MAX_MATCHS = 0
PAUSE_METHOD = "nextRound" ; nextRound or instantConfirm or instantNoConfirm
NODE_STARTUP_METHOD = "node" ; binary file name or none in case you are starting it with forever or manually
LOG_ADDRESS_SERVER = "'$PUBLIC_IP':12345" ; todo: check if this runs on localhost or external ip
WEBSOCKET_SECRET_KEY = "'$websocket_secret'"

[Redis]
REDIS_HOST = "127.0.0.1"
REDIS_PORT = 6379
REDIS_AUTH_USERNAME =
REDIS_AUTH_PASSWORD =
REDIS_CHANNEL_LOG = "ebot-logs"
REDIS_CHANNEL_EBOT_FROM_WS = "ebot-from-ws"
REDIS_CHANNEL_EBOT_TO_WS = "ebot-to-ws"

[Match]
LO3_METHOD = "restart" ; restart or csay or esl
KO3_METHOD = "restart" ; restart or csay or esl
DEMO_DOWNLOAD = true ; true or false :: whether gotv demos will be downloaded from the gameserver after matchend or not
REMIND_RECORD = false ; true will print the 3x "Remember to record your own POV demos if needed!" messages, false will not
DAMAGE_REPORT = true ; true will print damage reports at end of round to players, false will not
USE_DELAY_END_RECORD = false ; use the tv_delay to record postpone the tv_stoprecord & upload

[MAPS]
MAP[] = "de_dust2"
MAP[] = "de_inferno"
MAP[] = "de_overpass"
MAP[] = "de_nuke"
MAP[] = "de_vertigo"
MAP[] = "de_ancient"
MAP[] = "de_anubis"

[WORKSHOP IDs]

[Settings]
COMMAND_STOP_DISABLED = true
RECORD_METHOD = "matchstart" ; matchstart or knifestart
DELAY_READY = true' > /home/ebot/ebot-cs2-app/config/config.ini

COMPOSER_ALLOW_SUPERUSER=1 composer install --no-interaction
npm install
#run ebot app now
echo '#!/bin/bash
screen -S ebot-cs2-app -d -m
screen -S ebot-cs2-app -X stuff "/usr/bin/php /home/ebot/ebot-cs2-app/bootstrap.php\n"
screen -S ebot-cs2-app -X detach' > /home/ebot/ebot-cs2-app/ebot.sh
chmod +x /home/ebot/ebot-cs2-app/ebot.sh
#todo: check if ebot is running before continuing - need to change order of installs
printf "$green" "eBot CS2 app running. Now editing CS2 webpanel configuration."
# Wait for the user to press Enter
read -p "Press Enter to continue..."
cd /home/ebot/ebot-cs2-web/
# Generate app_user.yml
echo '# ----------------------------------------------------------------------
# white space are VERY important, dont remove it or it will not work
# ----------------------------------------------------------------------

  log_match: ../../ebot-csgo/logs/log_match
  log_match_admin: ../../ebot-csgo/logs/log_match_admin
  demo_path: ../../ebot-csgo/demos

  default_max_round: 12
  default_rules: esl5on5
  default_overtime_max_round: 3
  default_overtime_startmoney: 12000

  # true or false, whether demos will be downloaded by the ebot server
  # the demos can be downloaded at the matchpage, if its true

  demo_download: true

  ebot_ip: '$PUBLIC_IP'
  ebot_port: 12360

  # lan or net, its to display the server IP or the GO TV IP
  # net mode display only started match on home page
  mode: net

  # set to 0 if you dont want a refresh
  refresh_time: 30

  # Toornament Configuration
  toornament_id:
  toornament_secret:
  toornament_api_key:
  toornament_plugin_key: test-123457890

  # Same as eBot config
  websocket_secret_key: '$websocket_secret'' > /home/ebot/ebot-cs2-web/config/app_user.yml

# Generate databases.yml
rm /home/ebot/ebot-cs2-web/config/databases.yml
echo "# You can find more information about this file on the symfony website:
# http://www.symfony-project.org/reference/1_4/en/07-Databases

all:
  doctrine:
    class: sfDoctrineDatabase
    param:
      dsn:      mysql:host=127.0.0.1;dbname=$ebot_db_name
      username: $ebot_user_name
      password: $ebot_user_password" > /home/ebot/ebot-cs2-web/config/databases.yml

#Edit SF 1.4 class function so that it works with PHP 7.4 - protected function normalizeHeaderName($name)
#Specify the file to edit
file_to_edit="/home/ebot/ebot-cs2-web/lib/vendor/symfony/lib/response/sfWebResponse.class.php"

# Define the new function
new_function='
protected function normalizeHeaderName($name)
{
  $out = [];
  array_map(function($record) use (&$out) {
    $out[] = ucfirst(strtolower($record));
  }, explode("-",$name));
  return implode("-",$out);
}
'

# Use sed to delete lines 407-410 and then echo the new content starting at line 407
sed -i '407,410d' "$file_to_edit"
echo -e "$new_function" | sed -i '407r /dev/stdin' "$file_to_edit"
#
cd /home/ebot/ebot-cs2-web/
mkdir /home/ebot/ebot-cs2-web/cache/
rm -rf /home/ebot/ebot-cs2-web/web/installation/
php symfony cc
php symfony doctrine:build --all --no-confirmation

#echo "THE LAST QUESTION: I need a username and a password for ebot"
printf "$yellow" "THE LAST QUESTION: You need a username and a password for ebot."
read -p "Email: " -e -i email@domain.com EBOTEMAIL
read -p "Username: " -e -i admin EBOTUSER
read -p "Password: " -e -i password EBOTPASSWORD
php symfony guard:create-user --is-super-admin $EBOTEMAIL $EBOTUSER $EBOTPASSWORD
chown -R www-data:www-data /home/ebot/
chmod -R 755 /home/ebot/
chmod -R 777 /home/ebot/ebot-cs2-web/cache/
printf "$green" "Installed eBot CS2 stuff. Editing Apache configuration now."
# Wait for the user to press Enter
read -p "Press Enter to continue..."
read -p "Enter subdomain/domain on which the eBot will be running: " EBOT_DOMAIN
echo "<VirtualHost *:80>
	#Edit your email
	ServerAdmin $EBOTEMAIL
	#Edit your sub-domain
	ServerAlias $EBOT_DOMAIN
	DocumentRoot /home/ebot/ebot-cs2-web/web
	<Directory /home/ebot/ebot-cs2-web/web/>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
		<IfVersion < 2.4>
			Order allow,deny
			allow from all
		</IfVersion>
		<IfVersion >= 2.4>
			Require all granted
		</IfVersion>
	</Directory>
	</VirtualHost>" > /etc/apache2/sites-available/ebotcs2.conf

a2enmod rewrite && a2ensite ebotcs2.conf && service apache2 restart

cd /home/ebot/ebot-cs2-app/ && ./ebot.sh #need to fix this by changing change order of install - ebot logs, ebot web, ebot app

printf "$green" "Installed everything. You can login now on: '$EBOT_DOMAIN'"


#todo: write service for logs and app
#todo: write cronjob script that will periodically check if all processes are running.
