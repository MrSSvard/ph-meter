FROM debian:stretch

LABEL maintainer="stefan.nigma@gmail.com"
LABEL version="2018.10.12"


# Switch to root user in order to install things
USER root

# Set timezone in container
ENV TZ=Europe/Stockholm
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install applications
RUN apt-get update ; apt-get install --no-install-recommends -y apt-transport-https curl gnupg ; rm -rf /var/lib/apt/lists/*
RUN curl -sL http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key | apt-key add -
RUN echo "deb http://repo.mosquitto.org/debian stretch main" | tee /etc/apt/sources.list.d/mosquitto.list
RUN curl -sL https://repos.influxdata.com/influxdb.key | apt-key add - ; /bin/bash -c "source /etc/os-release"
RUN echo "deb https://repos.influxdata.com/debian stretch stable" | tee /etc/apt/sources.list.d/influxdb.list

# Install packages, uninstall unneeded packages and clean up in order to reduce size
RUN apt-get update ; apt-get install --no-install-recommends -y influxdb mosquitto python3 python3-pip python3-setuptools; pip3 install wheel ; pip3 install influxdb paho-mqtt ;  apt-get remove -y python3-pip apt-transport-https gnupg ; apt-get -y autoremove ; rm -rf /var/lib/apt/lists/*

# Copy required files into container
COPY setup.sh /dock/

RUN chmod +x /dock/setup.sh
COPY mosquitto/01-mosquitto-local.conf /etc/mosquitto/conf.d/
COPY mosquitto/mosquitto.acl /etc/mosquitto/
RUN chown -R grafana:grafana /etc/mosquitto /var/log/mosquitto  /var/lib/influxdb


COPY mqtt_to_influx.py /dock/
RUN chmod +x /dock/mqtt_to_influx.py

COPY grafana/PH-Meter.json /var/lib/grafana/dashboards/

EXPOSE 1883

VOLUME /var/lib/influxdb

# Switch back to grafana user
USER grafana

ENTRYPOINT [ "/dock/setup.sh" ]