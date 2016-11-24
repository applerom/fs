### fusion.inc.sh ### FusionPBX #############################################################################
FTP_FS_USER=fsadmin
FTP_FS_USER_PAS=mypassword
FTP_PBX_USER=pbxadmin
FTP_PBX_USER_PAS=mypassword

function fusion {
	fusion1=$(whiptail --title "Install FusionPBX" --separate-output --cancel-button "Exit" \
--backtitle  "" \
--checklist "Choose configuration" 12 90 4 \
"Apache" "Install Web-sever Apache 2" ON \
"LastVersion" "Install latest FusionPBX (or ver.4.0 if this punct disabled)" ON \
"FTP-FS-Fusion" "Install two FTP users - to access FreeSwitch and FusionPBX" OFF \
"Reload-if-exist" "Reload if exist /var/www/html (+backup)" OFF  3>&1 1>&2 2>&3 )
	if [ $? != 0 ]; then exit 0; fi

	dialogGaugeStart "Get and Setup FusionPBX" "Please wait" 8 70 0
	{
		if [[ $(echo $fusion1 | grep -c "Apache") == "1" ]]  ; then
			dialogGaugePrompt 2 "Install Apache 2 (Web-server)"
			dialogAptGet 2 18 install apache2
			dialogGaugePrompt 20 "Configure Apache"
			a2enmod ssl
			a2enmod rewrite

			if [ ! -d $MYCERT_DIR ] ; then get_certs ; fi
			cp $MYCERT_DIR/$MYCERT_CA /etc/ssl/private/cafile.pem
			cp $MYCERT_DIR/$MYCERT_CRT /etc/ssl/private/$MYCERT_CRT
			cp $MYCERT_DIR/$MYCERT_KEY /etc/ssl/private/$MYCERT_KEY
			
			make_backup /etc/apache2/sites-available/fusionpbx.conf
			cat <<EOF >>/etc/apache2/sites-available/fusionpbx.conf
<VirtualHost *:80>
		ServerAdmin webmaster@localhost
ServerName $MYSITE
ServerAlias www.$MYSITE
DocumentRoot /var/www/html
<Directory /var/www/html>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
		Require all granted
</Directory>
		ErrorLog \${APACHE_LOG_DIR}/$MYSITE-error.log
		# Possible values include: debug, info, notice, warn, error, crit,
		# alert, emerg.
		LogLevel warn
		CustomLog \${APACHE_LOG_DIR}/$MYSITE-access.log combined
</VirtualHost>
<VirtualHost *:443>
ServerName $MYSITE
ServerAlias www.$MYSITE
DocumentRoot /var/www/html
<Directory /var/www/html>
 Options Indexes FollowSymLinks MultiViews
 AllowOverride All
 Require all granted
</Directory>
		ErrorLog \${APACHE_LOG_DIR}/$MYSITE-ssl-error.log
		LogLevel warn
		CustomLog \${APACHE_LOG_DIR}/$MYSITE-ssl-access.log combined
	SSLEngine on
	SSLCertificateKeyFile	"/etc/ssl/private/$MYCERT_KEY"
	SSLCertificateFile		"/etc/ssl/private/$MYCERT_CRT"
	SSLCACertificateFile	"/etc/ssl/private/cafile.pem"
</VirtualHost>
EOF
			a2ensite fusionpbx
			wget -q https://www.adminer.org/static/download/4.2.4/adminer-4.2.4.php -O /var/www/html/myadminer.php
			chown -R www-data:www-data /var/www
			
			dialogGaugePrompt 20 "Install PHP"
			dialogAptGet 20 18 install php5 php5-cli php5-common php5-mysql php5-mcrypt libapache2-mod-php5 php-pear php5-curl php5-gd php5-odbc php5-pgsql php5-memcached

			dialogGaugePrompt 39 "Install Apache as service and restart"
			a2dismod mpm_event  > /dev/null 2>&1
			a2enmod mpm_prefork > /dev/null 2>&1
			service apache2 restart
			update-rc.d apache2 defaults
		fi
		
		_LastVersion="-b 4.0"
		if [[ $(echo $fusion1 | grep -c "LastVersion") == "1" ]] ; then
			_LastVersion=""
		fi
		dialogGaugePrompt 40 "Get FusionPBX"
		cd /var/www
		if [ -d /var/www/html ]; then
			if [[ $(echo $fusion1 | grep -c "Reload-if-exist") == "1" ]] || [ ! -d /var/www/html/app/xml_cdr ] ; then
				make_backup /var/www/html
				dialogGitClone 40 50 $_LastVersion https://github.com/fusionpbx/fusionpbx.git html 
			fi
		else
			dialogGitClone 40 50 $_LastVersion https://github.com/fusionpbx/fusionpbx.git html
		fi
		
		if [[ $(echo $fusion1 | grep -c "FTP-FS-Fusion") == "1" ]] ; then
			dialogGaugePrompt 92 "Add FTP-user for FreeSwitch and FusionPBX"
			get_var_txt_def FTP_FS_USER "Enter FreeSwitch FTP-user login" $FTP_FS_USER
			get_pas_txt_def FTP_FS_USER_PAS "Enter password for FreeSwitch FTP-user $FTP_FS_USER" $FTP_FS_USER_PAS
			echo $FTP_FS_USER_PAS | ftpasswd --passwd --stdin --file=/etc/proftpd/ftpd.passwd --name=$FTP_FS_USER --shell=/bin/false --home=/usr/local/freeswitch --uid=`sed -n 's|ftp:x:\([1-9][0-9]*\).*$|\1|p' /etc/passwd` --gid=33

			get_var_txt_def FTP_PBX_USER "Enter FusionPBX FTP-user login" $FTP_PBX_USER
			get_pas_txt_def FTP_PBX_USER_PAS "Enter password for FusionPBX FTP-user $FTP_FS_USER" $FTP_PBX_USER_PAS
			echo $FTP_PBX_USER_PAS | ftpasswd --passwd --stdin --file=/etc/proftpd/ftpd.passwd --name=$FTP_PBX_USER --shell=/bin/false --home=/var/www/html --uid=33 --gid=33
		fi

		dialogGaugePrompt 98 "Configure FusionPBX"
		fusion_configure

		dialogGaugePrompt 100 "Installation complete"
	} > "$MY_TMP_DIR/gauge"
	dialogGaugeStop
}

