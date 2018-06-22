FROM ubuntu:14.04

MAINTAINER Wonseok.J <wonseok786@khu.ac.kr>

ENV GRAFANA_VERSION 5.1.4
ENV INFLUXDB_VERSION 1.5.3
RUN adduser --system --home /var/lib/munin --shell /bin/false --uid 1103 --group munin

RUN apt-get update -qq && RUNLEVEL=1 DEBIAN_FRONTEND=noninteractive \
    apt-get install -y -qq cron munin munin-node nginx wget heirloom-mailx patch spawn-fcgi libcgi-fast-perl curl
RUN rm /etc/nginx/sites-enabled/default && mkdir -p /var/cache/munin/www && chown munin:munin /var/cache/munin/www && mkdir -p /var/run/munin && chown -R munin:munin /var/run/munin

# InfluxDB Install
RUN             echo 'IT WILL TAKE A LONG TIME!'
RUN             wget -nv https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
                      dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && rm influxdb_${INFLUXDB_VERSION}_amd64.deb
RUN /bin/bash -c "service influxdb start"

#RUN update-rc.d influxdb start 
#RUN influx -host 127.0.0.1 -username admin -password admin
#RUN /bin/dash -c "influx -execute "CREATE DATABASE munin_db""
#RUN /bin/bash -c "influx -execute CREATE USER admin WITH PASSWOaRD 'admin' WITH ALL PRIVILEGES"
#RUN /bin/bash -c "influx -execute CREATE USER admin WITH PASSWOaRD 'admin' WITH ALL PRIVILEGES"
#RUN /bin/bash -c "influx -execute CREATE USER grafana WITH PASSWORD 'grafana'"
#RUN /bin/bash -c "influx -execute GRANT ALL ON munin_db TO grafana"
RUN /bin/bash -c 'cd /etc/influxdb'
RUN /bin/bash -c "sed 's/[http]/[http]\nenabled=true\nbind-address=":8086"/' /etc/influxdb/influxdb.conf "
RUN /bin/bash -c "service influxdb restart"

# Grafana install

RUN             mkdir -p src/grafana && cd src/grafana && \
                        wget -nv https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_5.1.4_amd64.deb
RUN apt-get -qq install -y adduser libfontconfig
RUN cd src/grafana && dpkg -i grafana_5.1.4_amd64.deb
RUN service grafana-server start
RUN update-rc.d grafana-server defaults
RUN sed 's:[users]:[users]\nallow_sign_up=false:g' /etc/grafana/grafana.ini
RUN sed 's:[auth.anonymous]:[auth.anonymous]\nenabled=true:g' /etc/grafana/grafana.ini
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
EXPOSE 3000
CMD ["bash", "/munin"]