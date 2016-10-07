### whiptail.inc.sh #############################################################################
dialogAptGet()
{
	download_start=$1
	download_range=$2
	mkfifo -m 0600 "$MY_TMP_DIR/apt-status"
	aptcommand=$3
	case $aptcommand in
		update)
			exec 3>&2
			exec 2> /dev/null
			apt-get -y update > "$MY_TMP_DIR/apt-status" &
			exec 2>&3
		;;
		dist-upgrade)
			# > /dev/null 1>&2 3>
			exec 3>&2
			exec 2> /dev/null
			apt-get -y --show-progress -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold dist-upgrade > "$MY_TMP_DIR/apt-status" &
			exec 2>&3
		;;
		install)
			shift 3
			exec 3>&2
			exec 2> /dev/null
			apt-get -qyf --show-progress -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold install "$@" > "$MY_TMP_DIR/apt-status" &
			exec 2>&3
		;;
		*)
			shift 2
			exec 3>&2
			exec 2> /dev/null
			apt-get -qyf --show-progress -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold install "$@" > "$MY_TMP_DIR/apt-status" &
			exec 2>&3
		;;
	esac

	_pget=0
	_p=$download_start
	_text=""
	while read get1x httpredir jessie_main libcurl3; do
		case $get1x in
			Progress:)
				download_start_new=$(( download_start + ((_pget * download_range) / 100) ))
				download_range_new=$(( download_range - download_start_new + download_start ))
				if [[ $httpredir != "[" ]] ; then
					_p1=100
				else
					_p1=$(echo $jessie_main | sed 's|\([0-9]*\).*|\1|1')
				fi
				_p=$(( download_start_new + ((_p1 * download_range_new) / 100 ) ))
	#			_text=$(echo $jessie_main | sed 's|\([0-9]*\).*|\1|1')
	##			_text=$(echo $jessie_main | grep ".*\%")
				echo "XXX"
				echo $_p
				echo $_text
##				echo "_pget=$_pget _p1=$_p1 ds_new=$download_start_new dr_new=$download_range_new | '$httpredir' | '$_text'"
				echo "XXX"
			;;
			Get:*)
				case $aptcommand in
					update)
						_text="$get1x $jessie_main"
					;;
					dist-upgrade)
						_text="$get1x $libcurl3"
					;;
					install)
						_text="$get1x $libcurl3"
					;;
					*)
						_text="$get1x $jessie_main"
					;;
				esac
				if (( _pget < 50 )); then ((_pget++)) ; fi
				_p=$(( download_start + ((_pget * download_range) / 100) ))
				echo "XXX"
				echo $_p
				echo $_text
				echo "XXX"
			;;
			Hit)
				_text="Hit $jessie_main"
				if (( _pget < 50 )); then ((_pget++)) ; fi
				_p=$(( download_start + ((_pget * download_range) / 100) ))
				echo "XXX"
				echo $_p
				echo $_text
				echo "XXX"
			;;
			Ign)
				_text="Ign $jessie_main"
				if (( _pget < 50 )); then ((_pget++)) ; fi
				_p=$(( download_start + ((_pget * download_range) / 100) ))
				echo "XXX"
				echo $_p
				echo $_text
				echo "XXX"
			;;
			Unpacking)
				_text="Unpacking $httpredir"
				echo "XXX"
				echo $_p
				echo $_text
				echo "XXX"
			;;
			Setting)
				_text="Setting up $jessie_main"
				echo "XXX"
				echo $_p
				echo $_text
				echo "XXX"
			;;
			*)
	###			echo "unexpected apt-get status $status" 1>&2
	###			exit 1
			;;
		esac
	done < "$MY_TMP_DIR/apt-status"
	wait $!
	rm -f "$MY_TMP_DIR/apt-status"
}
dialogGitClone()
{
	download_start=$1
	download_range=$2
	_p=$download_start
	mkfifo -m 0600 "$MY_TMP_DIR/git-status"
	shift 2
	git clone --progress -q "$@" 2> "$MY_TMP_DIR/git-status" &
	#git clone --progress "$@" 1>&2 2> "$MY_TMP_DIR/git-status" &
#Receiving objects: 100% (279309/279309), 122.33 MiB | 3.25 MiB/s, done.
	while read receiving objects percents ; do
		case $receiving in
			Receiving)
				download_range_new=$(( (download_range * 85) / 100 ))
				_p1=$(echo $percents | sed 's|.*\([0-9]*\)\%.*|\1|1')
				_p=$(( download_start + ((_p1 * download_range_new) / 100 ) ))
				echo "XXX"
				echo $_p
				echo "Receiving objects"
				echo "XXX"
			;;
			Resolving)
				download_start_new=$(( download_start + download_range_new ))
				download_range_new=$(( download_range - download_range_new ))
				_p1=$(echo $percents | sed 's|.*\([0-9]*\)\%.*|\1|1')
				_p=$(( download_start_new + ((_p1 * download_range_new) / 100 ) ))
				echo "XXX"
				echo $_p
				echo "Resolving deltas"
				echo "XXX"
			;;
			*)
			;;
		esac
	done < "$MY_TMP_DIR/git-status"
	wait $!
	rm -f "$MY_TMP_DIR/git-status"
}

