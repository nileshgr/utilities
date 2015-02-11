#!/bin/sh

tcp_service_ports="22 80 443"
udp_service_ports=""

out_tcp_ports="22 25 53 80 443 465 587 993 9418"
out_udp_ports="53 123"

allow_ftp=false

# define nat IP address
nat_ip=

ipfw -f flush
ipfw -f table all flush

table=0
if [ -r /etc/ipfw.own_networks ]; then
	for ip in $(cat /etc/ipfw.own_networks); do
		ipfw table $table add $ip
	done
	ipfw add 200 allow all from "table($table)" to me in
	ipfw add 201 allow all from me to "table($table)" out
	table=$((table+1))
fi

ipfw nat 123 config ip $nat_ip same_ports unreg_only

index=1

ipfw add $index allow ip from 127.0.0.0/8 to 127.0.0.0/8 via lo0
ipfw add $index allow ip from ::1 to ::1 via lo0
ipfw add $index allow log ip from 10.0.0.0/8 to 127.0.0.1
ipfw add $index allow log ip from 127.0.0.1 to 10.0.0.0/8
ipfw add $index allow ip from fc00::/7 to ::1
ipfw add $index allow ip from ::1 to fc00::/7

index=$((index+1))

ipfw add $index allow ip from 10.0.0.0/24 to 10.0.0.0/24
ipfw add $index allow ip from fc00::1:0/112 to fc00::1:0/112 # 1:0 because 0:0 is in invalid ipv6 addr
ipfw add $((index+1)) allow ip from 10.0.1.0/24 to 10.0.1.0/24
ipfw add $((index+1)) allow ip from fc00::2:0/112 to fc00::2:0/112
ipfw add $((index+2)) allow ip from 10.0.2.0/24 to 10.0.2.0/24
ipfw add $((index+2)) allow ip from fc00::3:0/112 to fc00::3:0/112

index=$((index+5))

ipfw add $((index+1)) allow ipv6-icmp from :: to ff02::/16
ipfw add $index allow ipv6-icmp from fe80::/10 to fe80::/10
ipfw add $((index+1)) allow ipv6-icmp from fe80::/10 to ff02::/16
ipfw add $((index+1)) allow ipv6-icmp from any to any ip6 icmp6types 1
ipfw add $((index+1)) allow ipv6-icmp from any to any ip6 icmp6types 2,135,136

index=100

ipfw add $index nat 123 ip from any to $nat_ip in
ipfw add $((index+1)) check-state
ipfw add $((index+1)) allow icmp from me to any keep-state
ipfw add $index allow ipv6-icmp from me to any keep-state
ipfw add $((index+1)) allow icmp from any to any icmptypes 8
ipfw add $index allow ipv6-icmp from any to any ip6 icmp6types 128,129
ipfw add $((index+1)) allow icmp from any to any icmptypes 3,4,11
ipfw add $index allow ipv6-icmp from any to any ip6 icmp6types 3

index=199
# add port redirection (ipfw add $index fwd) between the last rule above and before rule 200

index=200
for port in $tcp_service_ports; do
	ipfw add $index allow tcp from any to me $port in
	ipfw add $index allow tcp from me $port to any out
	index=$((index+1))
done

index=300
for port in $udp_service_ports; do
	ipfw add $index allow udp from any to me $port in
	ipfw add $index allow udp from me $port to any out
	index=$((index+1))
done

index=400
for port in $out_tcp_ports; do
	ipfw add $index skipto 700 tcp from 10.0.0.0/8 to any $port out setup keep-state
	ipfw add $index allow tcp from me to any $port out setup keep-state
	index=$((index+1))
done

index=500
for port in $out_udp_ports; do
	ipfw add $index skipto 700 udp from 10.0.0.0/8 to any $port out keep-state
	ipfw add $index allow udp from me to any $port out keep-state
	index=$((index+1))
done

index=600

# add some other stuff here, like permitting special outgoing ports from specific IPs
# if you have multiple IPs

index=700
ipfw add $index nat 123 ip4 from 10.0.0.0/8 to not 10.0.0.0/8 out

if $allow_ftp; then 
	index=65000
	# FTP control port
	ipfw add $index allow tcp from me to any 21 out setup keep-state

	# Active FTP
	ipfw add $((index+1)) allow tcp from any 20 to me 1024-65535 in setup keep-state

	# Passive FTP
	ipfw add $((index+2)) allow tcp from me 1024-65535 to any 1024-65535 out setup keep-state
fi

ipfw add 65534 deny all from any to any
