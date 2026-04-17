#!/bin/bash
USER_ID=$(ID -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER

if [ $USER_ID -ne 0 ]; then
	echo -e "$R ERROR:: please login with root access $N" | tee -a $LOGS_FILE
	exit 1
else
	echo "You have loggedIn as Root" | tee -a $LOGS_FILE
fi

Validate() {
	if [ $1 -eq 0 ]; then
		echo -e "$2 is... $G Success:$N" | tee -a $LOGS_FILE
	else
		echo -e "$2 is .. $R Failure $N" | tee -a $LOGS_FILE
	fi
}

dnf module disable nodejs -y &>>$LOGS_FILE
Validate $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
Validate $? "enabling nodejs:20"

dnf install nodejs -y &>>$LOGS_FILE
Validate $? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
	useradd roboshop --shell /sbin/nologin --home /app --system --comment "roboshop sytem user" &>>$LOGS_FILE
	Validate $? "creating roboshop user"
else
	echo -e "System user ROBOSHOP already created...$Y Skipping$N"
fi

mkdir -p /app
Validate $? "creating app directory"

curl -o /app/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
Validate $? "downloading catalogue file"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "unzipping catalogue"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
Validate $? "Copying catalogue service"

systemctl daemon-reload &>>$LOGS_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue
VALIDATE $? "Starting Catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOGS_FILE
Validate $? "Installing Mongodb client"

STATUS=$(mongosh --host mongodb.daws-sunny.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if ($STATUS -lt 0); then
	mongosh --host mongodb.daws-sunny.site </app/db/master-data.js &>>$LOGS_FILE
	Validate $? "loading data into mongoDB"
else
	echo -e "DATA is already loaded...$Y Skipping $N"
fi
