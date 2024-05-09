#!/bin/sh

dir=/etc/storage/wireguard
if [ ! -d $dir ]; then mkdir $dir; fi
if [ ! -f $dir/wireguard.sh ]; then
	echo "Unable to find $dir/wireguard.sh"
	logger -t "WireGuard" "Unable to find $dir/wireguard.sh"
else
	chmod +x $dir/wireguard.sh
	$dir/wireguard.sh $1
fi