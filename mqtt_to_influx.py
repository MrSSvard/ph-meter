#!/usr/bin/env python3
import paho.mqtt.client as mqtt
import datetime
import time
import os
from influxdb import InfluxDBClient

def on_connect(client, userdata, flags, rc):
    print("Connected with result code "+str(rc))
    client.subscribe("PH-Meter/#")

def on_message(client, userdata, msg):
    # Use utc as timestamp
    receiveTime=datetime.datetime.utcnow()
    message=msg.payload.decode("utf-8")
    isfloatValue=False
    try:
        # Convert the string to a float so that it is stored as a number and not a string in the database
        val = float(message)
        isfloatValue=True
    except:
        isfloatValue=False

    if isfloatValue:
        print(str(receiveTime) + ": " + msg.topic + " " + str(val))

        json_body = [
            {
                "measurement": msg.topic,
                "time": receiveTime,
                "fields": {
                    "value": val
                }
            }
        ]

        dbclient.write_points(json_body)

# Set up a client for InfluxDB
dbclient = InfluxDBClient('127.0.0.1', 8086, 'root', 'root', 'phmeter')

# Initialize the MQTT client that should connect to the Mosquitto broker
mosquittoPw=os.environ.get('MOSQ_PHMETER_PASS')
client = mqtt.Client()
client.username_pw_set('phmeter',mosquittoPw)
client.on_connect = on_connect
client.on_message = on_message
connOK=False
while(connOK == False):
    try:
        client.connect("127.0.0.1", 1883, 60)
        connOK = True
    except:
        connOK = False
    time.sleep(2)

# Blocking loop to the Mosquitto broker
client.loop_forever()