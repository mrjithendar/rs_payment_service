#!bin/bash 

ORGANIZATION=DecodeDevOps
COMPONENT=payment
USERNAME=roboshop
APPDIRECTORY=/home/$USERNAME/$COMPONENT

PAYMENTINI=https://raw.githubusercontent.com/$ORGANIZATION/$COMPONENT/main/$COMPONENT.ini
PAYMENT=https://raw.githubusercontent.com/$ORGANIZATION/$COMPONENT/main/$COMPONENT.py
SERVICE=https://raw.githubusercontent.com/$ORGANIZATION/$COMPONENT/main/$COMPONENT.service
RABBITMQ=https://raw.githubusercontent.com/$ORGANIZATION/$COMPONENT/main/rabbitmq.py
REQUIREMENTS=https://raw.githubusercontent.com/$ORGANIZATION/$COMPONENT/main/requirements.txt

OS=$(hostnamectl | grep 'Operating System' | tr ':', ' ' | awk '{print $3$NF}')
selinux=$(sestatus | awk '{print $NF}')

if [ $(id -u) -ne 0 ]; then
  echo -e "\e[1;33mYou need to run this as root user\e[0m"
  exit 1
fi

if [ $OS == "CentOS8" ]; then
    echo -e "\e[1;33mRunning on CentOS 8\e[0m"
    else
        echo -e "\e[1;33mOS Check not satisfied, Please user CentOS 8\e[0m"
        exit 1
fi

if [ $selinux == "disabled" ]; then
    echo -e "\e[1;33mSE Linux Disabled\e[0m"
    else
        echo -e "\e[1;33mOS Check not satisfied, Please disable SE linux\e[0m"
        exit 1
fi

hostname $COMPONENT

cat /etc/passwd | grep $USERNAME
if [ $? -ne 0 ]; then
    useradd $USERNAME
    echo -e "\e[1;33m$USERNAME user added\e[0m"
    else
    echo -e "\e[1;32m$USERNAME user exists\e[0m"
fi 

echo -e "\e[1;33mDownloading Artifacts\e[0m"
if [ -d $APPDIRECTORY ]; then
    rm -rf $APPDIRECTORY
    mkdir -p $APPDIRECTORY
    else
        mkdir -p $APPDIRECTORY
fi
curl -L $PAYMENTINI -o $APPDIRECTORY/$COMPONENT.ini
curl -L $PAYMENT -o $APPDIRECTORY/$COMPONENT.py
curl -L $RABBITMQ -o $APPDIRECTORY/rabbitmq.py
curl -L $REQUIREMENTS -o $APPDIRECTORY/requirements.txt

echo -e "\e[1;33m\e[1;33mInstalling python36\e[0m"
rpm -qa gcc | grep gcc 
if [ $? -ne 0 ]; then
    yum install -y python36 python3-pip gcc python3-devel
    echo -e "\e[1;33m\e[1;33mBuild tools installed\e[0m"
    else
        echo -e "\e[1;31mExisting installations found\e[0m"
fi

echo -e "\e[1;33mIntsalling $COMPONENT python packages\e[0m"
pip3 install -r $APPDIRECTORY/requirements.txt

if [ $? -eq 0 ]; then
    echo -e "\e[1;33mApp dependencies installed successfully\e[0m"
    else
        echo -e "\e[1;31mFailed to install app dependences\e[0m"
        exit 1
fi

echo -e "\e[1;33mConfiguring and starting $COMPONENT\e[0m"
curl -L $SERVICE -o /etc/systemd/system/$COMPONENT.service
sed -i -e 's/{{DOMAIN}}/'$USERNAME'.com/g' /etc/systemd/system/$COMPONENT.service

systemctl daemon-reload
systemctl enable $COMPONENT && systemctl restart $COMPONENT

if [ $? -eq 0 ]; then
    echo -e "\e[1;33m$COMPONENT configured successfully\e[0m"
    else
        echo -e "\e[1;33mfailed to configure $COMPONENT\e[0m"
        exit 0
fi