#!/bin/bash
syslog="/etc/log/log.txt"
aria2_conf=/usr/local/etc/aria2/aria2.conf

bt_tracker_list=$(wget -qO- https://cdn.jsdelivr.net/gh/ngosang/trackerslist@master/trackers_all.txt |awk NF|sed ":a;N;s/\n/,/g;ta")
	if [ -z "`grep "bt-tracker" ${aria2_conf}`" ]; then
		sed -i '$a bt-tracker='${bt_tracker_list} "${aria2_conf}"
	else
		sed -i "s@bt-tracker.*@bt-tracker=$bt_tracker_list@g" "${aria2_conf}"
		echo "$(date +%Y/%m/%d-%H:%M:%S)  【Aria2-BT更新服务】BT列表更新成功" >> $syslog
	fi
systemctl restart aria2
