#!/bin/sh

apt-get -y install sudo

sed -ie 's/%sudo\tALL=(ALL:ALL) ALL/%sudo\tALL=(ALL:ALL) NOPASSWD:ALL/g' \
/etc/sudoers

