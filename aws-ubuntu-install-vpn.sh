#!/bin/bash

# Automaticlly install pptpd on Amazon EC2 Amazon Linux (Ubuntu)
# 
#我用的是ubuntu的镜像，主要就是安装vpn需要的软件，设置iptables，配置ppp和vpn
#记得添加自定义规则：tcp端口1723,给vpn使用
#
#
# Authors: kime(cidy0106#gmail.com)
# Version: 0.0.1
#
#安装不要软件ppp和pptpd
apt-get install ppptd ppp

#下面是注释掉的，我也不清楚具体有啥子作用，保留
sed -i 's/^logwtmp/#logwtmp/g' /etc/pptpd.conf

#启用转发
sed -i 's/^net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sed -i 's/^net.ipv4.ip_forward=0/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p

#分配ip
echo "localip 192.168.222.1" >> /etc/pptpd.conf
echo "remoteip 192.168.222.2-100" >> /etc/pptpd.conf

#设置dns，跟我搭建vpn的服务器一样，记得修改成你自己的，不然很可能会上不到网
#原文是设置/etc/ppp/options.pptpd文件，但我不是/etc/ppp/pptpd-options，具体见/etc/pptpd.conf的说明

mydns=`cat /etc/resolv.conf |grep nameserver | awk '{print $2}'`
echo "ms-dns $mydns" >> /etc/ppp/pptpd-options
echo "ms-dns 8.8.8.8" >> /etc/ppp/pptpd-options

#iptables --flush POSTROUTING --table nat
#iptables --flush FORWARD

#下面会生成个默认的密码，自己改成容易记住的吧
#pass="kimeismyhero"

pass=`openssl rand 8 -base64`
if [ "$1" != "" ]
then pass=$1
fi

echo "vpn pptpd ${pass} *" >> /etc/ppp/chap-secrets

iptables -t nat -A POSTROUTING -s 192.168.222.0/24 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk 'NR==1 { print $1}'`
iptables -A FORWARD -p tcp --syn -s 192.168.222.0/24 -j TCPMSS --set-mss 1356

#service iptables save
#chkconfig iptables on
#chkconfig pptpd on
#service iptables start

service pptpd restart

echo -e "VPN service is installed, your VPN username is \033[1mvpn\033[0m, VPN password is \033[1m${pass}\033[1m"
