


# ==================================================================================================
# checkFileChanged() - Tests if the contents of a file have changed
# ==================================================================================================

# Parameter: filename1 filename2 message

checkFileChanged() {

	return

	if cmp "$1" "$2"; then
		dialog --colors --backtitle "$BACKTITLE" --msgbox "$3: Files are the same: $1 and $2." 12 80
	else
		dialog --colors --backtitle "$BACKTITLE" --msgbox "$3: Files are different: $1 and $2." 12 80
	fi
}


# ==================================================================================================
# changeInFile() - Backup a file and change file contents
# ==================================================================================================

# Parameter: filename sed-string

changeInFile() {

	FILE=$1

	# Backup the file if not done yet:
	if [ ! -f "$FILE.wizard_orig" ]; then  
		cp -rf $FILE $FILE.wizard_orig
	fi

	# Create a temporary file:
	cp -rf $FILE $FILE.wizard_temp
	
	# Modify file with 'sed':
	IN=$2
	REP=$3
	cat $FILE.wizard_temp | sed -e "s§$IN§$REP§g" > $FILE
	
	checkFileChanged  $FILE.wizard_temp $FILE "Unspecified changeInFile() call"

}

# ==================================================================================================
# restoreOriginalFile() - Tries to restore an original file
# ==================================================================================================

# Parameter: original-filename 

restoreOriginalFile() {

	FILE=$1
	
	if [ -f "$FILE.wizard_orig" ]; then  
		cp -rf $FILE.wizard_orig $FILE
	fi

}


	

# ==================================================================================================
# httpDownload() - Downloads a file
# ==================================================================================================

# Parameter: url

httpDownload() {

	updateBackTitle
	
    URL=$1
    wget $URL 2>&1 | awk -F% 'NR>7 { if (length==0) exit; FS=" "; $0=$1; print $NF; FS="%" } system("")' | dialog --colors --backtitle "$BACKTITLE" --gauge "Downloading file: \n\n$URL ..." 10 69
    # (taken from: http://forum.ubuntu.pl/showthread.php?t=93776

}
		
# ==================================================================================================
# httpDownload2() - Downloads a file, including error handler
# ==================================================================================================

# Parameter: url filename

httpDownload2() {
	
	httpDownload $1
	updateBackTitle

    if [ ! -f "$2" ]; then
        dialog --colors --backtitle "$BACKTITLE" --msgbox "Error: Could not download file '$1'." 8 70
    fi
}


# ==================================================================================================
# httpDownloadWizard() - Downloads a file into the packages folder, including error handling and MD5
#                  checking
# ==================================================================================================

# Parameter: filename url md5sum

