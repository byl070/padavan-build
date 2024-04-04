#!/bin/sh

start_wg() {
	localip="$(nvram get wireguard_localip)"
	listenport="$(nvram get wireguard_port)"
	privatekey="$(nvram get wireguard_localkey)"
	peerkey="$(nvram get wireguard_peerkey)"
	presharedkey="$(nvram get wireguard_prekey)"
	peerip="$(nvram get wireguard_peerip)"
	routeip="$(nvram get wireguard_routeip)"
	
	iptables -N wireguard 2>/dev/null
	iptables -F wireguard
	ip link set dev wg0 down 2>/dev/null
	ip link del dev wg0 2>/dev/null
	ip link add dev wg0 type wireguard || return 1
	ip link set dev wg0 mtu 1420
	if ip addr add $localip dev wg0; then
		localip="$(echo $localip | grep -E "/[1-9]+" || echo "${localip}/32")"
		echo $localip | grep -E -q "/32$" || iptables -A wireguard -s $localip -j ACCEPT
	else
		logger -t "WIREGUARD" "Set LocalIP Error"
		return 1
	fi
	if echo $privatekey > /tmp/privatekey && ! wg set wg0 private-key /tmp/privatekey; then
		logger -t "WIREGUARD" "Set PrivateKey Error"
		return 1
	fi
	if [ "$listenport" ] && ! wg set wg0 listen-port $listenport; then
		logger -t "WIREGUARD" "Set ListenPort Error"
		return 1
	fi
	if [ "$presharedkey" ] && echo $presharedkey > /tmp/presharedkey && ! wg set wg0 peer $peerkey preshared-key /tmp/presharedkey; then
		logger -t "WIREGUARD" "Set PresharedKey Error"
		return 1
	fi
	if wg set wg0 peer $peerkey allowed-ips 0.0.0.0/0; then
  if [ "$peerip" ]; then
		 for i in $(seq 1 5); do wg set wg0 peer $peerkey endpoint $peerip && unset peerip && break || sleep 3; done
	 	[ "$peerip" ] && logger -t "WIREGUARD" "Set PeerIP Error"
	 fi
	else
		return 1
	fi
	ip link set dev wg0 up
	for ip in ${routeip//,/ }; do
		if ip route add $ip dev wg0 2>/dev/null; then
			iptables -A wireguard -s $ip -j ACCEPT
		else
			logger -t "WIREGUARD" "AddRoute $ip Error" && echo "AddRoute $ip Error"
		fi
	done
	iptables -C INPUT -i wg0 -j wireguard 2>/dev/null || iptables -A INPUT -i wg0 -j wireguard
	iptables -C FORWARD -i wg0 -j wireguard 2>/dev/null || iptables -A FORWARD -i wg0 -j wireguard
	logger -t "WIREGUARD" "Wireguard is Start"
}


stop_wg() {
	if ip link set dev wg0 down 2>/dev/null && ip link del dev wg0; then
		while iptables -C INPUT -i wg0 -j wireguard 2>/dev/null; do iptables -D INPUT -i wg0 -j wireguard; done
		while iptables -C FORWARD -i wg0 -j wireguard 2>/dev/null; do iptables -D FORWARD -i wg0 -j wireguard; done
		iptables -F wireguard 2>/dev/null
		iptables -X wireguard 2>/dev/null
		logger -t "WIREGUARD" "Wireguard is Stop"
	fi
}



case $1 in
start)
	start_wg || stop_wg
	;;
stop)
	stop_wg
	;;
*)
	echo "check"
	#exit 0
	;;
esac