function fusion_configure {
	chown -R www-data:www-data /var/www/html
	
	FirstTimeInstall="/var/www/html/core/install/install_first_time.php"
	if [[ $(echo $fusion1 | grep -c "LastVersion") == "1" ]] ; then
		FirstTimeInstall="/var/www/html/core/install/install.php"
	fi

	# Todo: postgres setup for fusionpbx
	#	sed -i 's|<param name="db-info" value="host=localhost user=postgres password=nopassword dbname=fusionpbx connect_timeout=10" />|<param name="db-info" value="host=10.100.21.31 user=fsdbadmin password=mypassword dbname=fusionpbx connect_timeout=10" />|' /autoload_configs/cdr_pg_csv.conf.xml
	
	sed -i "s|admin_username = '';|admin_username = 'admin';|" $FirstTimeInstall
	sed -i "s|admin_password = '';|admin_password = 'sf16pas';|" $FirstTimeInstall
	sed -i "s|db_host = '';|db_host = '$POSTGRE_SERVER';|" $FirstTimeInstall
	sed -i "s|db_username = '';|db_username = '$POSTGRE_USER';|" $FirstTimeInstall
	sed -i "s|db_password = '';|db_password = '$POSTGRE_PASSWORD';|" $FirstTimeInstall
	sed -i "s|db_create = '';|db_create = 'same';|" $FirstTimeInstall
}

### END ### fusion.inc.sh #############################################################################