httpDownloadWizard() {

    DOWNLOAD_OK=0   
 
    while [ $DOWNLOAD_OK = 0 ]
    do

        MD5=" "
        if [ -f "$1" ]; then  
        	updateBackTitle
			
            dialog --colors --backtitle "$BACKTITLE" --infobox "Please wait - calculating MD5 checksum for '$1' ..." 5 60
            MD5=`md5sum $1 | cut -d ' ' -f 1-1`
        
        fi
        
		# Problem: MD5s do not match:
		if [ ! "$MD5" = "$3" ]; then  
			
			if [ "$2" = "manual" ]; then
				updateBackTitle
					
				dialog --colors --backtitle "$BACKTITLE" \
					   --yesno "The required file '$1' is either missing or it is corrupted (bad MD5 checksum). This is a file which has to be downloaded manually.\n\nDo you want to exit the application to correct this problem?" 10 70 
						   
				CORRECT=${?}
					
				if [ $CORRECT = 0 ]; then  
					clear
					echo -e "Please download the correct file and put it into the 'packages' subdirectory, then launch the i2b2 Wizard again.\n\nYou can try to download it with the following commands:\n\n  cd packages\n  wget $2";
					echo ""; exit
				fi
				DOWNLOAD_OK=1
				
			else
				
				if [ -f "$1" ]; then
					updateBackTitle
						
					dialog --colors --backtitle "$BACKTITLE" \
						   --yesno "The required file '$1' appears to be corrupted (bad MD5 checksum).\n\nDo you want to try to download the file again? If you select 'No', the installation will exit." 10 70 
							   
					NEW_DOWNLOAD=${?}
						
					if [ $NEW_DOWNLOAD = 1 ]; then  
						clear
						echo -e "Please download the correct file and put it into the 'packages' subdirectory, then launch the i2b2 Wizard again.\n\nYou can try to download it with the following commands:\n\n  cd packages\n  wget $2";
						echo ""; exit
					else
						rm $MY_PATH/packages/$1
					fi
				fi
			fi
 				
            if [ ! -f "$1" ]; then

				httpDownload $2
				
                if [ ! -f "$1" ]; then
					updateBackTitle
					
                    dialog --colors --backtitle "$BACKTITLE" \
                           --yesno "Could not download '$2'.\n\nDo you want to try it again? If you select 'No', the program will terminate." 10 70 

                    NEW_DOWNLOAD=${?}
                    
                    if [ $NEW_DOWNLOAD = 1 ]; then  
                        clear
						echo -e "Please download the correct file and put it into the 'packages' subdirectory, then launch the i2b2 Wizard again.\n\nYou can try to download it with the following commands:\n\n  cd packages\n  wget $2"; 
						echo ""; exit
                    fi
                fi
            fi
        else
            DOWNLOAD_OK=1   
        fi
        
    done
}

# ==================================================================================================
# autoDownloadPackages() - Downloads all missing packages
# ==================================================================================================

autoDownloadPackages() {
	
    if [ "$SYSTEM_SANE" = "yes" ]; then
     return;
    fi

    cd $MY_PATH/packages
	
	if ([ ! -f $FILECORESRC ] || [ ! -f $FILEDEMODATA ] || [ ! -f $FILEWEBCLIENT ]); then
		updateBackTitle
		
		dialog --colors --backtitle "$BACKTITLE" --inputbox "Please provide a valid server path to the i2b2 software packages:\n\n(If you do not have this information, please go to http://www.i2b2.org and download all files manually. Put them into the 'packages' subdirectory.)" 13 75 "http://www.imi.med.uni-erlangen.de/~matesn/i2b2wizard" 2>$TEMPVAR
				   
		SERVERPATH=`cat $TEMPVAR`
		  
		#httpDownloadWizard $FILEWORKBENCH $SERVERPATH/$FILEWORKBENCH $MD5WORKBENCH
		httpDownloadWizard $FILECORESRC $SERVERPATH/$FILECORESRC $MD5CORESRC
		httpDownloadWizard $FILEDEMODATA $SERVERPATH/$FILEDEMODATA $MD5DEMODATA
		httpDownloadWizard $FILEWEBCLIENT $SERVERPATH/$FILEWEBCLIENT $MD5WEBCLIENT
	
	fi

    # Check if we need to download Oracle XE:
    
	cd $MY_PATH/packages
	
	if [ -f /etc/debian_version ] && [ $DBTYPE = "ORACLE" ] ; then 
		INS=`aptitude search '~i ^oracle-xe-universal$'`
		if ([ "$INS" = ""  ] && [ "$DB_SERVER" = "localhost" ] && [ -f /etc/debian_version ] ); then 
			httpDownloadWizard oracle-xe-universal_10.2.0.1-1.1_i386.deb http://oss.oracle.com/debian/dists/unstable/non-free/binary-i386/oracle-xe-universal_10.2.0.1-1.1_i386.deb 3140db681260242c6e5951edfd5c17b5
		fi
	fi
	
    cd $MY_PATH
}


# ==================================================================================================
# setValues() - opens a form in which the user can set the system parameters
# ==================================================================================================

