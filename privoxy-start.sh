#!/bin/sh

echo $PASS >/1.txt
openconnect $VPN -u $USER -b</1.txt

sleep 10

danted -f /etc/danted.conf 
