#!/usr/bin/python

''' RANDOM MAC ID GENERATOR FOR KVM
''' KVM doesn't accept MAC IDs which don't start with 52:54

import random

mac_id='52:54'

for i in range(1,5):
	rand_num_str = hex(random.randint(0,255))[2:]
	if len(rand_num_str) < 2:
		rand_num_str = '0' + rand_num_str
	mac_id = mac_id + ':' + rand_num_str

print(mac_id)