setValues() {

	updateBackTitle

	OLDDB=$DBTYPE
	OLDI2B2VER=$PRODUCT_VERSION	
	
	dialog --colors --backtitle "$BACKTITLE" --title " Configure Default Parameters "\
	    --form "Use [up] [down] to select input field, [tab] to select buttons " 0 0 0 \
	    "Target $PRODUCT version:" 1 4 "$PRODUCT_VERSION" 1 37 35 0\
	    "ORACLE or MSSQL database:" 2 4 "$DBTYPE" 2 37 35 0\
	    \
	    "DB server IP (localhost):" 4 4 "$DB_SERVER" 4 37 35 0\
	    "DB server port (1521):" 5 4 "$DB_PORT" 5 37 35 0\
	    "DB SSID (Oracle) (xe):" 6 4 "$ORA_SSID" 6 37 35 0\
	    "DB admin username (system/sa):" 7 4 "$DB_SYSUSER" 7 37 35 0\
	    "DB admin password (i2b2):" 8 4 "$DB_SYSPASS" 8 37 35 0\
	    "Allow 'system' access (yes):" 9 4 "$DB_ALLOW" 9 37 4 0\
		"Project schema prefix (I2B2):" 10 4 "$DB_SCHEMAPREFIX" 10 37 35 0\
	    \
	    "i2b2 Hive ID (i2b2demo):" 12 4 "$HIVE_ID" 12 37 35 0\
		\
	    "I2B2HIVE schema (i2b2hive):" 14 4 "$HIVE_SCHEMA" 14 37 35 0\
	    "I2B2HIVE password (i2b2hive):" 15 4 "$HIVE_PASS" 15 37 35 0\
	    "I2B2PM schema (i2b2pm):" 16 4 "$PM_SCHEMA" 16 37 35 0\
	    "I2B2PM password (i2b2pm):" 17 4 "$PM_PASS" 17 37 35 0\
	    \
	    "Use separate JBoss-user (no):" 19 4 "$USE_JBOSS_USER" 19 37 4 0\
	    "JBoss user login (jboss):" 20 4 "$JBOSS_USER" 20 37 35 0\
		\
	    "Use LDAP for login:" 22 4 "$USE_LDAP" 22 37 4 0\
	    "Authentication method:" 23 4 "$LDAP_AUTH" 23 37 35 0\
	    "Domain:" 24 4 "$LDAP_DOMAIN" 24 37 35 0\
	    "Domain controller:" 25 4 "$LDAP_CONTR" 25 37 35 0\
	    2>$TEMPVAR
	    
	if [ ${?} -ne 0 ]; then return; fi   
	
    PRODUCT_VERSION=`sed -n 1p $TEMPVAR`
    DBTYPE=`sed -n 2p $TEMPVAR`
    DB_SERVER=`sed -n 3p $TEMPVAR`
    DB_PORT=`sed -n 4p $TEMPVAR`
    ORA_SSID=`sed -n 5p $TEMPVAR`
    DB_SYSUSER=`sed -n 6p $TEMPVAR`
    DB_SYSPASS=`sed -n 7p $TEMPVAR`
    DB_ALLOW=`sed -n 8p $TEMPVAR`
	DB_SCHEMAPREFIX=`sed -n 9p $TEMPVAR`
	HIVE_ID=`sed -n 10p $TEMPVAR`
    HIVE_SCHEMA=`sed -n 11p $TEMPVAR`
    HIVE_PASS=`sed -n 12p $TEMPVAR`
    PM_SCHEMA=`sed -n 13p $TEMPVAR`
    PM_PASS=`sed -n 14p $TEMPVAR`
    USE_JBOSS_USER=`sed -n 15p $TEMPVAR`
    JBOSS_USER=`sed -n 16p $TEMPVAR`
    USE_LDAP=`sed -n 17p $TEMPVAR`
    LDAP_AUTH=`sed -n 18p $TEMPVAR`	
    LDAP_DOMAIN=`sed -n 19p $TEMPVAR`
    LDAP_CONTR=`sed -n 20p $TEMPVAR`
		
	SYSTEM_SANE=no

	saveValues

	if ([ ! $OLDDB = $DBTYPE  ] || [ ! $OLDI2B2VER = $PRODUCT_VERSION ]); then
	
		dialog --colors --backtitle "$BACKTITLE" --msgbox "Some values have been changed. They require a restart of i2b2 Wizard. Please run this program again." 6 70
		exitHandler
		exit
	fi

}


