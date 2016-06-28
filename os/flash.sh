#!/bin/bash

if [ $# -ne 1 ]; then
 echo "One parameter required: the device of the serial interface"
 echo "$0 <device>"
 echo "e.g.:"
 echo "$0 ttyUSB0"
 exit 1
fi

DEVICE=$1

# check the serial connection

if [ ! -c /dev/$DEVICE ]; then
 echo "/dev/$DEVICE does not exist"
 exit 1
fi

if [ ! -f esptool.py ]; then
 echo "Cannot found the required tool:"
 echo "esptool.py"
 exit 1
fi

sudo ./esptool.py --port /dev/$DEVICE read_mac

if [ $? -ne 0 ]; then
 echo "Error reading the MAC -> set the device into the bootloader!"
 exit 1
fi

sudo ./esptool.py --port /dev/$DEVICE write_flash 0x00000 nodemcu-master-12-modules-2016-06-28-18-25-46-integer.bin
