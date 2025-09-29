r="\e[31m"
g="\e[32m"
y="\e[33m"
n="\e[0m"

log_folder="/var/log/shell-roboshop"
script_name=$(echo $0 | cut -d "." -f1)
script_dir=$pwd
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

dnf module disable nodejs -y &>>$log_file
VALIDATE $? "Disabling Nodejs"

dnf module enable nodejs:20 -y &>>$log_file
VALIDATE $? "enabling Nodejs"

dnf install nodejs -y &>>$log_file
VALIDATE $? "Installing Nodejs "

id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
VALIDATE $? "creating system user"
else
echo -e " user already exists.... $y skipping $n "
mkdir -p /app 
VALIDATE $? "Creating App directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$log_file
VALIDATE $? "downloading app code" 

cd /app 
VALIDATE $? "changing directory"

unzip /tmp/catalogue.zip &>>$log_file
VALIDATE $? "unzip catalogue"

npm install &>>$log_file
VALIDATE $? "Installing dependencess"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying systemctlservice"

systemctl daemon-reload

systemctl enable catalogue &>>$log_file
VALIDATE $? "enabling catalogue"

systemctl start catalogue  &>>$log_file
VALIDATE $? "Starting catalogue"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying to mongo repo"

dnf install mongodb-mongosh -y &>>$log_file
VALIDATE $? "installing mongoclient"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$log_file
VALIDATE $? "load catalogue products"

systemctl restart catalogue
VALIDATE $? "restarting catalogue"