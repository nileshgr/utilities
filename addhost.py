#!/usr/bin/python3

'''
Script written by Nilesh Govindrajan: http://nileshgr.com

Can add a host to nginx configuration and create document root, with php configuration enabled by default (fastcgi_php.conf must exist in nginx config root).

'''

def nginx_create_config(configpath, hostname, docroot):
    config='''server {{
server_name {0};
root {1};
include {2}/fastcgi_php.conf;
}}
'''.format(hostname, docroot, configpath)

    filename = '{0}/sites/{1}'.format(configpath, hostname)

    try:
        fd = open(filename)
        raise Exception('Configuration file {0} already exists'.format(filename))
    except IOError:
        fd = open(filename, 'w')
        fd.write(config)

def create_directory(os, docroot):        
    os.mkdir(docroot)
    os.system('chmod u=rwx,g=rwx,o= {0}'.format(docroot))

    import pwd
    uid = pwd.getpwnam('nginx').pw_uid

    import grp
    gid = grp.getgrnam('nginx').gr_gid

    os.chown(docroot, uid, gid)

def usage(progname):    
    print('''Usage: {0} [args]
-h | --host= Hostname
-d | --docroot= Document root of host (optional, defaults to /var/www/<hostname>)
-c | --configpath= Nginx config path (optional, defaults to /etc/nginx)
-? | --help This help message'''.format(progname))

def main(argv):
    progname = argv[0]
    args = argv[1:]

    if len(args) == 0:
        return usage(progname)

    from getopt import getopt

    (opts, extra) = getopt(args, '?h:d:c:', ['help', 'host=', 'configpath='])

    hostname = docroot = ''
    configpath = '/etc/nginx'

    for (opt, val) in opts:
        if opt in ('-?', '--help'):
            return usage(progname)
        elif opt in ('-h', '--host'):
            if len(val) < 1:
                raise Exception('Invalid hostname')
            hostname = val
        elif opt in ('-d', '--docroot'):
            if len(val) < 1:
                raise Exception('Invalid document root')
            docroot = val
        elif opt in ('-c', '--configpath'):
            if len(val) < 1:
                raise Exception('Invalid config path')
            configpath = val

    import os

    configpath = os.path.abspath(configpath)

    if len(docroot) > 0:
        docroot = os.path.abspath(docroot)
    else:
        docroot = '/var/www/{0}'.format(hostname)
        
    try:
        create_directory(os, docroot)
        nginx_create_config(configpath, hostname, docroot)
    except Exception as errmsg:
        print(errmsg)
        return 1

if __name__ == '__main__':
    import sys
    main(sys.argv)
