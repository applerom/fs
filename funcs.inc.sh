################################################################################
### Main FUNCS
################################################################################

function get_var_txt {
	local _getname
	read -p "$2" _getname
	if [ -z $_getname ]; then
		read -p "Please do previous step or exit! $2" _getname
		if [ -z $_getname ]; then
			echo "No entered value, exit."
			exit 1
		else
			eval $1=$_getname
		fi
	else
		eval $1=$_getname
	fi

}

function get_var_txt_def {
	local _getname
	_getname=$(whiptail --title "$2" --inputbox "$4" 10 60 $3 3>&1 1>&2 2>&3)
	if [[ $? != 0 ]]; then
		eval $1=$3
	else
		eval $1=$_getname
	fi
}

function get_pas_txt_def {
	local _getname
	_getname=$(whiptail --title "$2" --passwordbox "$4" 10 60 $3 --backtitle "Default password is $3" 3>&1 1>&2 2>&3)
	if [[ $? != 0 ]]; then
		eval $1=$3
	else
		eval $1=$_getname
	fi
}

function get_yes {
	local mykey
        read -p "$1[press Y or y for agree, any other for disagree] " -n 1 mykey
	echo ""
        if [[ $mykey == "y" ]] || [[ $mykey == "Y" ]] ; then
		return 0
        else
		return 1
	fi
}

function pause {
	read -p "press any key..." -n 1 MYKEY
	echo ""
}

function make_backup {
	local i=0
	while [[ -e $1.bak.$i ]] ; do
		let i++
	done
	mv $1 $1.bak.$i > /dev/null 2>&1
}

###GET_OS_INFO###

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

#########
function get_os_info () {
	OS=`lowercase \`uname\``
	KERNEL=`uname -r`
	BITS=`uname -m`

	if [ "${OS}" = "linux" ] ; then
	  # Figure out which OS we are running on
	  if [ -f /etc/os-release ]; then
		  source /etc/os-release
		  DIST_TYPE=$ID
		  DIST=$NAME
		  REV=$VERSION_ID
		  PSEUDONAME=$PRETTY_NAME
	  elif [ -f /usr/lib/os-release ]; then
		  source /usr/lib/os-release
		  DIST_TYPE=$ID
		  DIST=$NAME
		  REV=$VERSION_ID
	  elif [ -f /etc/redhat-release ]; then
		  DIST_TYPE='RedHat'
		  DIST=`cat /etc/redhat-release |sed s/\ release.*//`
		  PSEUDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
		  REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
	  elif [ -f /etc/system-release ]; then
		  if grep "Amazon Linux AMI" /etc/system-release; then
			DIST_TYPE='amzn'
		  fi
		  DIST=`cat /etc/system-release |sed s/\ release.*//`
		  PSEUDONAME=`cat /etc/system-release | sed s/.*\(// | sed s/\)//`
		  REV=`cat /etc/system-release | sed s/.*release\ // | sed s/\ .*//`
	  elif [ -f /etc/SuSE-release ] ; then
		  DIST_TYPE='SuSe'
		  PSEUDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
		  REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
	  elif [ -f /etc/mandrake-release ] ; then
		  DIST_TYPE='Mandrake'
		  PSEUDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
		  REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
	  elif [ -f /etc/debian_version ] ; then
		  DIST_TYPE='Debian'
		  DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
		  PSEUDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
		  REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
	  fi
	  if [ -f /etc/UnitedLinux-release ] ; then
		  DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
	  fi
	fi

	if [ "{$OS}" == "darwin" ]; then
		OS=mac
	fi

	DIST_TYPE=`lowercase $DIST_TYPE`
	UNIQ_OS_ID="${DIST_TYPE}-${KERNEL}-${BITS}"

}

function get_ext_ip {
	EXT_IP=`wget -T 10 -O- http://checkip.amazonaws.com 2>/dev/null`
	if [[ $(echo $EXT_IP | grep -c ".*\..*\..*\..*") != "1" ]]  ; then
		EXT_IP=`wget -T 10 -O- http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null`
		if [[ $(echo $EXT_IP | grep -c ".*\..*\..*\..*") != "1" ]] ; then
			echo "External IP not detected, exit."
			exit 1
		fi
	fi
}

### END ### funcs.inc.sh #############################################################################
