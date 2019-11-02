#!/bin/bash

# Set Random passwords if not specifically set

if [[ ! -v MOSQ_PHMETER_PASS ]]; then
    export MOSQ_PHMETER_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c15)
fi

if [[ ! -v MOSQ_USER_PASS ]]; then
    export MOSQ_USER_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c15)
fi

if [[ ! -v GF_SECURITY_ADMIN_PASSWORD ]]; then
    export GF_SECURITY_ADMIN_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c15)
fi

# Set up Mosquitto

echo "phmeter:${MOSQ_PHMETER_PASS}" > /etc/mosquitto/pwfile
echo "user:${MOSQ_USER_PASS}" >> /etc/mosquitto/pwfile
mosquitto_passwd -U /etc/mosquitto/pwfile

/usr/sbin/mosquitto -c /etc/mosquitto/mosquitto.conf &

# Start influxd
influxd &

# Set up InfluxDB
until influx -execute 'show databases'; do sleep .5; done
influx -execute 'CREATE DATABASE phmeter'
influx -execute "CREATE RETENTION POLICY one_hour ON phmeter DURATION 1h REPLICATION 1 DEFAULT"
influx -execute "CREATE RETENTION POLICY two_year ON phmeter DURATION 104w REPLICATION 1"


## Create Average Data
influx -execute 'CREATE CONTINUOUS QUERY "cq_1_ph" ON "phmeter" BEGIN SELECT mean("value") AS "value" INTO "two_year"."ph" FROM "PH-Meter/status/ph" GROUP BY time(2m) END'

influx -execute 'CREATE CONTINUOUS QUERY "cq_1_temp" ON "phmeter" BEGIN SELECT mean("value") AS "value" INTO "two_year"."temp" FROM "PH-Meter/status/temp" GROUP BY time(2m) END'

# Subscribe InfluxDB to MQTT 
/dock/mqtt_to_influx.py &

# Create InfluxDB Datasource for Grafana
until $(curl --output /dev/null --silent --head --fail http://grafana:3000); do sleep 1; done
curl "http://admin:${GF_SECURITY_ADMIN_PASSWORD}@grafana:3000/api/datasources" \
    -X POST -H "Content-Type: application/json" \
    --data-binary \
      '{
        "name":"PH-Meter",
        "type":"influxdb",
        "url":"http://mosquitto:8086",
        "access":"proxy",
        "isDefault":true,
        "database":"phmeter",
        "user":"n/a","password":"n/a"
      }'

# Keep Docker Container running
tail -f /dev/null