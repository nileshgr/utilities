#!/usr/bin/python3

'''
A script which pings network using fping and 
generates a hosts file for use with pdnsd/dnsmasq.

Use when you want to create hostnames based on mac addresses instead of
having fixed IP address

start_ip = starting ip address for fping
end_ip = ending ip address for fping
server_list = a file which contains data in following format:

    <mac address> <primary name> <alias 1> <alias 2> <alias 3>
    ...

generated_hosts_file = a file where ip to name mapping file must be written
domain = domain name to be stuck behind every alias (so alias1 becomes alias1.domain)
command_update = a list of command and it's arguments which will be executed when the file is updated
'''

### start configuration ###

start_ip = '192.168.0.1'
end_ip = '192.168.0.100'
domain = 'mydomain'
server_list = '/etc/servers'
generated_hosts_file = '/etc/servers_generated'
command_update = ['/usr/sbin/pdnsd-ctl', 'config']
daemon_interval = 60

### end configuration ###

import tempfile
import time
import subprocess
import shutil

while True:
	subprocess.call(['/usr/bin/fping', '-r', '1', '-i', '1', '-g', start_ip, end_ip], stdout=subprocess.DEVNULL)

	mac_to_names = dict()
	ip_to_names = dict()

	with open(server_list) as servers:
		for line in servers:
			data = line.strip().split(' ')
			mac_to_names[data[0]] = ["%s.%s" % (i, domain) for i in data[1:]]

	with open('/proc/net/arp') as arp:
		for line in arp:
			data = line.strip().split()

			try:
				names = mac_to_names[data[3]]
				names.reverse()
				ip_to_names[data[0]] = names
			except KeyError:
				pass

	with tempfile.NamedTemporaryFile(mode='w+t') as tmp:
		for k in sorted(ip_to_names):
			line = "%s %s" % (k, ' '.join(ip_to_names[k]))
			print(line, file=tmp)

		tmp.flush()
		tmp.seek(0)

		if subprocess.call(['diff', '-b', tmp.name, generated_hosts_file], stdout=subprocess.DEVNULL) != 0:
			shutil.copyfile(tmp.name, generated_hosts_file)
			if subprocess.call(command_update, stdout=subprocess.DEVNULL) != 0:
				print("update command failed")

	time.sleep(daemon_interval)

