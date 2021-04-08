#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
myuser="edit your user"
mygroup="edit your group name"
wherepubkey="your pubkey url"
sudopasswd=1
sshdport="your ssh port"
iftrim=0
grubtimeout=0
mirror=ustc

# sudopasswd=1表示需输密码验证sudo,0或其他表示不需要密码.
# iftrim=1将激活每周的trim,需systemctl支持.
# grubtimeout=9将不设置grub引导超时时间,其他值则设置时间为该值,仅debian系有效.

# ttfzenhei用于解决中文乱码
# o表示不设置源
# ustc表示使用中科大源(自动选择),ustcv4和ustcv6分别只解析中科大ipv4和ipv6,
# ustccernet,ustcchinanet,ustcunicom,ustccmcc,ustcrsync,tsinghua
# 分别表示中科大的教育网,电信,联通,移动,rsync线路,tsinghua是清华源(自动选择),
# tsinghuav4和tsinghuav6分别只解析清华源的ipv4和ipv6.


if [ $EUID -ne 0 ]; then
echo "you are $(whoami), please use root to continue this script."
exit 1
fi

mv /etc/locale.gen /etc/locale.gen.bak.$(date +%y%m%d%s)
echo "zh_CN.UTF-8 UTF-8" > /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# 先设置账户信息
#create group if not exists
egrep "^$mygroup" /etc/group >& /dev/null
if [ $? -ne 0 ]
then
groupadd $mygroup
else
echo "group not add because group $mygroup already exists!!!!!!"
echo "group not add because group $mygroup already exists!" >> configerror.log
exit 1
fi

#create user if not exists
egrep "^$myuser" /etc/passwd >& /dev/null
if [ $? -ne 0 ]
then
useradd -m -g $mygroup $myuser
else
echo "group not add because user $myuser already exists!!!!!!"
echo "group not add because user $myuser already exists!" >> configerror.log
exit 1
fi

#设置密码:
echo "Now setting ROOT password:"
passwd root
echo "Now setting $myuser password:"
passwd $myuser

#改时区:
mv /etc/localtime /etc/localtime.bak.$(date +%y%m%d%s)
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

if [ $mirror != o ] ; then
#设置源

# 下载中科大源模板，并去掉其他源
wget -O /tmp/ustcsources.txt https://mirrors.ustc.edu.cn/repogen/conf/debian-https-4-buster
mv /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%y%m%d%s)
mv /tmp/ustcsources.txt /etc/apt/sources.list
mv /etc/apt/sources.list.d /etc/apt/sources.list.d.bak
mkdir -p /etc/apt/sources.list.d

case $mirror in
ustc)
apt update ;;
ustcv4)
sed -i 's/mirrors.ustc.edu.cn/ipv4.mirrors.ustc.edu.cn/g' /etc/apt/sources.list
apt update ;;
ustcv6)
sed -i 's/mirrors.ustc.edu.cn/ipv6.mirrors.ustc.edu.cn/g' /etc/apt/sources.list
apt update ;;
ustccernet)
sed -i 's/mirrors.ustc.edu.cn/cernet.mirrors.ustc.edu.cn/g' /etc/apt/sources.list
apt update ;;
ustcchinanet)
sed -i 's/mirrors.ustc.edu.cn/chinanet.mirrors.ustc.edu.cn/g' /etc/apt/sources.list
apt update ;;
ustcunicom)
sed -i 's/mirrors.ustc.edu.cn/unicom.mirrors.ustc.edu.cn/g' /etc/apt/sources.list
apt update ;;
ustccmcc)
sed -i 's/mirrors.ustc.edu.cn/cmcc.mirrors.ustc.edu.cn/g' /etc/apt/sources.list
apt update ;;
ustcrsync)
sed -i 's/mirrors.ustc.edu.cn/rsync.mirrors.ustc.edu.cn/g' /etc/apt/sources.list
apt update ;;
tsinghua)
sed -i 's/mirrors.ustc.edu.cn/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
apt update ;;
tsinghuav4)
sed -i 's/mirrors.ustc.edu.cn/mirrors4.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
apt update ;;
tsinghuav6)
sed -i 's/mirrors.ustc.edu.cn/mirrors6.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
apt update ;;
*)
echo "镜像源指定错误!" >> myerror.log ;;
esac
fi
# BBR:
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
sysctl net.ipv4.tcp_available_congestion_control
lsmod | grep bbr

#sshd方面
# 改端口
apt install -y openssh-server
oldportinfo=$(sed -n '/Port /p' /etc/ssh/sshd_config)
sed -i "s/$oldportinfo/Port $sshdport/g" /etc/ssh/sshd_config

#root用户免密登陆
mkdir -p /root/.ssh
wget -O /root/.ssh/authorized_keys $wherepubkey
chown root:root /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

#允许root免密登陆
if [ "$(sed -n '/PermitRootLogin no/p' /etc/ssh/sshd_config)" = "PermitRootLogin no" ] ; then
sed -i "s/PermitRootLogin no/PermitRootLogin yes/g" /etc/ssh/sshd_config
fi

#允许密码登陆
if [ "$(sed -n '/PasswordAuthentication no/p' /etc/ssh/sshd_config)" = "PasswordAuthentication no" ] ; then
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
fi

systemctl restart sshd

# sudo设置
if [ $sudopasswd -eq 1 ] ; then
    echo "$myuser ALL=(ALL) ALL" >> /etc/sudoers
else
    echo "$myuser ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

# 每周trim
if [ $iftrim -eq 1 ] ; then
    which systemctl > /dev/null
    if [ $? -eq 0 ] ; then
        cp /usr/share/doc/util-linux/examples/fstrim.service /etc/systemd/system
        cp /usr/share/doc/util-linux/examples/fstrim.timer /etc/systemd/system
        systemctl enable fstrim.timer
    else
        echo "trim设置失败" >> myerror.log
    fi
fi

#grub引导超时时间设置:
if [ $grubtimeout -ne 9 ] ; then
    oldgrubinfo=$(sed -n '/GRUB_TIMEOUT=/p' /etc/default/grub)
    sed -i "s/$oldgrubinfo/GRUB_TIMEOUT=$grubtimeout/g" /etc/default/grub
    /usr/sbin/update-grub
fi
# 心得:如果要在sed中使用变量,需将单引号改为双引号！



# 更新软件仓库
apt update
apt upgrade -y
apt clean
