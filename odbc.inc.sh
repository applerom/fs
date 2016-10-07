### odbc.inc.sh ### ODBC-driver ####################################################################

function odbc_debian {

odbc_debian1=$(whiptail --title "ODBC-driver for $PSEUDONAME" --separate-output --cancel-button "Exit" \
--backtitle  "" \
--checklist "Choose configuration" 20 80 3 \
"ODBC-MySQL" "Install ODBC-MySQL driver" OFF \
"ODBC-PostgreSQL" "Install ODBC-PostgreSQL driver" ON \
"Test" "Test ODBC-connction" OFF  3>&1 1>&2 2>&3 )
if [ $? != 0 ]; then exit 0; fi

dialogGaugeStart "Set up and configure ODBC-driver" "Please wait" 8 70 0
{
	dialogGaugePrompt 2 "Get ODBC-driver"
	dialogAptGet 2 18 install unixodbc-dev libmyodbc

	make_backup /etc/odbcinst.ini
	make_backup /etc/odbc.ini
	
	if [[ $(echo $odbc_debian1 | grep -c "ODBC-MySQL") == "1" ]]  ; then
		dialogGaugePrompt 20 "Install MySQL client"
		dialogAptGet 20 38 install mysql-client
		cat >> /etc/odbcinst.ini <<EOF
[MySQL]
Description     = MySQL driver
Driver          = libmyodbc.so
Setup           = libodbcmyS.so

EOF
	fi

	if [[ $(echo $odbc_debian1 | grep -c "ODBC-PostgreSQL") == "1" ]]  ; then
		dialogGaugePrompt 60 "Install PostgreSQL client"
		dialogAptGet 60 38 install postgresql-client odbc-postgresql
		source_my_inc_file odbc-postgre.cfg
		PGPASSWORD=$POSTGRE_PASSWORD createdb freeswitch --host $POSTGRE_SERVER --username=$POSTGRE_USER
		#PGPASSWORD=fe41GHy9 createdb freeswitch --host fsdb1.cfevji3xkn63.us-east-1.rds.amazonaws.com --username=fsdb1admin
	fi
	cat >> /etc/odbcinst.ini <<EOF
[PostgreSQL]
Description     = PostgreSQL ODBC driver
Driver          = psqlodbcw.so

EOF
	dialogGaugePrompt 100 "Installation complete"
} > "$MY_TMP_DIR/gauge"
dialogGaugeStop


if [[ $(echo $odbc_debian1 | grep -c "ODBC-MySQL") == "1" ]]  ; then
	get_var_txt_def FS_MYSQL_NAME "Enter FS_MYSQL_NAME" $FS_MYSQL_NAME
	get_var_txt_def MYSQL_SERVER "Enter MYSQL_SERVER (localhost or IP or DNS)" $MYSQL_SERVER
	get_var_txt_def MYSQL_USER "Enter MYSQL_USER" $MYSQL_USER
	get_var_txt_def MYSQL_PASSWORD "Enter MYSQL_PASSWORD" $MYSQL_PASSWORD
	cat >> /etc/odbc.ini <<EOF
[$FS_MYSQL_NAME]
Driver=MySQL
SERVER=$MYSQL_SERVER
PORT=3306
DATABASE=freeswitch
OPTION=67108864
USER=$MYSQL_USER
PASSWORD=$MYSQL_PASSWORD

EOF
fi
if [[ $(echo $odbc_debian1 | grep -c "ODBC-PostgreSQL") == "1" ]]  ; then
	if [ -n FS_MYSQL_NAME ]; then
		TEXT1="(not «$FS_MYSQL_NAME»)"
	fi
	get_var_txt_def FS_POSTGRE_NAME "Enter FS_POSTGRE_NAME $TEXT1 " $FS_POSTGRE_NAME
	get_var_txt_def POSTGRE_SERVER "Enter POSTGRE_SERVER (localhost or IP or DNS)" $POSTGRE_SERVER
	get_var_txt_def POSTGRE_USER "Enter POSTGRE_USER" $POSTGRE_USER
	get_var_txt_def POSTGRE_PASSWORD "Enter POSTGRE_PASSWORD" $POSTGRE_PASSWORD

	cat >> /etc/odbc.ini <<EOF
[$FS_POSTGRE_NAME]
Driver=PostgreSQL
Description=PostgreSQL ODBC driver
Servername = $POSTGRE_SERVER
Port=5432
Protocol=6.4
FetchBufferSize=99
UserName = $POSTGRE_USER
Password = $POSTGRE_PASSWORD
Database=freeswitch
ReadOnly=no
Debug=1
CommLog=1

EOF

fi

odbcinst -i -d -f /etc/odbcinst.ini > /dev/null 2>&1
odbcinst -i -s -l -f /etc/odbc.ini > /dev/null 2>&1

if [[ $(echo $odbc_debian1 | grep -c "Test") == "1" ]]  ; then
	clear
	echo -e "${WHITEBRIGHT}--------------------------------------------------------------------------------$NOCOLOUR"
	echo -e "$MyX Test DSN"
	echo -e "${WHITEBRIGHT}--------------------------------------------------------------------------------$NOCOLOUR"
	odbcinst -s -q
	echo -e "${WHITEBRIGHT}================================================================================$NOCOLOUR"

	if [[ $(echo $odbc_debian1 | grep -c "ODBC-MySQL") == "1" ]]  ; then
		echo ""
		echo -e "${WHITEBRIGHT}--------------------------------------------------------------------------------$NOCOLOUR"
		echo -e "${WHITEBRIGHT}Test ODBC-MySQL"
		echo -e "${NOCOLOUR}to example enter:"
		echo -e "${YELLOW}SELECT User, Host FROM mysql.user;"
		echo -e "${NOCOLOUR}or"
		echo -e "${YELLOW}show databases;"
		echo ""
		echo -e "${WHITEBRIGHT}Press ${RED}quit${WHITEBRIGHT} to exit from ODBC-SQL"
		echo -e "${WHITEBRIGHT}--------------------------------------------------------------------------------$NOCOLOUR"
		isql $FS_MYSQL_NAME
		echo -e "${WHITEBRIGHT}================================================================================$NOCOLOUR"
	fi
	if [[ $(echo $odbc_debian1 | grep -c "ODBC-PostgreSQL") == "1" ]]  ; then
		echo ""
		echo -e "${WHITEBRIGHT}--------------------------------------------------------------------------------$NOCOLOUR"
		echo -e "${WHITEBRIGHT}Test ODBC-PostgreSQL"
		echo -e "${NOCOLOUR}to example enter:"
		echo -e "${YELLOW}SELECT datname FROM pg_database WHERE datistemplate = false;"
		echo ""
		echo -e "${WHITEBRIGHT}Press ${RED}quit${WHITEBRIGHT} to exit from ODBC-SQL"
		echo -e "${WHITEBRIGHT}--------------------------------------------------------------------------------$NOCOLOUR"
		isql $FS_POSTGRE_NAME
		echo -e "${WHITEBRIGHT}================================================================================$NOCOLOUR"
	fi
fi

}

### END ### odbc.inc.sh #############################################################################
