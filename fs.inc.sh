################################################################################
### FreeSwitch Vars
################################################################################
DEB_NAME=jessie
FS_REPO=http://files.freeswitch.org/repo/deb/freeswitch-1.6/
SOURCES_LIST_DIR=/etc/apt/sources.list.d
FS_REPO_LIST=freeswitch.list
FS_PUB_KEY=https://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub
FS_USER=freeswitch
FS_GROUP=www-data


################################################################################
### FreeSwitch FUNCTIONS
################################################################################
function fs_install {
	_mod_shout_1="mod_shout"
	_mod_shout_2="Install mod_shout"
	_mod_shout_3=ON
	_mod_shout_4=""

	if [[ $DIST_TYPE == "ubuntu" ]] ; then
		_mod_shout_2="(not supported for Ubuntu 14 LTS)" 
		_mod_shout_3=OFF
		_mod_shout_4="Warning: Ubuntu 14 LTS doesn't support mod_shout"
	fi

	whiptail --title "FreeSwitch settings" --yes-button "Continue" --no-button "Exit" \
	--yesno "\
FS_REPO: ${FS_REPO}\n\
FS_PUB_KEY: ${FS_PUB_KEY}\n\
FS_USER: ${FS_USER}\n\
FS_GROUP: ${FS_GROUP}\n\
\n\
$_mod_shout_4\n\
\n\
" 14 80
	if [ $? != 0 ]; then echo "FreeSwitch settings - exit" ; exit 0; fi

	fs_install1=$(whiptail --title "Install FreeSwitch and accessories" --separate-output --cancel-button "Exit" \
--backtitle  "" \
--checklist "Choose configuration" 28 80 18 \
"PostgreSQL-in-Core" "Enable core PostgreSQL support" ON \
"mod_v8" "Install mod_v8" ON \
"mod_nibblebill" "Install mod_nibblebill" ON \
"mod_silk" "Install mod_silk" ON \
"mod_mp4v" "Install mod_mp4v" ON \
"mod_curl" "Install mod_curl" ON \
"mod_flite" "Install mod_flite" ON \
"mod_cdr_pg_csv" "Install mod_cdr_pg_csv" ON \
"mod_cluechoo" "Install mod_cluechoo" ON \
"mod_ilbc" "Install mod_ilbc" ON \
"mod_siren" "Install mod_siren" ON \
"$_mod_shout_1" "$_mod_shout_2" $_mod_shout_3 \
"Lua" "Install Lua, LuaRocks and Lua-modules" ON \
"AllSounds" "Install all sounds and examples" ON \
"OwnCerts" "Install own certificates" ON \
"Reload-if-exist" "Reload FreeSwitch sources if they exist (+backup)" OFF \
"EC2_NAT" "Set up FreeSwitch for NAT on EC2 " OFF 3>&1 1>&2 2>&3 )
	if [ $? != 0 ]; then exit 0; fi

	dialogGaugeStart "Get and compile FreeSwitch" "Please wait" 8 70 0
	{
		dialogGaugePrompt 2 "Install Freeswitch dependencies"
		dialogAptGet 2 18 install unixodbc-dev libmyodbc

		if [[ $DIST_TYPE == "debian" ]] && [[ $VERSION_ID == "8" ]] ; then
			if [ -d $SOURCES_LIST_DIR ]; then
				dialogGaugePrompt 3 "Add $FS_REPO_LIST to $SOURCES_LIST_DIR"
				echo "deb $FS_REPO $DEB_NAME main" > $SOURCES_LIST_DIR/$FS_REPO_LIST
			else
				echo "$SOURCES_LIST_DIR DO NOT exist! Exit."
				exit 1
			fi
			dialogGaugePrompt 4 "Get FS pub key"
			wget -q -O- $FS_PUB_KEY | apt-key add -
			echo "deb http://http.debian.net/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
			dialogAptGet 5 5 update

			if [[ $(echo $fs_install1 | grep -c "Lua") == "1" ]]  ; then
				dialogAptGet 10 4 install lua5.2 liblua5.2-dev
			fi
			dialogGaugePrompt 14 "Install all FS deps"
			dialogAptGet 14 36 freeswitch-video-deps-most
		fi

		if [[ $DIST_TYPE == "ubuntu" ]] ; then
			add-apt-repository -y ppa:ondrej/php5-5.6 > /dev/null 2>&1
			dialogAptGet 2 8 update
			if [[ $(echo $fs_install1 | grep -c "Lua") == "1" ]]  ; then
				dialogAptGet 10 4 install lua5.2 liblua5.2-dev
			dialogAptGet 14 30 autoconf automake devscripts gawk g++ git-core libjpeg-dev libncurses5-dev libtool make python-dev gawk pkg-config libtiff5-dev libperl-dev libgdbm-dev libdb-dev gettext libssl-dev libcurl4-openssl-dev libpcre3-dev libspeex-dev libspeexdsp-dev libsqlite3-dev libedit-dev libldns-dev libpq-dev yasm libopus-dev libsndfile-dev
			fi
			if [[ $(echo $fs_install1 | grep -c "mod_silk") == "1" ]]  ; then
				dialogAptGet 44 2 install libsilk-dev
			fi
			if [[ $(echo $fs_install1 | grep -c "mod_flite") == "1" ]]  ; then
				dialogAptGet 46 2 install libflite-dev 
			fi
			if [[ $(echo $fs_install1 | grep -c "mod_shout") == "1" ]]  ; then
				dialogAptGet 48 2 install libshout3-dev libmpg123-dev
			fi
		fi		

		dialogGaugePrompt 50 "Get Freeswitch"
		git config --global pull.rebase true > /dev/null 2>&1
		cd /usr/local/src/
		if [ -d /usr/local/src/freeswitch ]; then
			if [[ $(echo $fs_install1 | grep -c "Reload-if-exist") == "1" ]]  ; then
				make_backup /usr/local/src/freeswitch
				dialogGitClone 50 6 https://freeswitch.org/stash/scm/fs/freeswitch
			fi
		else
			dialogGitClone 50 6 https://freeswitch.org/stash/scm/fs/freeswitch
		fi

		cd /usr/local/src/freeswitch

		dialogGaugePrompt 56 "Bootstrap Freeswitch sources"
		dialogBootstrap 56 8 -j
		if [[ $(echo $fs_install1 | grep -c "PostgreSQL-in-Core") == "1" ]]  ; then
			dialogGaugePrompt 64 "Configure Freeswitch sources with POSTGRE-support"
			dialogConfigure 64 6 --enable-core-pgsql-support
		else
			dialogGaugePrompt 64 "Configure Freeswitch sources"
			dialogConfigure 64 6
		fi
		if [[ $(echo $fs_install1 | grep -c "mod_v8") == "1" ]]  ; then
			dialogGaugePrompt 70 "Enable: mod_v8"
			sed -i 's|#languages/mod_v8|languages/mod_v8|' /usr/local/src/freeswitch/modules.conf
		fi
		if [[ $(echo $fs_install1 | grep -c "mod_nibblebill") == "1" ]]  ; then
			dialogGaugePrompt 70 "Enable: mod_nibblebill"
			sed -i 's|#applications/mod_nibblebill|applications/mod_nibblebill|' /usr/local/src/freeswitch/modules.conf
		fi
		if [[ $(echo $fs_install1 | grep -c "mod_silk") == "1" ]]  ; then
			dialogGaugePrompt 70 "Enable: mod_silk"
			sed -i 's|#codecs/mod_silk|codecs/mod_silk|' /usr/local/src/freeswitch/modules.conf
		fi
		if [[ $(echo $fs_install1 | grep -c "mod_mp4v") == "1" ]]  ; then
			dialogGaugePrompt 70 "Enable: mod_mp4v"
			sed -i 's|#codecs/mod_mp4v|codecs/mod_mp4v|' /usr/local/src/freeswitch/modules.conf
		fi
		if [[ $(echo $fs_install1 | grep -c "mod_curl") == "1" ]]  ; then
			dialogGaugePrompt 70 "Enable: mod_curl"
			sed -i 's|#applications/mod_curl|applications/mod_curl|' /usr/local/src/freeswitch/modules.conf
		fi
		if [[ $(echo $fs_install1 | grep -c "mod_flite") == "1" ]]  ; then
			dialogGaugePrompt 70 "Enable: mod_flite"
			sed -i 's|#asr_tts/mod_flite|asr_tts/mod_flite|' /usr/local/src/freeswitch/modules.conf
		fi
		if [[ $(echo $fs_install1 | grep -c "mod_shout") == "1" ]]  ; then
			dialogGaugePrompt 70 "Enable: mod_shout"
			sed -i 's|#formats/mod_shout|formats/mod_shout|' /usr/local/src/freeswitch/modules.conf
		fi
		
		if [[ $(echo $fs_install1 | grep -c "mod_cdr_pg_csv") == "1" ]]  ; then
			dialogGaugePrompt 70 "Enable: mod_cdr_pg_csv"
			sed -i 's|#event_handlers/mod_cdr_pg_csv|event_handlers/mod_cdr_pg_csv|' /usr/local/src/freeswitch/modules.conf
		fi
		if [[ $(echo $fs_install1 | grep -c "mod_cluechoo") == "1" ]]  ; then
			dialogGaugePrompt 70 "Enable: mod_cluechoo"
			sed -i 's|#applications/mod_cluechoo|applications/mod_cluechoo|' /usr/local/src/freeswitch/modules.conf
		fi
		if [[ $(echo $fs_install1 | grep -c "mod_ilbc") == "1" ]]  ; then
			dialogGaugePrompt 70 "Enable: mod_ilbc"
			sed -i 's|#codecs/mod_ilbc|codecs/mod_ilbc|' /usr/local/src/freeswitch/modules.conf
		fi
		if [[ $(echo $fs_install1 | grep -c "mod_siren") == "1" ]]  ; then
			dialogGaugePrompt 70 "Enable: mod_siren"
			sed -i 's|#codecs/mod_siren|codecs/mod_siren|' /usr/local/src/freeswitch/modules.conf
		fi

		dialogGaugePrompt 70 "Compile Freeswitch"
		dialogMake 70 20 200

		dialogGaugePrompt 90 "Install Freeswitch"
		dialogMake 90 8 120 install
		if [[ $(echo $fs_install1 | grep -c "AllSounds") == "1" ]]  ; then
			dialogGaugePrompt 98 "Install some FS sounds end examples"
			fs_all_sounds 98 1 999
		fi
		
#		if [[ $(echo $fs_install1 | grep -c "PostgreSQL-in-Core") == "1" ]]  ; then
#			sed -i '<!-- <param name="core-db-dsn"|<param name="core-db-dsn"|' /usr/local/src/freeswitch/modules.conf
#		fi
		dialogGaugePrompt 99 "Install Freeswitch as service"
		fs_service
		fs_ln_home

		if [[ $(echo $fs_install1 | grep -c "OwnCerts") == "1" ]]  ; then
			dialogGaugePrompt 99 "Get own certificates and install them for Freeswitch"
			fs_certs
		fi
	
		if [[ $(echo $fs_install1 | grep -c "EC2_NAT") == "1" ]]  ; then
			dialogGaugePrompt 99 "Setup Freeswitch for EC2"
			fs_ec2
		fi
		if [[ $(echo $fs_install1 | grep -c "Lua") == "1" ]]  ; then
			dialogGaugePrompt 99 "Compile/install Luarocks and Lua-modules"
			cd /usr/local/src/
			dialogGitClone 99 1 https://github.com/keplerproject/luarocks.git
			cd /usr/local/src/luarocks
			dialogGaugePrompt 99 "Configure Luarocks"
			dialogConfigure 99 1
			dialogGaugePrompt 99 "Compile/install Luarocks"
			dialogMake 99 1 bootstrap
			dialogGaugePrompt 99 "Install LuaSocket"
			luarocks install luasocket > /dev/null 2>&1
			dialogGaugePrompt 99 "Install LuaSec"
			luarocks install luasec > /dev/null 2>&1
			dialogGaugePrompt 99 "Install LuaXML"
			luarocks install luaxml > /dev/null 2>&1
			dialogGaugePrompt 99 "Setup FS for Lua"
			sed -i 's|<!-- <param name="module-directory" value="/usr/lib/lua/5.1/?.so"/> -->|<param name="module-directory" value="/usr/lib/x86_64-linux-gnu/?.so"/>|' /usr/local/freeswitch/conf/autoload_configs/lua.conf.xml
			sed -i 's|<!-- <param name="module-directory" value="/usr/local/lib/lua/5.1/?.so"/> -->|<param name="module-directory" value="/usr/local/lib/lua/5.2/?.so"/>|' /usr/local/freeswitch/conf/autoload_configs/lua.conf.xml
			sed -i 's|<!-- <param name="script-directory" value="/usr/local/lua/?.lua"/> -->|<param name="script-directory" value="/usr/local/share/lua/5.2/?.lua"/>|' /usr/local/freeswitch/conf/autoload_configs/lua.conf.xml
		fi

		dialogGaugePrompt 100 "FS installation complete"
	} > "$MY_TMP_DIR/gauge"
#	}
	dialogGaugeStop
	service freeswitch start > /dev/null 2>&1
}

