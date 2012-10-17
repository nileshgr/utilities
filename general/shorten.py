#!/usr/bin/python3

apikey = '' # bitly api key
login = '' # bitly login

import sys, re, urllib.request, urllib.parse

if len(sys.argv) < 2:
	sys.exit(1)

istr = sys.argv[1]

matches = re.finditer('https?://[\w\+.\-_=\(\)%\[\]\?/@#&!:;,]+', istr)

for match in matches:
	url = match.group(0)
	ec_url = urllib.parse.urlencode({'format': 'txt', 'apiKey': apikey, 'longUrl': url, 'login': login})
	req = "http://api.bitly.com/v3/shorten?%s" % ec_url
	shorturl = urllib.request.urlopen(req).read().decode()
	shorturl = shorturl[:-1]
	istr = istr.replace(url, shorturl)

print(istr, end='')
