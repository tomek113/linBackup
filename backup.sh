#!/bin/bash

HOME_DIR="Cannot be empty"
PROFILE_NAME=$1

function checkStatus 
{
if [ "$?" -ne 0 ]
                        then
                                echo "ERROR: Backup failed."
                                exit 1
                        fi
}

function runBackup
{
	for PROF in $PROF_LIST
        do
		grep ^$PROF $HOME_DIR/profiles.conf > /dev/null
		if [ $? -eq 1 ]
		then
			echo "ERROR: Profile $PROF does not exist, skipping."
			break
		fi
                PROFILE_NAME=`echo $PROF |cut -d"," -f1`
                SOURCE=`echo $PROF |cut -d"," -f2`
                DEST=`echo $PROF |cut -d"," -f3`
                COMPR=`echo $PROF |cut -d"," -f4`
		ENCRYPTION=`echo $PROF |cut -d"," -f5`
                echo "RUNNING: $PROFILE_NAME, Compression: $COMPR, Encryption: $ENCRYPTION"
		if [ "$ENCRYPTION" = "Y" ]
		then
			tar -cf $DEST $SOURCE
			checkStatus
			ENC_PASSWORD=`grep ^$PROFILE_NAME $HOME_DIR/password.db |cut -d"," -f2`
			gpg --batch --yes --passphrase $ENC_PASSWORD -c --cipher-algo AES256 $DEST
			checkStatus
			rm -f $DEST
		elif [ "$COMPR" = "Y" ]
		then
			tar -cf $DEST $SOURCE
			checkStatus
			gzip -f $DEST
			checkStatus
		else
			tar -cf $DEST $SOURCE
			checkStatus
		fi
		echo "INFO: Backup completed successfully."
	done
}

echo "INFO: Starting backup procedure. User: `whoami` Date: `date`" 

if [ "$PROFILE_NAME" = "" ]
then
	echo "INFO: All profiles will be backed up."
	PROF_LIST=`cat $HOME_DIR/profiles.conf |grep -v ^#`
	if [ "$PROF_LIST" = "" ]
	then
		echo "ERROR: No profiles to process."
		exit 1
	fi
	echo "INFO: Profiles list: `echo "$PROF_LIST" |cut -d"," -f1 |tr "\n" " "`"
	runBackup
else
	echo "INFO: Profiles list: $PROFILE_NAME"
	PROFILE_NAME=`echo ^$PROFILE_NAME |sed 's/,/,|^/g'`,
	PROF_LIST=`egrep "$PROFILE_NAME" $HOME_DIR/profiles.conf`
	if [ "$PROF_LIST" = "" ]
        then
                echo "ERROR: No profiles to process."
                exit 1
        fi
	runBackup
fi
