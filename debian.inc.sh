################################################################################
### Debian-based OS Setup standard function
################################################################################
function debian {	

debian1=$(whiptail --title "Current OS is $PSEUDONAME" --separate-output --cancel-button "Exit" \
--backtitle  "" \
--checklist "Select what to install and configure" 20 80 12 \
"UpdateOS" "Update current OS" ON \
"Mail-server" "Install/configure Mail-server" ON \
"FTP-server" "Install/configure FTP-server" ON \
"MasqueradeIP" "Use masquerade IP for FTP-server" OFF \
"DefaultFTPuser" "Set default FTP-user" ON \
"NicePrompt" "Set nice prompt string" ON \
"WebDir" "Create/chown Web drirectory /var/www" ON \
"NanoTune" "Some tweaks for Nano-editor" ON \
"FalseShell" "Install shell /bin/false" ON \
"BootScript" "Install custom script in boot" ON \
"DiskACL" "Add ACL for all disks" OFF \
"Symlinks" "Create useful symlinks" ON 3>&1 1>&2 2>&3 )
if [ $? != 0 ]; then exit 0; fi

	export DEBIAN_FRONTEND=noninteractive
##	echo 'Dpkg::Progress-Fancy "1";' > /etc/apt/apt.conf.d/99progressbar

 	dialogGaugeStart "Set up and configure $PSEUDONAME" "Please wait" 8 70 0
	{
		dialogGaugePrompt 2 "Update system"
		dialogAptGet 2 8 update

		dialogGaugePrompt 10 "Upgrade system"
		if [[ $(echo $debian1 | grep -c "UpdateOS") == "1" ]]  ; then
			dialogAptGet 10 50 dist-upgrade
		fi

#		apt-get -yq remove ftp host bzip2 zip lynx exim4 proftpd > /dev/null 2>&1		#testonly

		dialogGaugePrompt 60 "Install useful packets"
		dialogAptGet 60 16 install mc ftp host bzip2 zip curl lynx debconf-utils


		if [[ $(echo $debian1 | grep -c "Mail-server") == "1" ]]  ; then
			### Email-server ################################################################################
			echo "exim4-config exim4/dc_eximconfig_configtype select internet site; mail is sent and received directly using SMTP" | debconf-set-selections
			echo "exim4-config exim4/dc_local_interfaces string 127.0.0.1 ; ::1" | debconf-set-selections
			if [ $(dpkg-query -W -f='${Status}' exim4 2>/dev/null | grep -c "ok installed") -eq 0 ];
			then
				dialogGaugePrompt 76 "Install and configure Mail-server (Exim4)"
				dialogAptGet 76 6 install exim4
			else
				dialogGaugePrompt 76 "Configure Mail-server (Exim4)"
				dpkg-reconfigure exim4-config -fnoninteractive 2>/dev/null
			fi
		fi


		if [[ $(echo $debian1 | grep -c "FTP-server") == "1" ]]  ; then
			### FTP-server ################################################################################
			echo "proftpd-basic shared/proftpd/inetd_or_standalone select standalone" | debconf-set-selections
			dialogGaugePrompt 82 "Install / configure FTP-server (proftpd)"
			dialogAptGet 82 6 install proftpd

			sed -i 's|# DefaultRoot.*~|DefaultRoot ~|' /etc/proftpd/proftpd.conf
			sed -i 's|# PassivePorts.*|PassivePorts 12345 12399|' /etc/proftpd/proftpd.conf
			if [[ $(echo $debian1 | grep -c "MasqueradeIP") == "1" ]]  ; then
				sed -i "s|# MasqueradeAddress.*|MasqueradeAddress $EXT_IP|" /etc/proftpd/proftpd.conf
			fi
			if ! grep -q "/etc/proftpd/ftpd.passwd" /etc/proftpd/proftpd.conf ; then # protect from repeated running
				echo "AuthUserFile    /etc/proftpd/ftpd.passwd" >> /etc/proftpd/proftpd.conf
			fi
			if [[ $(echo $debian1 | grep -c "DefaultFTPuser") == "1" ]]  ; then
				echo 'QAZ6yhnQAZ6yhn' | ftpasswd --passwd --stdin --file=/etc/proftpd/ftpd.passwd --name=rom --shell=/bin/false --home=/var/www --uid=`sed -n 's|ftp:x:\([1-9][0-9]*\).*$|\1|p' /etc/passwd` --gid=33 --sha512 > /dev/null 2>&1
			fi
			service proftpd restart  > /dev/null 2>&1
			update-rc.d proftpd defaults  > /dev/null 2>&1
		fi

		dialogGaugePrompt 93 "Set nice Prompt"
		if [[ $(echo $debian1 | grep -c "NicePrompt") == "1" ]]  ; then
			MYPS1="PS1='" #init/begin
			MYPS1+="$Blue"
			MYPS1+="__________________________________________________________" # long string of _spaces_ for comfortable reading
			MYPS1+=" \`if [ \$? = 0 ]; then echo \"$Checkmark\"; else echo \"$FancyX\" ; fi\`" # 0 or 1 of last operation
			MYPS1+=" \`if [[ \$EUID == 0 ]]; then echo \"\"; else echo \"$Red\\u$White@\" ; fi\`" # show current user (or nothing for root)
			MYPS1+="$Yellow\\H" # Hostname
			MYPS1+=" $Blue$MyDateTime\n" # current time & date and new string
			MYPS1+=" $Cyan\\w $GreenLight\\\$$NoColour " # current dir + $
			MYPS1+="'" #end of PS1
			sudomc="sudo -H mc"
			if ! grep -q "$sudomc" $MYHOME/$AUTOEXEC_FILE ; then # protect from repeated running
				echo $MYPS1 >> $MYHOME/$AUTOEXEC_FILE
				echo $sudomc >> $MYHOME/$AUTOEXEC_FILE

				echo $MYPS1 >> /root/.bashrc
			fi
		fi

		dialogGaugePrompt 94 "Create/chown Web drirectory"
		if [[ $(echo $debian1 | grep -c "WebDir") == "1" ]]  ; then
			## addgroup ftp www-data > /dev/null 2>&1
			mkdir -p /var/www > /dev/null 2>&1
			## chown -R ftp:www-data /var/www
			chown -R ftp: /var/www
		fi

		dialogGaugePrompt 95 "Some tweaks for Nano-editor"
		if [[ $(echo $debian1 | grep -c "NanoTune") == "1" ]]  ; then
			sed -i 's|color green|color brightgreen|' /usr/share/nano/xml.nanorc
			sed -i 's~(cat|cd|chmod|chown|cp|echo|env|export|grep|install|let|ln|make|mkdir|mv|rm|sed|set|tar|touch|umask|unset)~(apt-get|awk|cat|cd|chmod|chown|cp|cut|echo|env|export|grep|install|let|ln|make|mkdir|mv|rm|sed|set|tar|touch|umask|unset)~' /usr/share/nano/sh.nanorc
		fi
		
		dialogGaugePrompt 96 "Install shell /bin/false"
		if [[ $(echo $debian1 | grep -c "FalseShell") == "1" ]]  ; then
			if ! grep -q "/bin/false" /etc/shells ; then # protect from repeated running
				echo "/bin/false" >> /etc/shells
			fi
		fi
		
		
		dialogGaugePrompt 97 "Install custom script for startup"
		if [[ $(echo $debian1 | grep -c "BootScript") == "1" ]]  ; then
			if [ ! -f $MYSH ] ; then # protect from repeated running
				cat <<EOF >>$MYSH
sudo hostname $MYSITE
echo -e "Debian `cat /etc/debian_version`"
df -k | awk '\$NF=="/"{printf "Disk Usage: %s\n", \$5}'
EOF
			fi
		fi

		dialogGaugePrompt 98 "Add ACL for all disks"
		if [[ $(echo $debian1 | grep -c "DiskACL") == "1" ]]  ; then
			sed -i 's|/ ext4 defaults 1 1|/ ext4 defaults,acl,barrier=0 1 1|' /etc/fstab
		fi

		dialogGaugePrompt 99 "Create useful symlinks for home-directory"
		if [[ $(echo $debian1 | grep -c "Symlinks") == "1" ]]  ; then
			ln -s /var/www $MYHOME > /dev/null 2>&1
			ln -s /etc $MYHOME > /dev/null 2>&1
			ln -s /usr/local/src $MYHOME > /dev/null 2>&1
			ln -s /var/log $MYHOME > /dev/null 2>&1
		fi
			
		dialogGaugePrompt 100 "Installation complete"
	} > "$MY_TMP_DIR/gauge"
	dialogGaugeStop

}
### END ### debian.inc.sh #############################################################################
