#!/bin/bash

if [ $# -ne 1 ]; then
 echo "One parameter required: the device of the serial interface"
 echo "$0 <device>"
 echo "e.g.:"
 echo "$0 ttyUSB0"
 exit 1
fi

DEVICE=$1


echo "Read the MAC address from bootloader"
./esptool.py --port /dev/$DEVICE read_mac
