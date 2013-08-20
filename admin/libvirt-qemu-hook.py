#!/usr/bin/python

import sys
import os

domain=sys.argv[1]
action=sys.argv[2]

iptables='/sbin/iptables'

mapping = {
			'<guest name (as defined in xml)>': { 'ip': '<private ip>', 'publicip': '<public ip>', 'portmap': 'all' | {'<proto>': [(<host port>, <guest port>)], ...}}, 
			...
		}


def rules(act, map_dict):
        if map_dict['portmap'] == 'all':
                cmd = '{} -t nat {} PREROUTING -d {} -j DNAT --to {}'.format(iptables, act, map_dict['publicip'], map_dict['ip'])
                os.system(cmd)
                cmd = '{} -t nat {} POSTROUTING -s {} -j SNAT --to {}'.format(iptables, act, map_dict['ip'], map_dict['publicip'])
                os.system(cmd)
                cmd = '{} -t filter {} FORWARD -d {} -j ACCEPT'.format(iptables, act, map_dict['ip'])
                os.system(cmd)
                cmd = '{} -t filter {} FORWARD -s {} -j ACCEPT'.format(iptables, act, map_dict['ip'])
                os.system(cmd)
        else:
                for proto in map_dict['portmap']:
                        for portmap in map_dict['portmap'].get(proto):
                                cmd = '{} -t nat {} PREROUTING -d {} -p {} --dport {} -j DNAT --to {}:{}'.format(iptables, act, map_dict['publicip'], proto, str(portmap[0]), map_dict['ip'], str(portmap[1]))
                                os.system(cmd)
                                cmd = '{} -t filter {} FORWARD -d {} -p {} --dport {} -j ACCEPT'.format(iptables, act, map_dict['ip'], proto, str(portmap[1]))
                                os.system(cmd)
                                cmd = '{} -t filter {} FORWARD -s {} -p {} --sport {} -j ACCEPT'.format(iptables, act, map_dict['ip'], proto, str(portmap[1]))
                                os.system(cmd)

host=mapping.get(domain)

if host is None:
        sys.exit(0)

if action == 'stopped' or action == 'reconnect':
        rules('-D', host)

if action == 'start' or action == 'reconnect':
        rules('-I', host)
