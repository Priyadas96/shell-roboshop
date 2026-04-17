#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]; then
	echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
	exit 1 #give other than 0 upto 127
else
	echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE() {
	if [ $1 -eq 0 ]; then
		echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
	else
		echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
		exit 1
	fi
}

dnf module disable nginx -y &>>$LOGS_FILE
VALIDATE $? "disabling nginx"

dnf module enable nginx:1.24 -y &>>$LOGS_FILE
VALIDATE $? "enabling nginx"

dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "Installing nginx"

rm -rf /usr/share/nginx/html/* &>>$LOGS_FILE
VALIDATE $? "removing nginx default files"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOGS_FILE
VALIDATE $? "unzipping frontend"

rm -rf /etc/nginx/nginx.config &>>$LOGS_FILE
VALIDATE $? "Remove default nginx conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx
VALIDATE $? "Restarting nginx"