dialogBootstrap()
{
	download_start=$1
	download_range=$2
	_p=$download_start
	_p1=0
	mkfifo -m 0600 "$MY_TMP_DIR/bootstrap-status"
	shift 2
	./bootstrap.sh "$@" > "$MY_TMP_DIR/bootstrap-status" 2>&1 &
#configure.ac:47: installing 'config/compile'
	while read configure installing config ; do
		case $installing in
			installing)
				if (( _p1 < 40 )); then ((_p1++)) ; fi
				_p=$(( download_start + ((_p1 * download_range) / 40 ) ))
				echo "XXX"
				echo $_p
				echo "$configure $config"
				echo "XXX"
			;;
			*)
			;;
		esac
	done < "$MY_TMP_DIR/bootstrap-status"
	wait $!
	rm -f "$MY_TMP_DIR/bootstrap-status"
}

dialogConfigure()
{
	download_start=$1
	download_range=$2
	_p=$download_start
	_p1=0
	_p2=0
	mkfifo -m 0600 "$MY_TMP_DIR/configure-status"
	shift 2
	exec 3>&2
	exec 2> /dev/null
	./configure "$@" > "$MY_TMP_DIR/configure-status" &
	exec 2>&3
#checking for tiffio.h... yes
	while read checking _for tiffio _yes ; do
		case $checking in
			checking)
#				((_p2++))
				if (( _p1 < 2200 )); then ((_p1++)) ; fi
				_p=$(( download_start + ((_p1 * download_range) / 2200 ) ))
				echo "XXX"
				echo $_p
				echo "$checking $_for $tiffio $_yes"
#				echo "_p2=$_p2 || $checking $_for $tiffio $_yes"
				echo "XXX"
			;;
			*)
			;;
		esac
	done < "$MY_TMP_DIR/configure-status"
	wait $!
	rm -f "$MY_TMP_DIR/configure-status"
}

dialogMake()
{
	download_start=$1
	download_range=$2
	p2_range=$3
	_p=$download_start
	_p1=0
	_p2=0
	mkfifo -m 0600 "$MY_TMP_DIR/make-status"
	shift 3
	exec 3>&2
	exec 2> /dev/null
	make "$@" > "$MY_TMP_DIR/make-status" &
	exec 2>&3
#make[3]: Entering directory `/usr/local/src/freeswitch/libs/apr-util'
	while read _make _entering _directory _util ; do
		case $_entering in
			Entering)
#				((_p2++))
				if (( _p1 < p2_range )); then ((_p1++)) ; fi
				_p=$(( download_start + ((_p1 * download_range) / p2_range ) ))
				echo "XXX"
				echo $_p
				echo "Make $_util"
#				echo "_p2=$_p2 || $_make $_entering $_directory $_util"
				echo "XXX"
			;;
			*)
			;;
		esac
	done < "$MY_TMP_DIR/make-status"
	wait $!
	rm -f "$MY_TMP_DIR/make-status"
}


# Update a progress gauge
# dialogGaugePrompt percent text
# See dialogGaugeStart
dialogGaugePrompt()
{
    echo "XXX"
    echo $1
    echo $2
    echo "XXX"
	if [[ $(echo $MM1 | grep -c "SlowExecute") == "1" ]]  ; then sleep 1 ; fi
}

# Start a progress gauge
# dialogGaugeStart title text height width percent
# See dialogGaugePrompt, dialogGaugeStop
dialogGaugeStart()
{
	mkfifo -m 0600 "$MY_TMP_DIR/gauge"
	whiptail --title "$1" --backtitle "$BACKTITLE" --gauge "$2" $3 $4 $5 < "$MY_TMP_DIR/gauge" &
	gauge_pid=$!
	if [[ $(echo $MM1 | grep -c "QuickExecute") == "0" ]]  ; then sleep 1 ; fi
}

# Stop a progress gauge
# See dialogGaugeStart
dialogGaugeStop()
{
	wait $gauge_pid
	rm -f "$MY_TMP_DIR/gauge"
}

# Display an input box
# dialogInput title text height width input-text
# 'input' contains text entry
# 'ret' contains exit code (0 on success, >0 if user cancels)
dialogInput()
{
	{ input=$(whiptail --title "$1" --backtitle "$BACKTITLE" --inputbox \
	    "$2" $3 $4 "$5" 3>&1 1>/dev/tty 2>&3); ret=$?; } || true
}

# Display a menu
# dialogMenu title text height width menu-height menu-item...
# 'input' contains menu selection
# 'ret' contains exit code (0 on success, >0 if user cancels)
dialogMenu()
{
	title=$1
	text=$2
	height=$3
	width=$4
	menu_height=$5
	shift 5
	{
		input=$(for item; do echo "\"$item\""; echo '""'; done \
		    | xargs whiptail --title "$title" --backtitle "$BACKTITLE" \
		    --menu "$text" $height $width $menu_height 3>&1 1>/dev/tty \
		    2>&3)
		ret=$?
	} || true
}

# Display a message
# dialogMsgBox title button-text text height width
dialogMsgBox()
{
	whiptail --title "$1" --backtitle "$BACKTITLE" --ok-button "$2" \
	    --msgbox "$3" $4 $5
}

# Display a password box
# dialogPassword title text height width
# 'input' contains text entry
# 'ret' contains exit code (0 on success, >0 if user cancels)
dialogPassword()
{
	{ input=$(whiptail --title "$1" --backtitle "$BACKTITLE" --passwordbox \
	    "$2" $3 $4 3>&1 1>/dev/tty 2>&3); ret=$?; } || true
}

# Display a yes/no choice
# dialogYesNo title yes-text no-text text height width
# exit 0 on yes, 1 on no
dialogYesNo()
{
	whiptail --title "$1" --backtitle "$BACKTITLE" --yes-button "$2" \
	    --no-button "$3" --yesno "$4" $5 $6
}

### END ### whiptail.inc.sh #############################################################################
