#!/bin/bash

# URL des Webservers
SERVER_URL="http://remstalmap.com:5005/logcat"

# Ger^dtename abrufen
DEVICE_NAME=$(sed -n 's/^.*<string name="origin">\(.*\)<\/string>.*$/\1/p' /data/data/de.vahrmap.vmapper/shared_prefs/config.xml)
if [ -z "$DEVICE_NAME" ]; then
    DEVICE_NAME=$(hostname)
fi

# Tempor^dre Datei f^ar logcat-Output
LOGCAT_FILE="/sdcard/logcat_$DEVICE_NAME.log"

# Maximale Dateigr^t�e in Bytes (z.B. 1 MB)
MAX_FILE_SIZE=$((1 * 1024 * 1024))

# Log-Datei erstellen, falls sie nicht existiert
touch $LOGCAT_FILE

# Logcat in einer separaten Schleife in eine Datei schreiben
(logcat | grep VM > $LOGCAT_FILE) &

# Periodisch die letzten Zeilen der Logcat-Datei lesen und an den Server senden
while true; do
    tail -n 300 $LOGCAT_FILE | while read line; do
        curl -X POST \
            -d "device_name=$DEVICE_NAME" \
            -d "log_data=$line" \
            $SERVER_URL
    done
    sleep 5  # Pausieren zwischen den Sendungen, um die Serverlast zu reduzieren

    # Dateigr^t�e ^aberpr^afen und Log-Datei zur^acksetzen, falls sie zu gro� wird
    if [ $(stat -c%s "$LOGCAT_FILE") -gt $MAX_FILE_SIZE ]; then
        > $LOGCAT_FILE
    fi
