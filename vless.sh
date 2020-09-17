#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

apt -y install jq curl lsof
clear && echo
kernel_version=`uname -r|awk -F "-" '{print $1}'`
if [[ `echo ${kernel_version}|awk -F '.' '{print $1}'` == '4' ]] && [[ `echo ${kernel_version}|awk -F '.' '{print $2}'` -ge 9 ]] || [[ `echo ${kernel_version}|awk -F '.' '{print $1}'` == '5' ]]; then
		sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
		sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
		echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
		echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
		sysctl -p
		sleep 1s
fi

#禁用SELinux
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi

pid_array=($(lsof -i:22|grep LISTEN|awk '{print$2}'|uniq))
for node in ${pid_array[@]};
do
	kill $node
done

bash <(curl -sL https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

cat > /usr/local/etc/v2ray/config.json <<EOF
{
  "inbounds": [
    {
      "port": 22,
      "listen":"127.0.0.1",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "1bb83c10-911e-4767-81d2-adb5177c0718",
            "level": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
	"security": "tls",
        "wsSettings": {
        "path": "/5e60be4f39c63c/"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
	
cat > ./sps.py <<EOF
import subprocess

subprocess.run("/usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json > /.run.log &", shell=True)
EOF

python3 sps.py

IP=$(curl -s ipinfo.io/ip)
echo IP
