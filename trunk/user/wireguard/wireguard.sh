#!/bin/sh

start_wg() {
	localip="$(nvram get wireguard_localip)"
	listenport="$(nvram get wireguard_port)"
	privatekey="$(nvram get wireguard_localkey)"
	peerkey="$(nvram get wireguard_peerkey)"
	presharedkey="$(nvram get wireguard_prekey)"
	peerip="$(nvram get wireguard_peerip)"
	routeip="$(nvram get wireguard_routeip)"
	if [ -z $localip ] || [ -z $privatekey ] || [ -z $peerkey ]; then
		logger -t "WIREGUARD" "Config Error" && exit 0
	fi
	logger -t "WIREGUARD" "Wireguard is Start"
	ip link show wg0 >/dev/null 2>&1 && ip link set dev wg0 down && ip link del dev wg0
	ip link add dev wg0 type wireguard
	ip link set dev wg0 mtu 1420
	ip addr add $localip dev wg0
	if [ "$listenport" ]; then
		wg set wg0 listen-port $listenport
	fi
	echo "$privatekey" > /tmp/privatekey
	wg set wg0 private-key /tmp/privatekey
	if [ "$presharedkey" ]; then
	 echo "$presharedkey" > /tmp/presharedkey
		wg set wg0 peer $peerkey preshared-key /tmp/presharedkey
	fi
	wg set wg0 peer $peerkey persistent-keepalive 30 allowed-ips 0.0.0.0/0 endpoint $peerip
	ip link set dev wg0 up
	if [ "$routeip" ]; then 
		for ip in ${routeip//,/ }; do
			ip route add $ip dev wg0 || logger -t "WIREGUARD" "Route $ip Error"
		done
	fi
	iptables -A INPUT -i wg0 -j ACCEPT
	iptables -A FORWARD -i wg0 -j ACCEPT
}


stop_wg() {
	if ip link show wg0 >/dev/null 2>&1; then
		iptables -D INPUT -i wg0 -j ACCEPT
		iptables -D FORWARD -i wg0 -j ACCEPT
		ip link set dev wg0 down && ip link del dev wg0
		logger -t "WIREGUARD" "Wireguard is Stop"
	fi
	}



case $1 in
start)
	start_wg
	;;
stop)
	stop_wg
	;;
*)
	echo "check"
	#exit 0
	;;
esac