# ==================================================================================================
# autoUpdate() - Check if there is a new update for i2b2 Wizard.
# ==================================================================================================

autoUpdate() {

	return

	updateBackTitle
	echo "Checking for updates ..."
	
	rm updateinfo
	touch updateinfo
	
	wget --timeout=15 http://www.imi.med.uni-erlangen.de/~matesn/i2b2wizard/.autoupdate/$VER -O $MY_PATH/updateinfo > $MY_PATH/logs/autoupdate.log 2> $MY_PATH/logs/autoupdate.err.log
	
	LATESTVER=`awk 'NR == 1' updateinfo`
	URL=`awk 'NR == 2' updateinfo`
	FILE=`awk 'NR == 3' updateinfo`
	UPDATEPATH=`awk 'NR == 4' updateinfo`
	UPDATEABLE=`awk 'NR == 5' updateinfo`
	MESSAGE=`awk 'NR == 6' updateinfo`
	
	
	if [ ! $LATESTVER = $VER ]; then
	
		if [ $UPDATEABLE = 'yes' ]; then
			updateBackTitle 	
			dialog --colors --backtitle "$BACKTITLE" --title " Update for i2b2 Wizard found " --yesno "$MESSAGE" 10 80 
			SURE=${?}
			
			if [ ! $SURE = 1 ]; then  
				
				progressBar 0 "Backing up current i2b2 Wizard to backups/backup-$VER.zip ..."
				cd $MY_PATH
				mkdir -p backups
				zip -r backups/backup-$VER.zip . -x packages/*  > $MY_PATH/logs/backup.log 2> $MY_PATH/logs/backup.err.log
				errorHandler $LINENO "Backup i2b2 Wizard" $MY_PATH/logs/backup.log $MY_PATH/logs/backup.err.log
				httpDownload2 $URL $FILE
				unzip $FILE -d update
				rm $FILE
				cd update/$UPDATEPATH
				clear
				sh autoupdate.sh
				exitHandler
			fi
		else
			updateBackTitle
			dialog --colors --backtitle "$BACKTITLE" --title " Update for i2b2 Wizard found " --msgbox "$MESSAGE" 10 80 
		fi
	fi		
		
	#errorHandler $LINENO "AutoUpdate" $MY_PATH/logs/autoupdate.log $MY_PATH/logs/autoupdate.err.log
	
}


# ==================================================================================================
# errorHandler() - Shows an info-box if a task (e.g. Ant-script) has failed
# ==================================================================================================

# Parameters: line-number info-message .log-file .err.log-file

errorHandler() { 

	updateBackTitle
    if [ -f "$3" ]; then  

		TMP1=`cat $3 | tr a-z A-Z | grep 'FAILED'`
		TMP2=`cat $4 | tr a-z A-Z | grep 'FAILED'`

		TMP3=`cat $3 | tr a-z A-Z | grep 'ERROR'`
		TMP4=`cat $4 | tr a-z A-Z | grep 'ERROR'`

		TMP5=`cat $3 | tr a-z A-Z | grep "DOESN'T EXIST"`
		TMP6=`cat $4 | tr a-z A-Z | grep "DOESN'T EXIST"`

		TMP7=`cat $3 | tr a-z A-Z | grep 'CANNOT CREATE'`
		TMP8=`cat $4 | tr a-z A-Z | grep 'CANNOT CREATE'`

		TMP9=`cat $3 | tr a-z A-Z | grep ' ERRORS'`
		TMP10=`cat $4 | tr a-z A-Z | grep ' ERRORS'`

		TMP11=`cat $3 | tr a-z A-Z | grep 'Error'`
		TMP12=`cat $4 | tr a-z A-Z | grep 'Error'`

		TMP13=`cat $3 | tr a-z A-Z | grep 'COMMAND NOT FOUND'`
		TMP14=`cat $4 | tr a-z A-Z | grep 'COMMAND NOT FOUND'`
		
		TEST1="$TMP1$TMP3$TMP5$TMP7$TMP9$TMP11$TMP13"
		TEST2="$TMP2$TMP4$TMP6$TMP8$TMP10$TMP12$TMP14"

        if [ -n "$TEST1" ] ; then
			SYSTEM_SANE=no
			updateBackTitle  
            dialog --colors --backtitle "$BACKTITLE" --title " Error: Failed before line $1 with task $2 " --textbox $3 20 100
        fi
		
        if [ -n "$TEST2" ]; then
			updateBackTitle  
			SYSTEM_SANE=no
			dialog --colors --backtitle "$BACKTITLE" --title " Error: Failed before line $1 with task '$2' " --textbox $4 20 100
        fi
		
    fi
 	if [ ! -f "$4" ]; then   
		SYSTEM_SANE=no
		updateBackTitle
		dialog --colors --backtitle "$BACKTITLE" --msgbox "Error: Failed before line $1 with task '$2' for unknown reason (a log file was not found although it was expected). Maybe the error message can be seen if you scroll upwards in this terminal. Please check script!" 10 70
		return;
 	fi
	if [ ! -f "$3" ]; then  
		SYSTEM_SANE=no
		updateBackTitle
		dialog --colors --backtitle "$BACKTITLE" --msgbox "Error: failed before line $1 with task '$2' for unknown reason (a log file was not found although it was expected). Maybe the error message can be seen if you scroll upwards in this terminal. Please check script!" 10 70
	    return;
 	fi

}


# ==================================================================================================
# saveValues() - saves the program-variables to wizard.conf
# ==================================================================================================

saveValues() {
	
    cd $MY_PATH
    rm $MY_PATH/config/wizard.conf
    
    echo "# --- Created by wizard.sh ---" > $MY_PATH/config/wizard.conf

    echo "PRODUCT=$PRODUCT" >> $MY_PATH/config/wizard.conf
 
    echo "PRODUCT_VERSION=$PRODUCT_VERSION" >> $MY_PATH/config/wizard.conf
    echo "DBTYPE=$DBTYPE" >> $MY_PATH/config/wizard.conf

    echo "DB_SERVER=$DB_SERVER" >> $MY_PATH/config/wizard.conf
    echo "DB_PORT=$DB_PORT" >> $MY_PATH/config/wizard.conf
    echo "DB_SYSUSER=$DB_SYSUSER" >> $MY_PATH/config/wizard.conf
    echo "DB_SYSPASS=$DB_SYSPASS" >> $MY_PATH/config/wizard.conf
    echo "DB_ALLOW=$DB_ALLOW" >> $MY_PATH/config/wizard.conf
    echo "ORA_SSID=$ORA_SSID" >> $MY_PATH/config/wizard.conf
	echo "DB_SCHEMAPREFIX=$DB_SCHEMAPREFIX" >> $MY_PATH/config/wizard.conf
	
	
	if [ $DBTYPE = "MSSQL" ]; then
		DB_CONNECTIONSTRING="$DB_SERVER:$DB_PORT"
	else
		DB_CONNECTIONSTRING="$DB_SERVER:$DB_PORT:$ORA_SSID"
	fi
	
	echo "DB_CONNECTIONSTRING=$DB_CONNECTIONSTRING" >> $MY_PATH/config/wizard.conf
		
    echo "HIVE_SCHEMA=$HIVE_SCHEMA" >> $MY_PATH/config/wizard.conf
    echo "PM_SCHEMA=$PM_SCHEMA" >> $MY_PATH/config/wizard.conf
    echo "HIVE_PASS=$HIVE_PASS" >> $MY_PATH/config/wizard.conf
    echo "PM_PASS=$PM_PASS" >> $MY_PATH/config/wizard.conf
    echo "HIVE_ID=$HIVE_ID" >> $MY_PATH/config/wizard.conf
    echo "USE_JBOSS_USER=$USE_JBOSS_USER" >> $MY_PATH/config/wizard.conf
    echo "JBOSS_USER=$JBOSS_USER" >> $MY_PATH/config/wizard.conf
    echo "LAST_PROJECT='$LAST_PROJECT'" >> $MY_PATH/config/wizard.conf
    echo "IP_ADDR=$IP_ADDR" >> $MY_PATH/config/wizard.conf

    echo "LAST_USER='$LAST_USER'" >> $MY_PATH/config/wizard.conf
    echo "CONFIG_DIRTY=$CONFIG_DIRTY" >> $MY_PATH/config/wizard.conf
    echo "SYSTEM_SANE=$SYSTEM_SANE" >> $MY_PATH/config/wizard.conf
    echo "PM_HIVE_LOADED=$PM_HIVE_LOADED" >> $MY_PATH/config/wizard.conf

    echo "USE_LDAP=$USE_LDAP" >> $MY_PATH/config/wizard.conf
    echo "LDAP_AUTH=$LDAP_AUTH" >> $MY_PATH/config/wizard.conf
    echo "LDAP_DOMAIN=$LDAP_DOMAIN" >> $MY_PATH/config/wizard.conf
    echo "LDAP_CONTR=$LDAP_CONTR" >> $MY_PATH/config/wizard.conf
		
	#echo "JAVA_HOME=$JAVA_HOME" >> $MY_PATH/config/wizard.conf
	#echo "JBOSSSTATUS=$JBOSSSTATUS" >> $MY_PATH/config/wizard.conf
	#echo "JBOSSSTARTEDATSTART=$JBOSSSTARTEDATSTART" >> $MY_PATH/config/wizard.conf
	#echo "TOMCATSTATUS=$TOMCATSTATUS" >> $MY_PATH/config/wizard.conf
	
	echo "MYSQL_ROOT_PASS=$MYSQL_ROOT_PASS" > $MY_PATH/config/shrine.conf
    echo "MYSQL_SHRINE_PASS=$MYSQL_SHRINE_PASS" >> $MY_PATH/config/shrine.conf
	echo "KEYSTORE_PASSWORD='$KEYSTORE_PASSWORD'" >> $MY_PATH/config/shrine.conf
	echo "KEYSTORE_HUMAN='$KEYSTORE_HUMAN'" >> $MY_PATH/config/shrine.conf
	echo "KEYSTORE_CITY='$KEYSTORE_CITY'" >> $MY_PATH/config/shrine.conf
	echo "KEYSTORE_STATE='$KEYSTORE_STATE'" >> $MY_PATH/config/shrine.conf
	echo "KEYSTORE_COUNTRY='$KEYSTORE_COUNTRY'" >> $MY_PATH/config/shrine.conf
	echo "SHRINE_NODENAME='$SHRINE_NODENAME'" >> $MY_PATH/config/shrine.conf
			
    chmod +x $MY_PATH/config/wizard.conf
	chmod +x $MY_PATH/config/shrine.conf


    createStartStopScripts
	
}


# ==================================================================================================
# updateBackTitle() - refreshes the JBoss-status in the upper left corner
# ==================================================================================================

updateBackTitle() {

    RUNNING_INFO1="[JBoss/i2b2: \Z1STOPPED\Zn]"
    RUNNING_INFO2="[Tomcat/SHRINE: \Z1STOPPED\Zn]"

    getJBossStatus
	getTomcatStatus

    if [ "$JBOSSSTATUS" = "1" ]; then  
        RUNNING_INFO1="[JBoss/i2b2: \Z2RUNNING\Zn]"
    fi   

    if [ "$TOMCATSTATUS" = "1" ]; then  
        RUNNING_INFO2="[Tomcat/SHRINE: \Z2RUNNING\Zn]"
    fi   

    if [ "$SILENT" = "1" ]; then  
        SILENT_INFO="\Z1>>> ATTEMPTING AUTOMATIC INSTALLATION <<<\Zn "
    fi  
	
    BACKTITLE="$RUNNING_INFO1 $RUNNING_INFO2 $SILENT_INFO:::::::::::..  i2b2 Wizard $VER  ..::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"

}

# ==================================================================================================
# progressBar() - Shows a progress bar.
# ==================================================================================================

progressBar() {
	updateBackTitle
		
	#{
	#	echo "XXX\n$1\n$2\nXXX"
	#} | dialog --colors --backtitle "$BACKTITLE" --gauge "$2" 6 70 0

	echo "$1" | dialog --colors --backtitle "$BACKTITLE" --gauge "$2" 6 70 0
	
}

# ==================================================================================================
# notImplementedYet() - Display "Not implemented yet!" message
# ==================================================================================================

notImplementedYet() {

	updateBackTitle
    dialog --colors --backtitle "$BACKTITLE" --msgbox "Not implemented yet!" 6 40
  
}

# ==================================================================================================
# exitHandler() - called before leaving the program
# ==================================================================================================

exitHandler() {

	updateBackTitle
    createStartStopScripts
    setFilePermissions
    getJBossStatus
	
    if ([ "$JBOSSSTARTEDATSTART" = "1" ] &&[ "$JBOSSSTATUS" = "0" ]); then
		
		updateBackTitle
        dialog --colors --backtitle "$BACKTITLE" --title " Exit Program "\
               --yesno "JBoss was running when Wizard was started. Restart JBoss?" 5 70 
        RESTART=${?}
        if [ $RESTART = 0 ]; then  
            startJBoss;
        fi
    fi    

    if [ $CONFIG_DIRTY = "yes" ]; then
		updateBackTitle  
        dialog --colors --backtitle "$BACKTITLE" --title " Exit Program "\
               --yesno "The i2b2 Hive configuration has been changed. Do you want to re-deploy the webservices and restart JBoss?" 6 70 
        RESTART=${?}
        if [ $RESTART = 0 ]; then  
            startJBoss;
        fi
    fi    

    RUNNING_INFO="JBOSS: STOPPED"
    getJBossStatus
    if [ "$JBOSSSTATUS" = "1" ]; then  
        RUNNING_INFO="JBOSS: RUNNING"
    fi
    
    #saveValues
    clear
	echo "$RUNNING_INFO"; echo ""; echo "Thank you for using i2b2 Wizard."; echo ""
    exit

}


# ==================================================================================================
# showMessageAndExit() - Display a message and terminate program.
# ==================================================================================================

showMessageAndExit() {

	updateBackTitle
	clear
	echo $*
	exit

}


# ==================================================================================================
# runETL() - Executes an arbitrary Oracle SQL file
# ==================================================================================================

# Parameter: filename

runETL() {

	updateBackTitle
    dialog --colors --backtitle "$BACKTITLE" --infobox "Please wait - executing '$1.sql'" 5 50

    cd $MY_PATH/ETL/

    # Transform the SQL-file so that we can execute it with Ant. Idea taken from:
    # http://technology.amis.nl/blog/620/executing-plsql-from-ant-how-to-keep-the-format-straight
    
    FILE="$MY_PATH/ETL/scripts/$1.sql"
    sed -e '/\-\-PLSQLSTART/,/\-\-PLSQLEND/ !s/\;/\n_\n/g;' \
        -e '/\-\-PLSQLSTART/,/\-\-PLSQLEND/ s/\///;'\
        -e 's/\-\-PLSQLSTART/_/g;' \
        -e 's/\-\-PLSQLEND/_/g;' \
        -e 's/\-\-.*/_/g;' <$FILE >$FILE.run
    
    checkJavaInstallation
    $ANT_HOME/bin/ant -f run_etl.xml $1 > $MY_PATH/logs/run_etl_$1.log 2> $MY_PATH/logs/run_etl_$1.err.log

    rm "$MY_PATH/ETL/scripts/$1.sql.run"

    errorHandler $LINENO "ETL-task $1" $MY_PATH/logs/run_etl_$1.log $MY_PATH/logs/run_etl_$1.err.log
}

