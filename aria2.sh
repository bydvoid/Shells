#!/bin/bash

aria2user="www"
# aria2.service里也要设置一下
dhtfile="https://s.hapy.cc:444/repo/files/dht.dat"
aria2servicefile="https://s.hapy.cc:444/repo/files/aria2.service"
updatebtsh="https://s.hapy.cc:444/repo/sh/updatebt.sh"

# 判断架构
bit=`uname -m`
if [[ ${bit} == "x86_64" ]]; then
	bit="64bit"
	aria2file="https://s.hapy.cc:444/repo/files/aria2-1.34.0-linux-gnu-64bit-build1.tar.bz2"
	aria2dirname="aria2-1.34.0-linux-gnu-64bit-build1"
	aria2conf="https://s.hapy.cc:444/repo/files/config/aria2nas.conf"
elif [[ ${bit} == "i386" || ${bit} == "i686" ]]; then
	bit="32bit"
	aria2file="https://s.hapy.cc:444/repo/files/aria2-1.34.0-linux-gnu-32bit-build1.tar.bz2"
	aria2dirname="aria2-1.34.0-linux-gnu-32bit-build1"
	aria2conf="https://s.hapy.cc:444/repo/files/config/aria2nas.conf"
else
	bit="arm"
	aria2conf="https://s.hapy.cc:444/repo/files/config/aria2t1.conf"
fi


# 卸载已经有的
uninstall_aria2(){
    systemctl stop aria2
    systemctl disable aria2.service
    dpkg -l aria2 > /dev/null
if [ $? -eq 0 ] ; then
    apt-get remove aria2 -y
    apt autoremove -y
fi
disableupdatebt
#if aria2c exists then delete
if [ -e /usr/bin/aria2c ] ; then
   rm /usr/bin/aria2c
fi
which aria2c > /dev/null
if [ $? -eq 0 ] ; then
   rm $(which aria2c)
fi
if [ -d /etc/aria2 ] ; then
   rm /etc/aria2 -rf
fi
if [ -d /home/$aria2user/.cache/aria2 ] ; then
   rm /home/$aria2user/.cache/aria2 -rf
fi
echo "卸载aria2完成!"
}

# 安装aria2
install_aria2x86(){
wget --no-check-certificate -O /tmp/aria2.tar.bz2 $aria2file
cd /tmp
tar xjf aria2.tar.bz2
cd $aria2dirname
make install
cd ..
rm /tmp/$aria2dirname -rf
rm /tmp/aria2.tar.bz2
mkdir -p /etc/aria2
cd /etc/aria2
touch aria2.session

#conf文件和dht
wget --no-check-certificate -O /etc/aria2/aria2.conf $aria2conf
mkdir -p /home/$aria2user/.cache/aria2
wget --no-check-certificate -O /home/$aria2user/.cache/aria2/dht.dat $dhtfile

#设置权限
chown $aria2user:$aria2user -R /etc/aria2
chown $aria2user:$aria2user -R /home/$aria2user

#设置服务
wget --no-check-certificate -O /etc/systemd/system/aria2.service $aria2servicefile
systemctl enable aria2.service
systemctl start aria2.service
echo "aria2 $bit 版本安装完成！"
}

install_aria2arm(){
apt-get install aria2 -y
mkdir -p /etc/aria2
cd /etc/aria2
touch aria2.session

#conf文件和dht
wget --no-check-certificate -O /etc/aria2/aria2.conf $aria2conf
mkdir -p /home/$aria2user/.cache/aria2
wget --no-check-certificate -O /home/$aria2user/.cache/aria2/dht.dat $dhtfile

#设置权限
chown $aria2user:$aria2user -R /etc/aria2
chown $aria2user:$aria2user -R /home/$aria2user
chmod 600 /etc/aria2/aria2.conf

#设置服务
wget --no-check-certificate -O /etc/systemd/system/aria2.service $aria2servicefile
systemctl enable aria2.service
systemctl start aria2.service
echo "aria2 $bit 版本安装完成！"
}

#自动更新BT Trackers
updatebts(){
    mkdir -p /root/crontab/
    rm -rf /tmp/installaria2/
    mkdir -p /tmp/installaria2/
    wget --no-check-certificate -O /root/crontab/updatebt.sh $updatebtsh
    chmod +x /root/crontab/updatebt.sh
    crontab -l > "/tmp/installaria2/crontab.bak"
    sed -i "/updatebt.sh/d" "/tmp/installaria2/crontab.bak"
    echo -e "\n0 3 * * 1 /bin/bash /root/crontab/updatebt.sh" >> "/tmp/installaria2/crontab.bak"
    crontab "/tmp/installaria2/crontab.bak"
    rm -rf /tmp/installaria2/
    cron_config=$(crontab -l | grep "updatebt.sh")
    if [[ -z ${cron_config} ]]; then
        echo "设置 Aria2 自动更新 BT-Tracker服务器 失败 !"
    else
        echo -e "设置 Aria2 自动更新 BT-Tracker服务器 成功 !"
        bash /root/crontab/updatebt.sh
    fi
}

disableupdatebt(){
    rm -rf /tmp/installaria2/
    mkdir -p /tmp/installaria2/
    crontab -l > "/tmp/installaria2/crontab.bak"
    sed -i "/updatebt.sh/d" "/tmp/installaria2/crontab.bak"
    crontab "/tmp/installaria2/crontab.bak"
    rm -rf /tmp/installaria2/
    rm -f /root/crontab/updatebt.sh
    cron_config=$(crontab -l | grep "updatebt.sh")
    if [[ -z ${cron_config} ]]; then
        echo "设置 Aria2 停止自动更新 BT-Tracker服务器 成功 !"
    else
        echo "设置 Aria2 停止自动更新 BT-Tracker服务器 失败 !"
    fi
}


if [ -z $1 ]; then
   uninstall_aria2
   if [ ${bit} == "arm" ]; then
      install_aria2arm
      updatebts
   else
      install_aria2x86
      updatebts
   fi
   systemctl status aria2.service
else
if [ $1 = "u" ]; then
   uninstall_aria2
fi
fi









