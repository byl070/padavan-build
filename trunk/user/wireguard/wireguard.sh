#!/bin/sh

dir=/etc/storage/wireguard
if [ ! -d $dir ]; then mkdir $dir; fi
if [ ! -f $dir/wireguard.sh ]; then
	echo "not found $dir/wireguard.sh"
	logger -t "WireGuard" "not found $dir/wireguard.sh"
else
	chmod +x $dir/wireguard.sh
	$dir/wireguard.sh $1
fi