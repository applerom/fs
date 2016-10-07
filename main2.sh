#!/bin/bash

# main2.sh script
SCRIPT_VERSION=0.50
MYSITE=my.site.com
MY_DEPLOY_SERVER=52.38.7.241
MYSH=/etc/profile.d/my.sh

### MAIN 2 ################################################################################
if [[ $UID != 0 ]] ; then 
	whiptail --infobox "Run only under root! Add sudo at the begin and repeat your command again."
	exit 1
fi

MY_TMP_DIR=$(mktemp -d /tmp/FS_scripts.XXX) # create_tmp_dir
trap "rm -R ${MY_TMP_DIR}" SIGTERM SIGINT EXIT
if [[ ! -O ${MY_TMP_DIR} ]]; then # Check that the dir exists and is owned by our euid (root)
	echo "Unable to create temporary directory MY_TMP_DIR."
	exit 1
fi
chmod 700 $MY_TMP_DIR

function source_my_inc_file {	
	if [ -f $1 ] ; then
		source $1
	else
		echo "Not found file $1"
		exit 1
	fi
}
source_my_inc_file vars.cfg
source_my_inc_file colours.inc.sh
source_my_inc_file funcs.inc.sh
source_my_inc_file aws.inc.sh
source_my_inc_file debian.inc.sh
source_my_inc_file odbc.inc.sh
source_my_inc_file fs.inc.sh
source_my_inc_file fusion.inc.sh
source_my_inc_file whiptail.inc.sh

################################################################################
### MAIN 2
################################################################################

get_os_info
get_ext_ip
echo "1"
whiptail --title "FreeSwitch Install and Setup script, ver. $SCRIPT_VERSION" --yes-button "Continue" --no-button "Exit" \
--yesno \
"\
Current OS: $PSEUDONAME \n\
 DIST_TYPE: $DIST_TYPE \n\
 KERNEL: ${KERNEL} \n\
 VERSION_ID: $VERSION_ID \n\
 BITS: ${BITS} \n\
\n\
Current Hostname: `hostname` \n\
External IP: $EXT_IP \
 \n\
" 15 80
if [ $? != 0 ]; then exit 0; fi

case $DIST_TYPE in
	debian)
		if [[ $VERSION_ID != "8" ]] ; then
			whiptail --infobox "Only Debian version 8 is supported in this current ($SCRIPT_VERSION) script version"
			exit 1
		fi
		MYHOME=/home/admin
		OS_VER_SHOW="Debian `cat /etc/debian_version`"
		AUTOEXEC_FILE=".bashrc"
	;;
	ubuntu)
		MYHOME=/home/ubuntu
		OS_VER_SHOW=""
		AUTOEXEC_FILE=".profile"
	;;
	amzn)
		whiptail --infobox "$PSEUDONAME is not support in this current ($SCRIPT_VERSION) script version"
		exit 1
	;;
	*)
		whiptail --infobox "Only for Debian 8 or Ubuntu 14 LTS in this current ($SCRIPT_VERSION) script version"
		exit 1
	;;
esac
MYCERT_DIR=$MYHOME/certs

get_var_txt_def MYSITE "Enter FQDN of your computer/server/site" $SiteName "Example: my.secrom.com, current hostname is `hostname`"
hostname $MYSITE


MM1=$(whiptail --title "Current OS is $PSEUDONAME" --separate-output --cancel-button "Exit" \
--backtitle  "" \
--checklist "Select what to do and install" 15 80 6 \
"OS-setting" "Setup your OS - install useful packets etc" ON \
"AWS-services" "Install AWS-sevices (Amazon Inspector, Log Agent etc.)" ON \
"ODBC" "Install ODBC-driver for MySQL/PostgreSQL" ON \
"FreeSwitch" "Install last version FreeSwitch + Lua 5.2" ON \
"FusionPBX" "Install FusionPBX" ON \
"SlowExecute" "Make small pauses between installations steps" OFF 3>&1 1>&2 2>&3 )
if [ $? != 0 ]; then exit 0; fi

if [[ $(echo $MM1 | grep -c "OS-setting") == "1" ]]  ; then debian ; fi
if [[ $(echo $MM1 | grep -c "AWS-services") == "1" ]]  ; then aws_services_install ; fi
if [[ $(echo $MM1 | grep -c "ODBC") == "1" ]]  ; then odbc_debian ; fi
if [[ $(echo $MM1 | grep -c "FreeSwitch") == "1" ]]  ; then fs_install ; fi
if [[ $(echo $MM1 | grep -c "FusionPBX") == "1" ]]  ; then fusion ; fi
exit 0


### END ### main2.sh #############################################################################
