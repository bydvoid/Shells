#!/bin/bash

aria2user="www"
autoupdatebt=1
# aria2.service里也要设置一下
dhtfile="https://cdn.jsdelivr.net/gh/bydvoid/Shells/repo/files/dht.dat"
aria2servicefile="https://cdn.jsdelivr.net/gh/bydvoid/Shells/repo/files/services/aria2.service"
updatebtsh="https://cdn.jsdelivr.net/gh/bydvoid/Shells/repo/sh/updatebt.sh"
aria2bin="https://cdn.jsdelivr.net/gh/bydvoid/Shells/repo/files/bin/aria2c"
aria2conf="https://cdn.jsdelivr.net/gh/bydvoid/Shells/repo/files/config/aria2.conf"



#自动更新BT Trackers
updatebts(){
    mkdir -p /root/crontab/
    mkdir -p /tmp/installaria2/
    wget -O /root/crontab/updateb/t.sh $updatebtsh
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
        echo "设置 Aria2 自动更新 BT-Tracker服务器 成功 !"
        bash /root/crontab/updatebt.sh
    fi
}


# 安装aria2
install_aria2(){
wget -O /usr/local/bin/aria2c $aria2bin
chmod +x /usr/local/bin/aria2c

mkdir -p /usr/local/etc/aria2
cd /usr/local/etc/aria2
touch aria2.session

#conf文件和dht
wget -O /usr/local/etc/aria2/aria2.conf $aria2conf
mkdir -p /home/$aria2user/.cache/aria2
wget -O /home/$aria2user/.cache/aria2/dht.dat $dhtfile

#设置权限
chown $aria2user:$aria2user -R /usr/local/etc/aria2

#设置服务
wget -O /etc/systemd/system/aria2.service $aria2servicefile
systemctl enable aria2.service
systemctl start aria2.service
systemctl status aria2.service > /dev/null
if [ $? -eq 0 ]; then
    echo "aria2安装完成！"
else
    echo "aria2安装失败！"
fi

}

if [ $autoupdatebt -eq 1]; then
    updatebts
fi

