#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

alias psql="psql -h db1"
alias pg_dump="pg_dump -h db1"

databases=$(psql -A -t -c "select datname from pg_database where datname not in ('template0', 'template1', 'postgres')" postgres)

for d in $databases
do	
	pg_dump -Fc -f ${d}.dump -Z 0
	xz -9e ${d}.dump
done
