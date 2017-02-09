#!/bin/bash

sudo usermod -a -G dialout `whoami`
sudo cp -f $(dirname "${BASH_SOURCE[0]}" )/20-usb-serial.rules /etc/udev/rules.d