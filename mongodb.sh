#!/bin/bash
r="\e[31m"
g="\e[32m"
y="\e[33m"
n="\e[0m"

log_folder="/var/log/robo_shop"
script_name=$(echo $0 | cut -d "." -f1)
log_file="$log_folder/$script_name.log"

mkdir -p $log_folder

echo "script started excuted at : $(date)" | tee -a $log_file



userid=$(id -u)

if [ $userid -ne 0 ]; then
    echo "Error:: Please run this script with root privelege"
    exit 1
fi


VALIDATE (){
    if [ $1 -ne 0 ]; then
        echo -e "Error:: $2 is $r failure $n" | tee -a $log_file
        exit 1
    else
        echo -e "$2 is $g success $n" | tee -a $log_file
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "adding Mongo Repo" 

dnf install mongodb-org -y  &>>$log_file
VALIDATE $? "Installing MongoDB" 

systemctl enable mongod &>>$log_file
VALIDATE $? "Enable MongoDB"  

systemctl start mongod &>>$log_file
VALIDATE $? "start MongoDB"