#!/bin/bash

# Script to copy one MySQL database to another while converting the destination database to InnoDB
# Author: Nilesh Govindrajan <contact@nileshgr.com>

DBUSER=''
DBPASS=''

OLDDBNAME=''
NEWDBNAME=''

TABLES=$(mysql -A "$OLDDBNAME" --user="$DBUSER" --password="$DBPASS" -r -N -e 'show tables')

mysql --user="$DBUSER" --password="$DBPASS" -e "CREATE DATABASE $NEWDBNAME"

for table in $TABLES; do
    sql="CREATE TABLE $table LIKE ${OLDDBNAME}.${table};"
    echo "$sql"
    mysql -A "$NEWDBNAME" --user="$DBUSER" --password="$DBPASS" -e "$sql"
    sql="ALTER TABLE $table ENGINE=InnoDB;"
    echo "$sql"
    mysql -A "$NEWDBNAME" --user="$DBUSER" --password="$DBPASS" -e "$sql"
    sql="INSERT INTO ${table} SELECT * FROM ${OLDDBNAME}.${table};"
    echo "$sql"
    mysql -A "$NEWDBNAME" --user="$DB_USER" --password="$DBPASS" -e "$sql"
done
