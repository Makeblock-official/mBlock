#!/bin/bash

usermod -a -G plugdev `whoami`
cp -f $(dirname "${BASH_SOURCE[0]}" )/20-usb-serial.rules /etc/udev/rules.d
udevadm control --reload-rules