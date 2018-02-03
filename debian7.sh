#!/bin/bash

# go to root
cd

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# install wget and curl
apt-get update;apt-get -y install wget curl;

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# set repo
wget -O /etc/apt/sources.list "https://raw.github.com/ekanarita/esteh/master/conf/sources.list.debian7"
wget "http://www.dotdeb.org/dotdeb.gpg"
cat dotdeb.gpg | apt-key add -;rm dotdeb.gpg

# remove unused
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;

# update
apt-get update; apt-get -y upgrade;

# install webserver
apt-get -y install nginx php5-fpm php5-cli

# install essential package
apt-get -y install bmon iftop htop nmap axel nano iptables traceroute sysv-rc-conf dnsutils bc nethogs openvpn vnstat less screen psmisc apt-file whois ptunnel ngrep mtr git zsh mrtg snmp snmpd snmp-mibs-downloader unzip unrar rsyslog debsums rkhunter
apt-get -y install build-essential

# disable exim
service exim4 stop
sysv-rc-conf exim4 off

# update apt-file
apt-file update

# setting vnstat
vnstat -u -i venet0
service vnstat restart

# install webserver
cd
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/nauval2007/debian7os/master/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Modified by Shien Ikiru</pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/nauval2007/debian7os/master/vps.conf"
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf
service php5-fpm restart
service nginx restart


# install openvpn
wget -O /etc/openvpn/openvpn.tar "https://raw.github.com/ekanarita/esteh/master/conf/openvpn-debian.tar"
cd /etc/openvpn/
tar xf openvpn.tar
wget -O /etc/openvpn/1194.conf "https://raw.github.com/ekanarita/esteh/master/conf/1194.conf"
service openvpn restart
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
wget -O /etc/iptables.up.rules "https://raw.github.com/ekanarita/esteh/master/conf/iptables.up.rules"
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
MYIP=`curl -s ifconfig.me`;
MYIP2="s/xxxxxxxxx/$MYIP/g";
sed -i $MYIP2 /etc/iptables.up.rules;
iptables-restore < /etc/iptables.up.rules
service openvpn restart

