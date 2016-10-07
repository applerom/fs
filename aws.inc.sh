### aws.inc.sh #############################################################################
function aws_cli_install {
	wget -q "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -O $MY_TMP_DIR/awscli-bundle.zip
	unzip -q -o $MY_TMP_DIR/awscli-bundle.zip -d $MY_TMP_DIR
	$MY_TMP_DIR/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
}
function aws_credentials_install {
	mkdir -p /root/.aws > /dev/null 2>&1
	cp aws_credentials.cfg /root/.aws/credentials
}

function aws_logger_install {
	cp awslogs-agent.cfg $MY_TMP_DIR/awslogs-agent.cfg
	wget -q https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O $MY_TMP_DIR/awslogs-agent-setup.py
	python $MY_TMP_DIR/awslogs-agent-setup.py --non-interactive --region $AvailabilityZone --configfile $MY_TMP_DIR/awslogs-agent.cfg > /dev/null 2>&1
}

function amazon_inspector_install {
	if [[ $DIST_TYPE == "ubuntu" ]] && [[ $(echo $VERSION_ID | grep -c "14\..*") == "1" ]] ; then
		wget -q https://s3-us-west-2.amazonaws.com/inspector.agent.us-west-2/latest/install -O $MY_TMP_DIR/AmazonInspectorInstall
		bash $MY_TMP_DIR/AmazonInspectorInstall > /dev/null 2>&1
		if [[ $? != 0 ]]; then
			whiptail --infobox "Error — Amazon Inspector wasn't installed, exit!"
			exit 1
		fi
	fi
}

function aws_services_install {
	_inspector_1="Inspector"
	_inspector_2="(Amazon Inspector is not supported by this OS)"
	_inspector_3=OFF

	if [[ $DIST_TYPE == "ubuntu" ]] && [[ $(echo $VERSION_ID | grep -c "14\..*") == "1" ]] ; then
		dpkg -S inspector > /dev/null 2>&1
		if [[ $? != 0 ]]; then
			_inspector_2="Install Amazon Inspector"
			_inspector_3=ON
		else
			_inspector_2="Install Amazon Inspector (already installed)"
			_inspector_3=OFF
		fi
	fi

	
	aws1=$(whiptail --title "Install AWS services" --separate-output --cancel-button "Exit" \
--backtitle  "" \
--checklist "Choose configuration" 8 70 3 \
"CLI" "Install AWS client line interface" ON \
"Logger" "Install AWS Logger" ON \
"$_inspector_1" "$_inspector_2" $_inspector_3 3>&1 1>&2 2>&3 )
	if [ $? != 0 ]; then exit 0; fi

	
	dialogGaugeStart "Install AWS services" "Please wait" 8 70 0
	{
		dialogGaugePrompt 2 "Install AWS client line interface"
		if [[ $(echo $aws1 | grep -c "CLI") == "1" ]]  ; then
			aws_cli_install
		fi
		if [[ $(echo $aws1 | grep -c "Logger") == "1" ]]  ; then
##			dialogGaugePrompt 20 "Install AWS credentials for AWS Logger"
##			aws_credentials_install
			dialogGaugePrompt 30 "Install AWS Logger"
			aws_logger_install
		fi
		if [[ $(echo $aws1 | grep -c "Inspector") == "1" ]]  ; then
			dialogGaugePrompt 80 "Install Amazon Inspector"
			amazon_inspector_install
		fi
		dialogGaugePrompt 100 "Amazon services are successful installed"
	} > "$MY_TMP_DIR/gauge"
	dialogGaugeStop
	
}
### END ### aws.inc.sh #############################################################################