function fs_all_sounds {
	dialogMake $1 $2 $3 cd-sounds-install
	dialogMake $1 $2 $3 cd-moh-install
	dialogMake $1 $2 $3 samples
	
	dialogMake $1 $2 $3 cd-sounds-ru-install
	dialogMake $1 $2 $3 uhd-sounds-ru-install
	dialogMake $1 $2 $3 hd-sounds-ru-install
	dialogMake $1 $2 $3 sounds-ru-install

	dialogMake $1 $2 $3 cd-sounds-fr-install
	dialogMake $1 $2 $3 uhd-sounds-fr-install
	dialogMake $1 $2 $3 hd-sounds-fr-install
	dialogMake $1 $2 $3 sounds-fr-install
	
	mkdir -p /usr/local/freeswitch/conf/lang/de/phrases
	mkdir -p /usr/local/freeswitch/conf/lang/en/phrases
	mkdir -p /usr/local/freeswitch/conf/lang/fr/phrases
	mkdir -p /usr/local/freeswitch/conf/lang/ru/phrases
	mkdir -p /usr/local/freeswitch/conf/lang/he/phrases
	
	touch /usr/local/freeswitch/conf/lang/de/phrases/empty.xml
	touch /usr/local/freeswitch/conf/lang/en/phrases/empty.xml
	touch /usr/local/freeswitch/conf/lang/fr/phrases/empty.xml
	touch /usr/local/freeswitch/conf/lang/ru/phrases/empty.xml
	touch /usr/local/freeswitch/conf/lang/he/phrases/empty.xml
	
}

