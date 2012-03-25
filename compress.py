#!/usr/bin/env python3

'''
Script written by Nilesh Govindarajan: http://nileshgr.com

Check timestamp and gzip-compress all files in directories specified at command line and their subdirectories

'''

# List of file extensions that should not be compressed

do_not_compress = ['gz', 'php', 'inc', 'bz2', 'tar']

def usage(cmdname):
	print('''Usage: {0} [options, ...] [directories, ...]
-h or --help                             Show This Help Text
-u <user> or --user=<user>               Set the user to chown to
-g <group> or --group=<group>            Set the group to chown to'''.format(cmdname))

def check_and_compress(path, chown_user, chown_group):
	for root, dirs, files in os.walk(path):
		for name in files:
			if name[0] != '.' and name[name.rfind('.')+1:] not in do_not_compress:
				filepath = os.path.join(root, name)
				if not os.path.exists(filepath): continue # Skip if path does not exist. Broken symlinks for example.
				
				gzfilepath = filepath + '.gz'
				file_created_time = os.path.getmtime(filepath)
				gzip_file_created_time = 0 if not os.path.exists(gzfilepath) else os.path.getmtime(gzfilepath)

				if gzip_file_created_time < file_created_time:
					with open(filepath, 'rb') as f_in:
						with gzip.open(gzfilepath, 'wb') as f_out:
							f_out.writelines(f_in)

				if chown_user != -1 and chown_group != -1:
					os.chown(gzfilepath, chown_user, chown_group)
				elif chown_user != -1:
					os.chown(gzfilepath, chown_user, os.stat(gzfilepath)[stat.ST_GID])
				elif chown_group != -1:
					os.chown(gzfilepath, os.stat(gzfilepath)[stat.ST_UID], chown_group)
					
def main(argv):
	if len(argv[1:]) == 0:
		usage(argv[0])
		
	from getopt import getopt
	(opts, paths)=getopt(argv[1:], 'hu:g:', ['help', 'user=', 'group='])

	chown_user = chown_group = -1

	import grp, pwd
	
	for (opt, val) in opts:		      
		if opt in ('-h', '--help'):
			usage(argv[0])
		elif opt in ('-u', '--user'):
			if len(val) < 1:
				print("Invalid user id/name");
				return 1
			chown_user = val
			try:
				try:
					pwd.getpwuid(chown_user)
				except (TypeError, ValueError):
					chown_user = pwd.getpwnam(chown_user).pw_uid
			except KeyError:
				print("Invalid User {0} Specified".format(chown_user))
				return 1				
		elif opt in ('-g', '--group'):
			if len(val) < 1:
				print("Invalid user id/name")
				return 1
			chown_group = val
			try:
				try:
					grp.getgrgid(chown_group)
				except (TypeError, ValueError):
					chown_group = grp.getgrnam(chown_group).gr_gid					
			except KeyError:
				print("Invalid Group {0} Specified".format(chown_group if not chown_group_int else "Id " + str(chown_group)))
				return 1

	import os, stat, gzip
	global os, stat, gzip
	
	for path in paths:
		if os.path.isdir(path) or (os.path.islink(path) and os.path.exists(path)):
			check_and_compress(path, chown_user, chown_group)			

import sys
main(sys.argv)
