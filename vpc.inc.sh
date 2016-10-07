### vpc.inc.sh #############################################################################
function jsget {
	local _var1
	local _res
	local _req
	local _pyt
	_var1="$1"
	_req=$1
	_pyt=$2
	shift 2
	_res=$("$@" | python -c "import json,sys;obj=json.load(sys.stdin);print obj${_pyt}")
	eval $_req=$_res

	if [ $_var1 == "VpcId" ] ; then
		echo "VpcId=$_res" > $_res.cfg
	else
		echo "$_var1=$_res" >> $VpcId.cfg
	fi
}

function jschk {
	local _req
	#_req=$("$@" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["return"]')
echo $("$@")
return
	if [[ $_req != "true" ]] ; then
		echo "Error in this command: '$@'"
		pause
		##exit 1
	fi
}

function select_aws_cfg {
	AWSregion=$(whiptail --title "AWS regions" --separate-output --cancel-button "Exit" \
	--backtitle  "" \
	--menu "Select region to install VPC" 18 70 10 \
	"us-east-1" "US East (N. Virginia)" \
	"us-west-2" "US West (Oregon)" \
	"us-west-1" "US West (N. California)" \
	"eu-west-1" "EU (Ireland)" \
	"eu-central-1" "EU (Frankfurt)" \
	"ap-southeast-1" "Asia Pacific (Singapore)" \
	"ap-northeast-1" "Asia Pacific (Tokyo)" \
	"ap-southeast-2" "Asia Pacific (Sydney)" \
	"ap-northeast-2" "Asia Pacific (Seoul)" \
	"sa-east-1" "South America (Sao Paulo)" 3>&1 1>&2 2>&3 )
	if [ $? != 0 ]; then exit 0; fi
	#cn-north-1

	export AWS_DEFAULT_REGION=$AWSregion

	case $AWSregion in
		ap-northeast-1)
			AMIforDebian=ami-899091e7
		;;
		ap-southeast-1)
			AMIforDebian=ami-7bb47d18
		;;
		ap-southeast-2)
			AMIforDebian=ami-9a7056f9
		;;
		eu-central-1)
			AMIforDebian=ami-2638224a
		;;
		eu-west-1)
			AMIforDebian=ami-11c57862
		;;
		sa-east-1)
			AMIforDebian=ami-651f9c09
		;;
		us-east-1)
			AMIforDebian=ami-f0e7d19a
		;;
		us-west-1)
			AMIforDebian=ami-f28bfa92
		;;
		us-west-2)
			AMIforDebian=ami-837093e3
		;;
	esac
	AMIforDebianDescription="Debian 8.3, HVM x86_64, EBS, Marth 2016"

	Instance_type=$(whiptail --title "Select type of EC2-instance" --separate-output --cancel-button "Exit" \
	--backtitle  "" \
	--menu "Instance Type → CPU cores | Memory (GB) | Networking Performance" 18 70 10 \
	"t2.nano" "1 | 0.5 | Low" \
	"t2.micro" "1 | 1 | Low to Moderate (recommended for testing)" \
	"t2.small" "1 | 2 | Low to Moderate (recommended for testing)" \
	"t2.medium" "2 | 4 | Low to Moderate" \
	"t2.large" "2 | 8 | Low to Moderate" \
	"m4.large" "2 | 8 | Moderate (recommended for production)" \
	"m4.xlarge" "4 | 16 | High (recommended for production)" \
	"m4.2xlarge" "8 | 32 | High" \
	"m4.4xlarge" "16 | 64 | High" \
	"m4.10xlarge" "40 | 160 | 10 Gigabit" \
	"m3.medium" "1 | 3.75 | Moderate" \
	"m3.large" "2 | 7.5 | Moderate" \
	"m3.xlarge" "4 | 15 | High" \
	"m3.2xlarge" "8 | 30 | High" \
	"c4.large" "2 | 3.75 | Moderate" \
	"c4.xlarge" "4 | 7.5 | High" \
	"c4.2xlarge" "8 | 15 | High" \
	"c4.4xlarge" "16 | 30 | High" \
	"c4.8xlarge" "36 | 60 | 10 Gigabit" \
	"c3.large" "2 | 3.75 | Moderate" \
	"c3.xlarge" "4 | 7.5 | Moderate" \
	"c3.2xlarge" "8 | 15 | High" \
	"c3.4xlarge" "16 | 30 | High" \
	"c3.8xlarge" "32 | 60 | 10 Gigabit" \
	"g2.2xlarge" "8 | 15 | High" \
	"g2.8xlarge" "32 | 60 | 10 Gigabit" \
	"r3.large" "2 | 15.25 | Moderate" \
	"r3.xlarge" "4 | 30.5 | Moderate" \
	"r3.2xlarge" "8 | 61 | High" \
	"r3.4xlarge" "16 | 122 | High" \
	"r3.8xlarge" "32 | 244 | 10 Gigabit" \
	"i2.xlarge" "4 | 30.5 | Moderate" \
	"i2.2xlarge" "8 | 61 | High" \
	"i2.4xlarge" "16 | 122 | High" \
	"i2.8xlarge" "32 | 244 | 10 Gigabit" \
	"d2.xlarge" "4 | 30.5 | Moderate" \
	"d2.2xlarge" "8 | 61 | High" \
	"d2.4xlarge" "16 | 122 | High" \
	"d2.8xlarge" "36 | 244 | 10 Gigabit" 3>&1 1>&2 2>&3 )
	if [ $? != 0 ]; then exit 0; fi

	DbInstanceClass=$(whiptail --title "Select type of RDS-instance" --separate-output --cancel-button "Exit" \
	--backtitle  "" \
	--menu "Instance Type → Cores | ECU | Memory | Performance | Encryption" 30 80 20 \
	"db.t1.micro"		"1  | 1   | 0.6 | Very Low | - | " \
	"db.m1.small"		"1  | 1   | 1.7 | Very Low | - |" \
	"db.m4.large"		"2  | 6.5 | 8   | Moderate | + | for production" \
	"db.m4.xlarge"		"4  | 13  | 16  | High     | + | for production" \
	"db.m4.2xlarge"		"8  | 26  | 32  | High     | + |" \
	"db.m4.4xlarge"		"16 | 54  | 64  | High     | + |" \
	"db.m4.10xlarge"	"40 | 125 | 160 | 10 GBps  | + |" \
	"db.r3.large"		"2  | 6.5 | 15  | Moderate | + |" \
	"db.r3.xlarge"		"4  | 13  | 31  | Moderate | + |" \
	"db.r3.2xlarge"		"8  | 26  | 61  | High     | + |" \
	"db.r3.4xlarge"		"16 | 52  | 122 | High     | + |" \
	"db.r3.8xlarge"		"32 | 104 | 244 | 10 Gbps  | + |" \
	"db.t2.micro"		"1  | 1   | 1   | Low      | - | for testing" \
	"db.t2.small"		"1  | 1   | 2   | Low      | - | for testing" \
	"db.t2.medium"		"2  | 2   | 4   | Moderate | - |" \
	"db.t2.large"		"2  | 2   | 8   | Moderate | + |" \
	"db.m3.medium"		"1  | 3   | 3.8 | Moderate | + | for development" \
	"db.m3.large"		"2  | 6.5 | 7.5 | Moderate | + |" \
	"db.m3.xlarge"		"4  | 13  | 15  | High     | + |" \
	"db.m3.2xlarge"		"8  | 26  | 30  | High     | + |" \
	"db.m2.xlarge"		"2  | 6.5 | 17  | Moderate | - |" \
	"db.m2.2xlarge"		"4  | 13  | 34  | Moderate | - |" \
	"db.m2.4xlarge"		"8  | 26  | 68  | High     | - |" \
	"db.cr1.8xlarge"	"32 | 88  | 244 | 10 Gbps  | + |" 3>&1 1>&2 2>&3 )
	if [ $? != 0 ]; then exit 0; fi
	
	AmazonEncryption=$(whiptail --title "AWS Encryption for Volumes and RDS" --separate-output --cancel-button "Exit" \
--backtitle  "" \
--checklist "Choose encryption" 20 80 3 \
"FS-Volume" "Use separate Volume for FreeSwitch" ON \
"Encryption-Volumes" "Use encryption for Volume" OFF \
"Encryption-PostgreSQL" "Use encryption for PostgreSQL (only M3+ !)" OFF  3>&1 1>&2 2>&3 )
if [ $? != 0 ]; then exit 0; fi
}

