#!/bin/bash

USER_ID=$(ID -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

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

cp mongo.repo /etc/yum.repos.d/mongodb.repo
Validate $? "copying mongo repo"

dnf install mongodb-org -y &>>$LOGS_FILE
Validate $? "Installing ..Mongodb Server"

systemctl enable mongod &>>$LOGS_FILE
Validate $? "enabling mongodb"

systemctl start mongod &>>$LOGS_FILE
Validate $? "starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
Validate $? "Editing MongoDB conf file for remote connections"

systemctl restart mongod &>>$LOGS_FILE
Validate $? "restarting mongodb"
