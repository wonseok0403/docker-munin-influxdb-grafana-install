FROM ubuntu:17

MAINTAINER Wonseok.J <wonseok786@khu.ac.kr>

RUN adduser --system --home /var/lib/munin --shell /bin/false --uid 1103 --group munin

RUN apt-get update -qq && RUNLEVEL=1 DEBIAN_FRONTEND=noninteractive \
    apt-get install -y -qq cron munin munin-node nginx wget heirloom-mailx patch spawn-fcgi libcgi-fast-perl
RUN rm /etc/nginx/sites-enabled/default && mkdir -p /var/cache/munin/www && chown munin:munin /var/cache/munin/www && mkdir -p /var/run/munin && chown -R munin:munin /var/run/munin

# InfluxDB Install
RUN /bin/bash -c "curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -"
RUN /bin/bash -c "source /etc/lsb-release"
RUN /bin/bash -c 'echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list'
RUN /bin/bash -c "sudo apt-get update && sudo apt-get install influxdb"
RUN /bin/bash -c "sudo service influxdb start"
#RUN /bin/bash -c "sudo printf "CREATE DATABASE munin_db\nCREATE USER admin WITH PASSWORD 'admin' WITH ALL PRIVILEGES\nCREATE USER grafana WITH PASSWORD 'grafana'\nGRANT ALL ON munin_db TO grafana\nexit>cartaro.sql'
RUN /bin/bash -c "influxdb -execute CREATE DATABASE munin_db"
RUN /bin/bash -c "influxdb -execute CREATE USER admin WITH PASSWORD 'admin' WITH ALL PRIVILEGES"
RUN /bin/bash -c "influxdb -execute CREATE USER grafana WITH PASSWORD 'grafana'"
RUN /bin/bash -c "influxdb -execute GRANT ALL ON munin_db TO grafana"
RUN /bin/bash -c '"sed 's#[http]#[http]\nenabled=true\nbind-address=":8086"#g'"'
RUN /bin/bash -c "systemctl restart influxdb.service"

# Grafana install
RUN wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_5.1.3_amd64.deb
RUN apt-get install -y adduser libfontconfig
RUN dpkg -i grafana_5.1.3_amd64.deb
RUN apt-get install -y apt-transport-https
RUN service grafana-server start
RUN update-rc.d grafana-server defaults
RUN systemctl daemon-reload
RUN systemctl start grafana-server
RUN systemctl status grafana-server
RUN systemctl enable grafana-server.service
RUN sed 's:[users]:[users]\nallow_sign_up=false:g'
RUN sed 's:[auth.anonymous]:[auth.anonymous]\nenabled=true'
RUN service grafana-server restart




VOLUME /var/lib/munin
VOLUME /var/log/munin

ADD ./munin.conf /etc/munin/munin.conf
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./nginx-munin /etc/nginx/sites-enabled/munin
ADD ./start-munin.sh /munin
ADD ./munin-graph-logging.patch /usr/share/munin
ADD ./munin-update-logging.patch /usr/share/munin

RUN cd /usr/share/munin && patch munin-graph < munin-graph-logging.patch && patch munin-update < munin-update-logging.patch

EXPOSE 8080
CMD ["bash", "/munin"]
