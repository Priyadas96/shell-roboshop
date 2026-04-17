#!/bin/bash
AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-024ade25ac3a5b0c3"
INSTANCES=("frontend" "user" "mongodb" "redis" "mysql" "rabbitmq" "catalogue" "cart" "shipping" "payment" "dispatch")
ZONE_ID="Z016724622CXQDS2CP51J"
DOMAIN_NAME="daws-sunny.site"

for instance in ${INSTANCES[@]}; do
	INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type t3.micro --security-group-ids sg-024ade25ac3a5b0c3 --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

	if [ $instance != "frontend" ]; then
		IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
		RECORD_NAME=$instance.$DOMAIN_NAME
	else
		IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
		RECORD_NAME=$DOMAIN_NAME
	fi

	echo "$instance IP address : $IP"

	aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$RECORD_NAME'","Type":"A","TTL":1,"ResourceRecords":[{"'$IP'"}]}}]}'
done
