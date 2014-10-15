#!/bin/sh

tcp_service_ports="22 80"
udp_service_ports=""

out_tcp_ports="22 25 53 80 443 465 587"
out_udp_ports="53 123"

allow_ftp=true

interface="re0"

ipfw -f flush
ipfw -f table all flush

table=0
if [ -r /etc/ipfw.own_networks ]; then
	for ip in $(cat /etc/ipfw.own_networks); do
		ipfw table $table add $ip
	done
	ipfw add 200 allow all from "table($table)" to me in via $interface
	ipfw add 201 allow all from me to "table($table)" out via $interface
	table=$((table+1))
fi

if [ -r /etc/ipfw.allow_pings_from ]; then
	for ip in $(cat /etc/ipfw.allow_pings_from); do
		ipfw table $table add $ip
	done
	ipfw add 202 allow icmp from "table($table)" to me in via $interface icmptypes 8
	ipfw add 203 allow icmp from me to "table($table)" out via $interface icmptypes 0
	table=$((table+1))
fi

ipfw add 1 check-state
ipfw add 100 allow all from any to any via lo0
ipfw add 101 allow icmp6 from any to any

# allow icmp - destination not reachable (3) and TTL exceeded (11)
ipfw add 300 allow icmp from any to me in icmptypes 3,11 via $interface
ipfw add 301 allow icmp from me to any out icmptypes 3,11 via $interface

index=400
for port in $tcp_service_ports; do
	ipfw add $index allow tcp from any to me $port in via $interface
	ipfw add $index allow tcp from me $port to any out via $interface
	index=$((index+1))
done

index=500
for port in $udp_service_ports; do
	ipfw add $index allow udp from any to me $port in via $interface
	ipfw add $index allow udp from me $port to any out via $interface
	index=$((index+1))
done

index=600
for port in $out_tcp_ports; do
	ipfw add $index allow tcp from me to any $port out via $interface setup keep-state
	index=$((index+1))
done

index=700
for port in $out_udp_ports; do
	ipfw add $index allow udp from me to any $port out via $interface keep-state
	index=$((index+1))
done

if $allow_ftp; then 
	index=65531
	# FTP control port
	ipfw add $index allow tcp from me to any 21 out via $interface setup keep-state

	# Active FTP
	ipfw add $((index+1)) allow tcp from any 20 to me 49152-65535 in via $interface setup keep-state

	# Passive FTP
	ipfw add $((index+2)) allow tcp from me 49152-65535 to any 49152-65535 out via $interface setup keep-state
fi