# configure openvpn client config
cd /etc/openvpn/
wget -O /etc/openvpn/1194-client.ovpn "https://raw.github.com/ekanarita/esteh/master/conf/1194-client.conf"
sed -i $MYIP2 /etc/openvpn/1194-client.ovpn;
PASS=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1`;
useradd -M -s /bin/false ekanarita
echo "ekanarita:$PASS" | chpasswd
echo "ekanarita" > pass.txt
echo "$PASS" >> pass.txt
tar cf client.tar 1194-client.ovpn pass.txt
cp client.tar /home/vps/public_html/
cd


# install badvpn
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/nauval2007/debian7os/master/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/nauval2007/debian7os/master/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300


# install mrtg
wget -O /etc/snmp/snmpd.conf "https://raw.githubusercontent.com/nauval2007/debian7os/master/snmpd.conf"
wget -O /root/mrtg-mem.sh "https://raw.githubusercontent.com/nauval2007/debian7os/master/mrtg-mem.sh"
chmod +x /root/mrtg-mem.sh
cd /etc/snmp/
sed -i 's/TRAPDRUN=no/TRAPDRUN=yes/g' /etc/default/snmpd
service snmpd restart
snmpwalk -v 1 -c public localhost 1.3.6.1.4.1.2021.10.1.3.1
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg.cfg public@localhost
curl "https://raw.githubusercontent.com/nauval2007/debian7os/master/mrtg.conf" >> /etc/mrtg.cfg
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg.cfg
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
cd


# setting port ssh
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
#sed -i '/Port 22/a Port 80' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
sed -i 's/#Banner/Banner/g' /etc/ssh/sshd_config
service ssh restart

# install dropbear
#apt-get -y update
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=443/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 109 -p 110 -p 80"/g' /etc/default/dropbear
sed -i 's/DROPBEAR_BANNER=""/DROPBEAR_BANNER="\/etc\/issue.net"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
service ssh restart
service dropbear restart

# upgrade dropbear 2014
#apt-get install zlib1g-dev
#wget https://insomnet4u.me/aneka/dropbear-2014.63.tar.bz2
#bzip2 -cd dropbear-2014.63.tar.bz2  | tar xvf -
#cd dropbear-2014.63
#./configure
#make && make install
#mv /usr/sbin/dropbear /usr/sbin/dropbear1
#ln /usr/local/sbin/dropbear /usr/sbin/dropbear
#service dropbear restart

# upgrade dropbear 2017
apt-get install zlib1g-dev
wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2017.75.tar.bz2
bzip2 -cd dropbear-2017.75.tar.bz2  | tar xvf -
cd dropbear-2017.75
./configure
make && make install
mv /usr/sbin/dropbear /usr/sbin/dropbear1
ln /usr/local/sbin/dropbear /usr/sbin/dropbear
service dropbear restartgi

# install vnstat gui
cd /home/vps/public_html/
wget https://raw.githubusercontent.com/adammau2/auto-debian7/master/app/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
sed -i "s/\$iface_list = array('eth0', 'sixxs');/\$iface_list = array('eth0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
sed -i "s/\$locale = 'en_US.UTF-8';/\$locale = 'en_US.UTF+8';/g" config.php
cd


#if [[ $ether = "eth0" ]]; then
#	wget -O /etc/iptables.conf $source/Debian7/iptables.up.rules.eth0
#else
#	wget -O /etc/iptables.conf $source/Debian7/iptables.up.rules.venet0
#fi

#sed -i $MYIP2 /etc/iptables.conf;
#iptables-restore < /etc/iptables.conf;

# block all port except
#sed -i '$ i\iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -d 127.0.0.1 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 21 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 22 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 53 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 80 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 81 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 109 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 110 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 143 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 1194 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 3128 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 8000 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 8080 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp --dport 10000 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p udp -m udp --dport 2500 -j ACCEPT' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p udp -m udp -j DROP' /etc/rc.local
#sed -i '$ i\iptables -A OUTPUT -p tcp -m tcp -j DROP' /etc/rc.local

# install fail2ban
apt-get update;apt-get -y install fail2ban;service fail2ban restart;

# Instal (D)DoS Deflate
if [ -d '/usr/local/ddos' ]; then
	echo; echo; echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/ddos
fi
clear
echo; echo 'Installing DOS-Deflate 0.6'; echo
echo; echo -n 'Downloading source files...'
wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
echo -n '.'
wget -q -O /usr/local/ddos/LICENSE http://www.inetbase.com/scripts/ddos/LICENSE
echo -n '.'
wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
echo -n '.'
wget -q -O /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
cp -s /usr/local/ddos/ddos.sh /usr/local/sbin/ddos
echo '...done'
echo; echo -n 'Creating cron to run script every minute.....(Default setting)'
/usr/local/ddos/ddos.sh --cron > /dev/null 2>&1
echo '.....done'
echo; echo 'Installation has completed.'
echo 'Config file is at /usr/local/ddos/ddos.conf'
echo 'Please send in your comments and/or suggestions to zaf@vsnl.com'

# install squid3
apt-get -y install squid3
wget -O /etc/squid3/squid.conf "https://raw.githubusercontent.com/adammau2/auto-debian7/master/conf/squid.conf"
sed -i $MYIP2 /etc/squid3/squid.conf;
service squid3 restart


# install webmin
cd
wget "http://prdownloads.sourceforge.net/webadmin/webmin_1.670_all.deb"
dpkg --install webmin_1.670_all.deb;
apt-get -y -f install;
rm /root/webmin_1.670_all.deb
service webmin restart
service vnstat restart

# User Status
cd
wget https://raw.githubusercontent.com/adammau2/auto-debian7/master/user-list
mv ./user-list /usr/local/bin/user-list
chmod +x /usr/local/bin/user-list

# Install SSH autokick
cd
wget https://raw.githubusercontent.com/adammau2/auto-debian7/master/autokick.sh
bash autokick.sh


# Install Monitor
cd
wget https://raw.githubusercontent.com/adammau2/auto-debian7/master/app/monssh
mv monssh /usr/local/bin/
chmod +x /usr/local/bin/monssh


# Install Menu
cd
wget https://raw.githubusercontent.com/adammau2/auto-debian7/master/app/menu
mv ./menu /usr/local/bin/menu
chmod +x /usr/local/bin/menu

# moth
cd
wget https://raw.githubusercontent.com/adammau2/auto-debian7/master/app/motd
mv ./motd /etc/motd

# finishing
chown -R www-data:www-data /home/vps/public_html
service cron restart
service nginx start
service php-fpm start
service vnstat restart
service openvpn restart
service snmpd restart
service ssh restart
service dropbear restart
service fail2ban restart
# service squid3 restart
service webmin restart
rm -rf ~/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

# info
clear
echo "ShienVPS | server |"
echo ""  | tee -a log-install.txt
echo "AUTOSCRIPT INCLUDES" | tee log-install.txt
echo "===============================================" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Service"  | tee -a log-install.txt
echo "-------"  | tee -a log-install.txt
echo "■ OpenVPN  : TCP 1194 (client config : http://$MYIP:81/client.tar)"  | tee -a log-install.txt
echo "■ OpenSSH  : 22, 80, 143"  | tee -a log-install.txt
echo "■ Dropbear : 443, 110, 109"  | tee -a log-install.txt
echo "■ Squid3   : 8080 (limit to IP SSH)"  | tee -a log-install.txt
echo "■ badvpn   : badvpn-udpgw port 7300"  | tee -a log-install.txt
echo "■ nginx    : 81"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Tools"  | tee -a log-install.txt
echo "-----"  | tee -a log-install.txt
echo "■ axel"  | tee -a log-install.txt
echo "■ bmon"  | tee -a log-install.txt
echo "■ htop"  | tee -a log-install.txt
echo "■ iftop"  | tee -a log-install.txt
echo "■ mtr"  | tee -a log-install.txt
echo "■ rkhunter"  | tee -a log-install.txt
echo "■ nethogs: nethogs venet0"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Script"  | tee -a log-install.txt
echo "------"  | tee -a log-install.txt
echo "■ screenfetch"  | tee -a log-install.txt
echo "■ ./ps_mem.py"  | tee -a log-install.txt
echo "■ ./speedtest_cli.py --share"  | tee -a log-install.txt
echo "■ ./bench-network.sh"  | tee -a log-install.txt
echo "■ ./userlogin.sh" | tee -a log-install.txt
echo "■ ./userexpired.sh" | tee -a log-install.txt
echo "■ ./userlimit.sh 2 [ini utk melimit max 2 login]" | tee -a log-install.txt
echo "■ sh dropmon [port] contoh: sh dropmon 443" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Fitur lain"  | tee -a log-install.txt
echo "----------"  | tee -a log-install.txt
echo "■ Webmin   : https://$MYIP:10000/"  | tee -a log-install.txt
echo "■ vnstat   : http://$MYIP:81/vnstat/"  | tee -a log-install.txt
echo "■ MRTG     : http://$MYIP:81/mrtg/"  | tee -a log-install.txt
echo "■ Timezone : Asia/Jakarta"  | tee -a log-install.txt
echo "■ Fail2Ban : [on]"  | tee -a log-install.txt
echo "■ IPv6     : [off]"  | tee -a log-install.txt
echo "Account Default (utk SSH dan VPN)"
echo "---------------"
echo "User     : shien"
echo "Password : $PASS"
echo ""  | tee -a log-install.txt
echo "Script Modified by  Shien Ikiru"  | tee -a log-install.txt
echo "Thanks to Original Creator Yurissh Kang Arie & Mikodemos"
echo ""  | tee -a log-install.txt
echo "VPS AUTO REBOOT TIAP 6 JAM"  | tee -a log-install.txt
echo "SILAHKAN REBOOT VPS ANDA"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "==============================================="  | tee -a log-install.txt
cd
rm -f /root/debian7.sh
