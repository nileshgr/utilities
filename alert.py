#!/usr/bin/python3

# A script by Nilesh Govindrajan: http://nileshgr.com

# List of mount points/disks to monitor

disks = ['/', '/home']

# Specify emails as an array of tuples, first element of tuple as Name of the person and second email address, see the example below:

email = [('Mr. Example', 'example@example.com'), ('Example 2', 'example2@example.net')]

disk_alert_percent = 90 # When disk usage touches this value, emails will be sent
swap_alert_percent = 10 # When swap usage touches this value, emails will be sent

email_from = 'no-reply@yourcompany.com' # Emails will be sent from this address

import subprocess, re, smtplib, socket
from email.mime.text import MIMEText
from email.utils import formataddr

smtp = smtplib.SMTP('localhost')
server = socket.gethostname()

# Disk space alert
for disk in disks:
    used_percent = int(re.search("(\d{0,2})%", subprocess.check_output(['df', '-h', disk], universal_newlines=True).split("\n")[1]).group(1))
    if(used_percent >= disk_alert_percent):
        for e in email:
            msg = MIMEText("Disk Usage on disk {0} (server '{1}') is {2}%\n".format(disk, server, used_percent))
            msg['Subject'] = "Disk Usage alert for server '{0}'".format(server)
            msg['From'] = email_from
            msg['To'] = formataddr(e)
            smtp.send_message(msg)
            del msg

with open('/proc/meminfo') as meminfo:
    lines = meminfo.readlines()
    free = 0
    total = 0
    for line in lines:
        if free > 0 and total > 0:
            break
        if line.find("SwapFree") != -1:
            free = int(re.search("SwapFree:\ *(\d+)", line).group(1))
        elif line.find("SwapTotal") != -1:
            total = int(re.search("SwapTotal:\ *(\d+)", line).group(1))
    if (total - free) / total >= swap_alert_percent/100:
        for e in email:
            msg = MIMEText("Swap Usage is (server '{0}') {1:.1%}\n".format(server, (total - free) / total))
            msg['Subject'] = "Swap Usage alert for server '{0}'".format(server)
            msg['From'] = email_from     
            msg['To'] = formataddr(e)
            smtp.send_message(msg)
            del msg