function start_vpc {
	dialogGaugeStart "Start Instance" "Please wait" 8 70 0
	{
		jsget VpcId '["Vpc"]["VpcId"]' aws ec2 create-vpc --cidr-block 10.0.0.0/16
		jsget VPC_1 '["Tags"][-1]["Value"]' aws ec2 describe-tags --filters Name=resource-type,Values=vpc Name=key,Values=Name
		if [[ $VPC_1 == VPC_* ]] ; then
			_next=$(echo $VPC_1 | sed 's|VPC_\([0-9]*\).*|\1|1')
			((_next++))
		else
			_next=0
		fi
		echo "_next=$_next" >> $VpcId.cfg
		VPC_2="VPC_${_next}"
		echo "VPC_2=$VPC_2" >> $VpcId.cfg
		SEC_GROUP="FreeSwitch-sg"
		echo "SEC_GROUP=$SEC_GROUP" >> $VpcId.cfg
		SEC_GROUP_DESC="Security group ${_next} for FreeSwitch"
		echo "SEC_GROUP_DESC=$SEC_GROUP_DESC" >> $VpcId.cfg
		FS_HOSTNAME="test${_next}.secrom.com"
		echo "FS_HOSTNAME=$FS_HOSTNAME" >> $VpcId.cfg
		FS_DB="fsdb${_next}"
		echo "FS_DB=$FS_DB" >> $VpcId.cfg
		dialogGaugePrompt 2 "$VPC_2 is created, VpcId: $VpcId"

		jsget ZoneName1 '["AvailabilityZones"][0]["ZoneName"]' aws ec2 describe-availability-zones
		jsget SubnetId '["Subnet"]["SubnetId"]' aws ec2 create-subnet --vpc-id $VpcId --cidr-block 10.0.1.0/24 --availability-zone $ZoneName1
		dialogGaugePrompt 4 "Subnet $SubnetId is created"
		jsget ZoneName2 '["AvailabilityZones"][1]["ZoneName"]' aws ec2 describe-availability-zones
		jsget SubnetId2 '["Subnet"]["SubnetId"]' aws ec2 create-subnet --vpc-id $VpcId --cidr-block 10.0.2.0/24 --availability-zone $ZoneName2
		dialogGaugePrompt 5 "Subnet $SubnetId2 is created"
		
		jsget InternetGatewayId '["InternetGateway"]["InternetGatewayId"]' aws ec2 create-internet-gateway
		dialogGaugePrompt 6 "InternetGateway $InternetGatewayId is created"
		
		jsget RouteTableId '["RouteTables"][0]["Associations"][0]["RouteTableId"]' aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VpcId
		dialogGaugePrompt 8 "RouteTable $RouteTableId is created"
		
		jschk aws ec2 attach-internet-gateway --internet-gateway-id $InternetGatewayId --vpc-id $VpcId
		dialogGaugePrompt 10 "InternetGateway $InternetGatewayId is attached to $VpcId"
		
		jschk aws ec2 create-route --route-table-id $RouteTableId --destination-cidr-block 0.0.0.0/0 --gateway-id $InternetGatewayId
		dialogGaugePrompt 12 "InternetGateway $InternetGatewayId is added to RouteTable $RouteTableId"
		
		jschk aws ec2 modify-vpc-attribute --vpc-id $VpcId --enable-dns-hostnames
		dialogGaugePrompt 14 "DNS hostnames for $VpcId is enabled"

		KEY_PAIR="sec16all"
		echo "KEY_PAIR=$KEY_PAIR" >> $VpcId.cfg
		# aws ec2 create-key-pair --key-name $KEY_PAIR | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["KeyMaterial"]' > $KEY_PAIR.pem
		# dialogGaugePrompt 16 "Key pair $KEY_PAIR is created and saved to $KEY_PAIR.pem"
		aws ec2 import-key-pair --key-name $KEY_PAIR --public-key-material $(openssl rsa -in $KEY_PAIR.pem -pubout | sed '/-----BEGIN PUBLIC KEY-----/d' | sed '/-----END PUBLIC KEY-----/d' | sed -z 's|\n||g')

		jsget GroupId '["GroupId"]' aws ec2 create-security-group --group-name $SEC_GROUP --description "$SEC_GROUP_DESC" --vpc-id $VpcId
		dialogGaugePrompt 18 "Security group $SEC_GROUP ($SEC_GROUP_DESC) is created, GroupId: $GroupId"
		
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol tcp --port 21 --cidr 0.0.0.0/0
		dialogGaugePrompt 20 "Port 21 (TCP) is added"
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol tcp --port 22 --cidr 0.0.0.0/0
		dialogGaugePrompt 21 "Port 22 (TCP) is added"
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol tcp --port 80 --cidr 0.0.0.0/0
		dialogGaugePrompt 22 "Port 80 (TCP) is added"
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol tcp --port 443 --cidr 0.0.0.0/0
		dialogGaugePrompt 23 "Port 443 (TCP) is added"
		#jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol tcp --port 3306 --source-group $GroupId
		#dialogGaugePrompt 24 "Port 3306 (TCP) is added"
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol udp --port 4569 --cidr 0.0.0.0/0
		dialogGaugePrompt 25 "Port 4569 (UDP) is added"
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol tcp --port "5060-5090" --cidr 0.0.0.0/0
		dialogGaugePrompt 26 "Ports 5060-5090 (TCP) are added"
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol udp --port "5060-5090" --cidr 0.0.0.0/0
		dialogGaugePrompt 27 "Ports 5060-5090 (UDP) are added"
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol tcp --port 5432 --source-group $GroupId
		dialogGaugePrompt 28 "Port 5432 (TCP) is added for $GroupId"
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol tcp --port 8000 --cidr 0.0.0.0/0
		dialogGaugePrompt 29 "Port 8000 (TCP) is added"
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol udp --port 8000 --cidr 0.0.0.0/0
		dialogGaugePrompt 30 "Port 8000 (UDP) is added"
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol tcp --port "12345-16999" --cidr 0.0.0.0/0
		dialogGaugePrompt 31 "Ports 12345-16999 (TCP) are added"
		jschk aws ec2 authorize-security-group-ingress --group-id $GroupId --protocol udp --port "16384-32768" --cidr 0.0.0.0/0
		dialogGaugePrompt 32 "Ports 16384-32768 (UDP) are added"

		jschk aws ec2 create-tags --resources $VpcId $SubnetId $SubnetId2 $InternetGatewayId $RouteTableId $GroupId --tags Key=Name,Value=$VPC_2
		dialogGaugePrompt 40 "Tag $VPC_2 is added"
		
		AMI_name=$AMIforDebian
		echo "AMI_name=$AMI_name" >> $VpcId.cfg
		#KeyName=secrom15

		MyDomain=secrom.com
		SubDomain=test1
		SiteName="$SubDomain.$MyDomain"
		SiteTag="'Key=Name,Value=\"$SiteName\"'"

		#aws iam create-instance-profile --instance-profile-name FreeSwitchProfile
		#aws iam add-role-to-instance-profile --role-name FreeSwitchRole --instance-profile-name FreeSwitchProfile
		
		dialogGaugePrompt 42 "Start ${Instance_type}-instance from $AMI_name with KeyName=$KEY_PAIR"
		jsget InstanceId '["Instances"][0]["InstanceId"]' aws ec2 run-instances --image-id $AMI_name --count 1 --instance-type $Instance_type --key-name $KEY_PAIR --security-group-ids $GroupId --subnet-id $SubnetId --iam-instance-profile Name=FreeSwitchProfile
		if [ -z $InstanceId ] ; then echo "EC2/VPC Instance not started - exit." ; break ; fi
		
		dialogGaugePrompt 44 "New instance is started, InstanceId=$InstanceId"
		
		aws ec2 create-tags --resources $InstanceId --tags Key=Name,Value="$SiteName"
		dialogGaugePrompt 46 "Name $SiteName for $InstanceId is added"

		jsget AllocationId '["AllocationId"]' aws ec2 allocate-address --domain vpc
		dialogGaugePrompt 48 "New Elastic IP for VPC is created"

		local _i=50
		while [ $(aws ec2 describe-instances --instance-ids $InstanceId | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Reservations"][0]["Instances"][0]["State"]["Code"]') -ne "16" ] ; do
			dialogGaugePrompt $_i "Waiting for started instance $InstanceId, pause 15sec."
			if (( "$_i" > "55" )) ; then echo "Too long waiting for $InstanceId - exit." ; break ; fi
			sleep 15
			((_i++))
		done

		jsget AssociationId '["AssociationId"]' aws ec2 associate-address --instance-id $InstanceId --allocation-id $AllocationId
		dialogGaugePrompt 56 "External IP is added to $InstanceId"
		
		PublicIpAddress=$(aws ec2 describe-instances --instance-ids $InstanceId | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Reservations"][0]["Instances"][0]["PublicIpAddress"]')
		echo "PublicIpAddress=$PublicIpAddress" >> $VpcId.cfg
		dialogGaugePrompt 58 "External IP is $PublicIpAddress"
		
		jsget HostedZoneId '["HostedZones"][0]["Id"]' aws route53 list-hosted-zones
		SecromHostedZone=$(echo $HostedZoneId | sed 's|/hostedzone/||1')
		dialogGaugePrompt 60 "SecromHostedZone is $SecromHostedZone"

		ChangeCur=change-cur-record.js
		cp change-resource-record-sets.js $MY_TMP_DIR/$ChangeCur
		sed -i "s|_MyDomain_|$MyDomain|" $MY_TMP_DIR/$ChangeCur
		sed -i "s|_subdomain_here_|$SiteName|" $MY_TMP_DIR/$ChangeCur
		sed -i 's|"A_or_CNAME"|"A"|' $MY_TMP_DIR/$ChangeCur
		# sed -i 's|300|300|' $MY_TMP_DIR/$ChangeCur
		sed -i "s|_IP_or_CNAME_here|$PublicIpAddress|" $MY_TMP_DIR/$ChangeCur
		jsget ChangeInfoId '["ChangeInfo"]["Id"]' aws route53 change-resource-record-sets --hosted-zone-id $SecromHostedZone --change-batch file://$MY_TMP_DIR/$ChangeCur
		if [ -z $ChangeInfoId ] ; then
			sed -i 's|"CREATE"|"UPSERT"|' $MY_TMP_DIR/$ChangeCur
			jsget ChangeInfoId '["ChangeInfo"]["Id"]' aws route53 change-resource-record-sets --hosted-zone-id $SecromHostedZone --change-batch file://$MY_TMP_DIR//$ChangeCur
		fi
		dialogGaugePrompt 62 "DNS-record $SiteName is created"

		AvailabilityZone=$(aws ec2 describe-instances --instance-ids $InstanceId | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["Reservations"][0]["Instances"][0]["Placement"]["AvailabilityZone"]')
		echo "AvailabilityZone=$AvailabilityZone" >> $VpcId.cfg
		
		AllocatedStorage=5
		echo "AllocatedStorage=$AllocatedStorage" >> $VpcId.cfg
		DbEingine=postgres
		echo "DbEingine=$DbEingine" >> $VpcId.cfg
		DbAdmin="${FS_DB}admin"
		echo "DbAdmin=$DbAdmin" >> $VpcId.cfg
		DbAdminPas="fe41GHy9"
		echo "DbAdminPas=$DbAdminPas" >> $VpcId.cfg
		DbSubnetGroupName="DbSubnet${_next}"
		jsget DBSubnetGroupsVpcId '["DBSubnetGroups"][0]["VpcId"]' aws rds describe-db-subnet-groups --db-subnet-group-name $DbSubnetGroupName
		if [ -n DBSubnetGroupsVpcId ] ; then
			DbSubnetGroupName="dbsubnet_for_$VpcId"
		fi
		echo "DbSubnetGroupName=$DbSubnetGroupName" >> $VpcId.cfg
		aws rds create-db-subnet-group --db-subnet-group-name $DbSubnetGroupName --db-subnet-group-description "Db DbSubnet desc${_next}" --subnet-ids $SubnetId $SubnetId2
		
		if [[ $(echo $AmazonEncryption | grep -c "Encryption-PostgreSQL") == "1" ]]  ; then
			aws kms describe-key --key-id "alias/rdskey"
			if [[ $? != 0 ]]; then
				jsget KMSkeyID '["KeyMetadata"]["KeyId"]' aws kms create-key --description "for RDS encryption" --key-usage "ENCRYPT_DECRYPT"
				aws kms create-alias --alias-name "alias/rdskey" --target-key-id $KMSkeyID
			fi
			jsget DBInstanceStatus '["DBInstance"]["DBInstanceStatus"]' aws rds create-db-instance --db-instance-identifier $FS_DB --allocated-storage $AllocatedStorage --db-instance-class $DbInstanceClass --engine $DbEingine --master-username $DbAdmin --master-user-password $DbAdminPas --vpc-security-group-ids $GroupId --availability-zone $AvailabilityZone --db-subnet-group-name $DbSubnetGroupName --no-publicly-accessible --storage-encrypted --kms-key-id "alias/rdskey"
			#  --storage-type gp2
			echo "DBInstanceStatus=$DBInstanceStatus, Encryption enabled"
		else
			jsget DBInstanceStatus '["DBInstance"]["DBInstanceStatus"]' aws rds create-db-instance --db-instance-identifier $FS_DB --allocated-storage $AllocatedStorage --db-instance-class $DbInstanceClass --engine $DbEingine --master-username $DbAdmin --master-user-password $DbAdminPas --vpc-security-group-ids $GroupId --availability-zone $AvailabilityZone --db-subnet-group-name $DbSubnetGroupName
			echo "DBInstanceStatus=$DBInstanceStatus, without Encryption"
		fi
			
		dialogGaugePrompt 64 "DB $FS_DB is created"
		
		local _i=66
		local _left=15
		while [[ $DBInstanceStatus != "available" ]] ; do
			dialogGaugePrompt $_i "Waiting for started db instance, current status - $DBInstanceStatus, pause 1 min, left about $_left min."
			if (( "$_i" > "90" )) ; then echo "Too long waiting for $FS_DB - exit." ; break ; fi
			sleep 60
			((_i++))
			if (( "$_left" > "1" )) ; then ((_left--)) ; fi			
			DBInstanceStatus=$(aws rds describe-db-instances --db-instance-identifier $FS_DB | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["DBInstances"][0]["DBInstanceStatus"]')
		done
		jsget POSTGRE_SERVER '["DBInstances"][0]["Endpoint"]["Address"]' aws rds describe-db-instances --db-instance-identifier $FS_DB
		echo "FS_POSTGRE_NAME=$FS_DB" 			> odbc-postgre.cfg
		echo "POSTGRE_SERVER=$POSTGRE_SERVER" 	>> odbc-postgre.cfg
		echo "POSTGRE_USER=$DbAdmin" 			>> odbc-postgre.cfg
		echo "POSTGRE_PASSWORD=$DbAdminPas" 	>> odbc-postgre.cfg

		if [[ $(echo $AmazonEncryption | grep -c "FS-Volume") == "1" ]]  ; then
			dialogGaugePrompt 90 "Creating Volume for FS"
			if [[ $(echo $AmazonEncryption | grep -c "Encryption-Volumes") == "1" ]]  ; then
				jsget KMSkeyID '["KeyMetadata"]["KeyId"]' aws kms describe-key --key-id "alias/volumekey"
				if [ -z $KMSkeyID ]; then
					jsget KMSkeyID '["KeyMetadata"]["KeyId"]' aws kms create-key --description "for Volume encryption" --key-usage "ENCRYPT_DECRYPT"
					aws kms create-alias --alias-name "alias/volumekey" --target-key-id $KMSkeyID
				fi
				jsget VolumeId '["VolumeId"]' aws ec2 create-volume --size 1 --availability-zone $AvailabilityZone --volume-type gp2 --encrypted --kms-key-id $KMSkeyID
				FS_Volume_tag="${VPC_2}__FS_Encrypted"
			else
				jsget VolumeId '["VolumeId"]' aws ec2 create-volume --size 1 --availability-zone $AvailabilityZone --volume-type gp2
				FS_Volume_tag="${VPC_2}__FS"
			fi
			jschk aws ec2 create-tags --resources $VolumeId --tags Key=Name,Value=$FS_Volume_tag
			
			_i=90
			VolumeStatus="creating"
			while [[ $VolumeStatus != "ok" ]] ; do
				dialogGaugePrompt $_i "Waiting for Volume $VolumeId, current status - $VolumeStatus, pause 5 sec."
				if (( "$_i" > "98" )) ; then echo "Too long waiting for creating $VolumeId - exit." ; break ; fi
				sleep 5
				((_i++))
				VolumeStatus=$(aws ec2 describe-volume-status --volume-ids $VolumeId | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["VolumeStatuses"][0]["Status"]')
			done
			dialogGaugePrompt 92 "Attach Volume for FS"
			aws ec2 attach-volume --volume-id $VolumeId --instance-id $InstanceId --device /dev/sdf
		fi
		dialogGaugePrompt 100 "Installation complete"
#	} > "$MY_TMP_DIR/gauge"
	}
	#echo "gauge_pid=$gauge_pid"
	kill $gauge_pid
	dialogGaugeStop

}
### END ### vpc.inc.sh #############################################################################