#!/bin/bash
#适用于debian系统

myuser="edit here"
#用于授权该用户使用docker

#安装依赖:
sudo apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

apt update
apt install docker-ce docker-ce-cli containerd.io -y

usermod -aG docker $myuser
systemctl restart docker