function fs_service {
	adduser --disabled-password  --quiet --system --home /usr/local/freeswitch --gecos "FreeSwitch" --ingroup $FS_GROUP $FS_USER > /dev/null 2>&1
	chown -R $FS_USER:$FS_GROUP /usr/local/freeswitch/
	chmod -R ug=rwX,o= /usr/local/freeswitch/
	chmod -R u=rwx,g=rx /usr/local/freeswitch/bin/*

	ln /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch > /dev/null 2>&1
	mkdir /etc/freeswitch > /dev/null 2>&1
	ln /usr/local/freeswitch/conf/freeswitch.xml /etc/freeswitch/freeswitch.xml > /dev/null 2>&1
	 
	chown $FS_USER:$FS_GROUP /etc/freeswitch
	chmod ug=rwx,o= /etc/freeswitch
	 
	mkdir /var/lib/freeswitch > /dev/null 2>&1
	chown $FS_USER:$FS_GROUP /var/lib/freeswitch
	chmod -R ug=rwX,o= /var/lib/freeswitch

	mkdir /var/log/freeswitch > /dev/null 2>&1
	chown $FS_USER:$FS_GROUP /var/log/freeswitch
	chmod -R ug=rwX,o= /var/log/freeswitch

	cp /usr/local/src/freeswitch/debian/freeswitch-sysvinit.freeswitch.default /etc/default/freeswitch
	 
	chown $FS_USER:$FS_GROUP /etc/default/freeswitch
	chmod ug=rw,o= /etc/default/freeswitch
	 
	cp /usr/local/src/freeswitch/debian/freeswitch-sysvinit.freeswitch.init  /etc/init.d/freeswitch
	 
	chown $FS_USER:$FS_GROUP /etc/init.d/freeswitch
	chmod u=rwx,g=rx,o= /etc/init.d/freeswitch

	ln -s /usr/local/freeswitch/bin/fs_cli /usr/bin/ > /dev/null 2>&1
	
	update-rc.d freeswitch defaults
}
function fs_ln_home {
	ln -s /usr/local/freeswitch $MYHOME/freeswitch > /dev/null 2>&1
	ln -s /usr/local/freeswitch/conf $MYHOME/freeswitch-conf > /dev/null 2>&1
	ln -s /usr/local/freeswitch/log $MYHOME/freeswitch-log > /dev/null 2>&1
	ln -s /usr/local/src/freeswitch $MYHOME/freeswitch-src > /dev/null 2>&1
}
function fs_ec2 {
	sed -i "s|default_password=1234|default_password=sf16|" /usr/local/freeswitch/conf/vars.xml

	sed -i 's|<!--<param name="aggressive-nat-detection" value="true"/>-->|<param name="aggressive-nat-detection" value="true"/>|' /usr/local/freeswitch/conf/sip_profiles/internal.xml
	sed -i 's|<!--<param name="NDLB-received-in-nat-reg-contact" value="true"/>-->|<param name="NDLB-received-in-nat-reg-contact" value="true"/>|' /usr/local/freeswitch/conf/sip_profiles/internal.xml
	sed -i 's|<!--<param name="NDLB-force-rport" value="true"/>-->|<param name="NDLB-force-rport" value="true"/>|' /usr/local/freeswitch/conf/sip_profiles/internal.xml
	sed -i 's|<!--<param name="NDLB-broken-auth-hash" value="true"/>-->|<param name="NDLB-broken-auth-hash" value="true"/>|' /usr/local/freeswitch/conf/sip_profiles/internal.xml
	sed -i 's|<!--<param name="enable-timer" value="false"/>-->|<param name="enable-timer" value="false"/>|' /usr/local/freeswitch/conf/sip_profiles/internal.xml
	sed -i 's|<!--<param name="multiple-registrations" value="contact"/>-->|<param name="multiple-registrations" value="true"/>|' /usr/local/freeswitch/conf/sip_profiles/internal.xml
	sed -i 's|<param name="ext-rtp-ip" value="auto-nat"/>|<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>|' /usr/local/freeswitch/conf/sip_profiles/internal.xml
	sed -i 's|<param name="ext-sip-ip" value="auto-nat"/>|<param name="ext-sip-ip" value="$${external_sip_ip}"/>|' /usr/local/freeswitch/conf/sip_profiles/internal.xml
	sed -i 's|<param name="auth-calls" value="$${internal_auth_calls}"/>|<param name="auth-calls" value="true"/>|' /usr/local/freeswitch/conf/sip_profiles/internal.xml

	sed -i 's|<!--<param name="aggressive-nat-detection" value="true"/>-->|<param name="aggressive-nat-detection" value="true"/>|' /usr/local/freeswitch/conf/sip_profiles/external.xml
	sed -i 's|<param name="ext-rtp-ip" value="auto-nat"/>|<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>|' /usr/local/freeswitch/conf/sip_profiles/external.xml
	sed -i 's|<param name="ext-sip-ip" value="auto-nat"/>|<param name="ext-sip-ip" value="$${external_sip_ip}"/>|' /usr/local/freeswitch/conf/sip_profiles/external.xml
	echo '<param name="NDLB-force-rport" value="true"/>' >> /usr/local/freeswitch/conf/sip_profiles/external.xml

	sed -i 's|<!-- <param name="rtp-start-port" value="16384"/> -->|<param name="rtp-start-port" value="11000"/>|' /usr/local/freeswitch/conf/autoload_configs/switch.conf.xml
	sed -i 's|<!-- <param name="rtp-end-port" value="32768"/> -->|<param name="rtp-end-port" value="12000"/>|' /usr/local/freeswitch/conf/autoload_configs/switch.conf.xml

	sed -i "s|domain=\$\${local_ip_v4}|domain=$MYSITE|" /usr/local/freeswitch/conf/vars.xml

	sed -i 's|<X-PRE-PROCESS cmd="set" data="bind_server_ip=auto"/>|<X-PRE-PROCESS cmd="set" data="bind_server_ip=$EC2_EXT_IP"/>|' /usr/local/freeswitch/conf/vars.xml
	sed -i 's|<X-PRE-PROCESS cmd="set" data="external_rtp_ip=stun:stun.freeswitch.org"/>|<X-PRE-PROCESS cmd="set" data="external_rtp_ip=$EC2_EXT_IP"/>|' /usr/local/freeswitch/conf/vars.xml
	sed -i 's|<X-PRE-PROCESS cmd="set" data="external_sip_ip=stun:stun.freeswitch.org"/>|<X-PRE-PROCESS cmd="set" data="external_sip_ip=$EC2_EXT_IP"/>|' /usr/local/freeswitch/conf/vars.xml
}
function fs_certs {
	mkdir /usr/local/freeswitch/certs > /dev/null 2>&1
# по другому уже, проверить!!!
	cat $MYCERT_DIR/$MYCERT_CRT $MYCERT_DIR/$MYCERT_KEY $MYCERT_DIR/$MYCERT_CA > /usr/local/freeswitch/certs/wss.pem
	cat $MYCERT_DIR/$MYCERT_CRT $MYCERT_DIR/$MYCERT_KEY $MYCERT_DIR/$MYCERT_CA > /usr/local/freeswitch/certs/agent.pem
	cp $MYCERT_DIR/$MYCERT_CA /usr/local/freeswitch/certs/cafile.pem
}

### END ### fs.inc.sh #############################################################################
