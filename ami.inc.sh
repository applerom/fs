################################################################################
### My AMILinux Setup standard function
################################################################################
function deb8set {	
echo -e "${BLUE}################################################################################$NOCOLOUR"
echo -e "${YELLOW}Set ${RED}$PSEUDONAME${YELLOW} Setup default script"
echo -e "${BLUE}################################################################################$NOCOLOUR"

get_var_txt_def MYSITE "Enter FQDN of your computer/server/site: " `hostname`
hostname $MYSITE
echo -e "${BLUE}################################################################################$NOCOLOUR"

### Update system ################################################################################
echo -e "${WHITEBRIGHT}Update system"
echo -e "--------------------------------------------------------------------------------$NOCOLOUR"
apt-get -y update
echo -e "${WHITEBRIGHT}--------------------------------------------------------------------------------$NOCOLOUR"
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
echo -e "${BLUE}################################################################################$NOCOLOUR"

echo -e "${WHITEBRIGHT}Install some useful packets:${NOCOLOUR}"
echo -e "$MyX mc (Midnight Commander)"
echo -e "$MyX ftp (native FTP-client)"
echo -e "$MyX host (ping)"
echo -e "$MyX zip (zip-packer/unpacker)"
echo -e "$MyX bzip2 (bz2-packer/unpacker)"
echo -e "$MyX lynx (HTML-browser for text mode)"
echo -e "$MyX debconf-utils (utils for config deb-packets)"
echo -e "${WHITEBRIGHT}--------------------------------------------------------------------------------${NOCOLOUR}"
apt-get install -y mc ftp host bzip2 zip curl lynx debconf-utils
echo -e "${BLUE}################################################################################$NOCOLOUR"


### Email-server ################################################################################
echo "exim4-config exim4/dc_eximconfig_configtype select internet site; mail is sent and received directly using SMTP" | debconf-set-selections
echo "exim4-config exim4/dc_local_interfaces string 127.0.0.1 ; ::1" | debconf-set-selections
if [ $(dpkg-query -W -f='${Status}' exim4 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
	echo -e "${WHITEBRIGHT}Install Mail-server (Exim4)"
	echo -e "--------------------------------------------------------------------------------$NOCOLOUR"
	apt-get install -y exim4
else
	echo -e "${WHITEBRIGHT}Mail-server (Exim4) already installed - configure it"
	echo -e "--------------------------------------------------------------------------------$NOCOLOUR"
	dpkg-reconfigure exim4-config -fnoninteractive
fi
echo -e "${BLUE}################################################################################$NOCOLOUR"

### FTP-server ################################################################################
if ! dpkg -S proftpd > /dev/null 2>&1; # if proftpd not installed
then
	echo "proftpd-basic shared/proftpd/inetd_or_standalone select standalone" | debconf-set-selections

	echo -e "${WHITEBRIGHT}Install FTP-server (proftpd)"
	echo -e "--------------------------------------------------------------------------------$NOCOLOUR"
	apt-get install -qy proftpd
else
	echo -e "${WHITEBRIGHT}FTP-server (proftpd) already installed."
	echo -e "--------------------------------------------------------------------------------$NOCOLOUR"
fi

sed -i 's|# DefaultRoot.*~|DefaultRoot ~|' /etc/proftpd/proftpd.conf
sed -i 's|# PassivePorts.*|PassivePorts 12345 12399|' /etc/proftpd/proftpd.conf
sed -i "s|# MasqueradeAddress.*|MasqueradeAddress $EXT_IP|" /etc/proftpd/proftpd.conf
if ! grep -q "/etc/proftpd/ftpd.passwd" /etc/proftpd/proftpd.conf ; then # protect from repeated running
	echo "AuthUserFile    /etc/proftpd/ftpd.passwd" >> /etc/proftpd/proftpd.conf
fi

echo -e "$WHITEBRIGHT"
echo -e "$MyX Add default FTP-user and setup FTP-server"
echo -e "--------------------------------------------------------------------------------$NOCOLOUR"
echo 'QAZ6yhnQAZ6yhn' | ftpasswd --passwd --stdin --file=/etc/proftpd/ftpd.passwd --name=rom --shell=/bin/false --home=/var/www --uid=`sed -n 's|ftp:x:\([1-9][0-9]*\).*$|\1|p' /etc/passwd` --gid=33 --sha512 > /dev/null 2>&1

service proftpd restart
update-rc.d proftpd defaults
echo -e "${BLUE}################################################################################$NOCOLOUR"


### PS1 setup ################################################################################
echo -e "$MyX Set nice prompt string"

MYPS1="PS1='" #init/begin
MYPS1+="$Blue"
MYPS1+="__________________________________________________________" # long string of _spaces_ for comfortable reading
MYPS1+=" \`if [ \$? = 0 ]; then echo \"$Checkmark\"; else echo \"$FancyX\" ; fi\`" # 0 or 1 of last operation
MYPS1+=" \`if [[ \$EUID == 0 ]]; then echo \"\"; else echo \"$Red\\u$White@\" ; fi\`" # show current user (or nothing for root)
MYPS1+="$Yellow\\H" # Hostname
MYPS1+=" $Blue$MyDateTime\n" # current time & date and new string
MYPS1+=" $Cyan\\w $GreenLight\\\$$NoColour " # current dir + $
MYPS1+="'" #end of PS1

if ! grep -q "sudo mc" $MYHOME/$AUTOEXEC_FILE ; then # protect from repeated running
	echo $MYPS1 >> $MYHOME/$AUTOEXEC_FILE
	echo "sudo -H mc" >> $MYHOME/$AUTOEXEC_FILE

	echo $MYPS1 >> /root/.bashrc
fi

### Other tunings ################################################################################
addgroup ftp www-data > /dev/null 2>&1
mkdir -p /var/www > /dev/null 2>&1
chown -R ftp:www-data /var/www

echo -e "$MyX Some tuning of editor Nano: for xml-files and some common commands"
sed -i 's|color green|color brightgreen|' /usr/share/nano/xml.nanorc
sed -i 's~(cat|cd|chmod|chown|cp|echo|env|export|grep|install|let|ln|make|mkdir|mv|rm|sed|set|tar|touch|umask|unset)~(apt-get|awk|cat|cd|chmod|chown|cp|cut|echo|env|export|grep|install|let|ln|make|mkdir|mv|rm|sed|set|tar|touch|umask|unset)~' /usr/share/nano/sh.nanorc

echo -e "$MyX Install correct shell for some packets (to ex. FTP-server)"
if ! grep -q "/bin/false" /etc/shells ; then # protect from repeated running
	echo "/bin/false" >> /etc/shells
fi

echo -e "$MyX Install own script in boot"

if [ ! -f $MYSH ] ; then # protect from repeated running
	cat <<EOF >>$MYSH
sudo hostname $MYSITE
echo -e $OS_VER_SHOW
df -k | awk '\$NF=="/"{printf "Disk Usage: %s\n", \$5}'
EOF
fi

sed -i 's|/ ext4 defaults 1 1|/ ext4 defaults,acl,barrier=0 1 1|' /etc/fstab

echo -e "$MyX Create useful symlinks: /etc, /var/www, /usr/local/src, /var/log"
ln -s /var/www $MYHOME > /dev/null 2>&1
ln -s /etc $MYHOME > /dev/null 2>&1
ln -s /usr/local/src $MYHOME > /dev/null 2>&1
ln -s /var/log $MYHOME > /dev/null 2>&1
}
### END ### ami.inc.sh #############################################################################
