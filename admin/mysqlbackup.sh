#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

alias mysql='mysql -r -s -u backup -h db1'
alias mysqldump='mysqldump -u backup -h db1'

databases=$(echo show databases | mysql | grep -vE 'information_schema|performance_schema')

for d in $databases
do	
	mkdir $d
	cd $d

	echo Backing up structure of $d
	mysqldump -R -t -d --add-drop-database $d | xz -9e > structure.sql.xz

	mkdir tables
	cd tables

	tables=$(echo show tables | mysql $d)

	for t in $tables
	do
		echo Backing up $t of $d
		mysqldump --add-drop-table $d $t | xz -9e > ${t}.sql.xz
	done

	cd ..
	cd ..
done
