#!/bin/bash
function getHostAddr() {
    local IPAddr=ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
    echo "$IPAddr"
}
apt-get install docker.io -y

docker build -t munin-server .
echo "Please input munin_users="
#read  muninuser
muninuser:="admin"
echo "Please inpput munin_password="
muninpw:="admin"
echo Please input Alert_Recipient email address=
recipaddr:="wonseok786@khu.ac.kr"
echo Please input Alert_sender email address=
sendaddr := "Alert@gmail.com"
echo "Input nodes, (format is servername:x.x.x.x servername2:y.y.y.y)"
read nodes
set muninuser:="'$muninuser'"
set muninpw:="'$muninpw'"
set nodes:="'$nodes'"

echo $muninuser
echo $muninpw
echo $nodes
docker run -d --name muninserver \
-p 8080:8080 \
-p 3000:3000 \
-p 8086:8086 \
-p 8088:8088 \
-p 2003:2003 \
-p 4242:4242 \
-p 8089:8089 \
-p 25826:25826 \
-v /var/log/munin:/var/log/munin \
-v /var/lib/munin:/var/lib/munin \
-v /var/run/munin:/var/run/munin \
-v /var/cache/munin:/var/cache/munin \
-e MUNIN_USERS=$muninuser \
-e MUNIN_PASSWORDS=$muninpw \
-e ALERT_RECIPIENT=$recipaddr \
-e ALERT_SENDER=$sendaddr \
-e NODES=$nodes \
-e MASTER_SERVER=$(getHostAddr) \
munin-server

docker exec -it muninserver /bin/bash
exit