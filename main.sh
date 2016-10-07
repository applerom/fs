#!/bin/bash

# main.sh script
SCRIPT_VERSION=0.50
MYCERT_KEY=vpro.by.key.pem
MYCERT_CRT=2_vpro.by.crt
MYCERT_CA=1_root_bundle.crt
echo "MYCERT_KEY=$MYCERT_KEY" 	> vars.cfg
echo "MYCERT_CRT=$MYCERT_CRT"	>> vars.cfg
echo "MYCERT_CA=$MYCERT_CA" 	>> vars.cfg
	
################################################################################
if [[ $UID != 0 ]] ; then 
	whiptail --infobox "Run only under root! Add sudo at the begin and repeat your command again."
	exit 1
fi

MY_TMP_DIR=$(mktemp -d /tmp/${SCRIPT_VERSION}_scripts.XXX) # create_tmp_dir
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
source_my_inc_file colours.inc.sh
source_my_inc_file funcs.inc.sh
source_my_inc_file whiptail.inc.sh

source_my_inc_file vpc.inc.sh

function copy_files_to_remote_system {
	#chmod 600 $KEY_PAIR
	echo "mkdir at $PublicIpAddress"
	ssh -o StrictHostKeyChecking=no -t -i $KEY_PAIR $LINUX_USER@$PublicIpAddress "mkdir $RSDIR certs"
	echo "copy files"

	echo "SiteName=$SiteName" >> vars.cfg
	echo "AvailabilityZone=$AvailabilityZone" >> vars.cfg

	scp -i $KEY_PAIR ./certs/* $LINUX_USER@$PublicIpAddress:certs
	scp -i $KEY_PAIR ./* $LINUX_USER@$PublicIpAddress:$RSDIR
}
################################################################################
### MAIN
################################################################################

#select_aws_cfg
#start_vpc
#source_my_inc_file vpc-fd917299.cfg

KEY_PAIR=sec16all.pem
#LINUX_USER=ec2-user
LINUX_USER=admin
PublicIpAddress=10.100.1.121
SiteName=vpro.by
AvailabilityZone=us-east-1b

RSDIR="./fs$SCRIPT_VERSION"
copy_files_to_remote_system

#exit 0


echo "run script"
ssh -o StrictHostKeyChecking=no -t -i $KEY_PAIR $LINUX_USER@$PublicIpAddress "sudo bash -c $RSDIR/main2.sh"

exit 0

### END ### main.sh #############################################################################
