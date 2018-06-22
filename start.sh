apt-get install docker.io -y

docker build -t munin-server .
echo "Please input munin_users="
read  muninuser
echo "Please inpput munin_password="
read muninpw
echo Please input Alert_Recipient email address=
read recipaddr
echo Please input Alert_sender email address=
read sendaddr
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
munin-server

docker exec -it muninserver /bin/bash
service grafana-service start
exit