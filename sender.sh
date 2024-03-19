#!/bin/bash

# URL des Webservers
SERVER_URL="http://remstalmap.com:5005/logcat"

# Ger^dtename abrufen
DEVICE_NAME=$(sed -n 's/^.*<string name="origin">\(.*\)<\/string>.*$/\1/p' /data/data/de.vahrmap.vmapper/shared_prefs/config.xml)
if [ -z "$DEVICE_NAME" ]; then
    DEVICE_NAME=$(hostname)
fi
# logcat-Output filtern und an Server senden
while true; do
    logcat | grep VM | while read line; do
        curl -X POST \
            -d "device_name=$DEVICE_NAME" \
            -d "log_data=$line" \
            $SERVER_URL
    done
done
