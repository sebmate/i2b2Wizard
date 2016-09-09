

# ==================================================================================================
# installDBMS() - Install the DBMS Software
# ==================================================================================================

installDBMS() {

	# PostgresSQL installation:
	installOracleXE10
	cd $MY_PATH

}



# ==================================================================================================
# enableRemoteOracle() - Enable remote access to the Oracle HTTP web-interface
# ==================================================================================================

enableRemoteOracle() {

	# Does not work yet. For a solution, refer to an e-mail by Mike Mendis.
	
    notImplementedYet
    return
	
	# --- Will not go below this line ---

    cd "$MY_PATH/database"

    DIR="$MY_PATH/database/"
    createDBProperties $DIR $DB_SYSUSER $DB_SYSPASS

    echo "EXEC DBMS_XDB.SETLISTENERLOCALACCESS(FALSE);" > "$MY_PATH/database/scripts/database_job.sql"

    checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/enable_remote_access.log 2> $MY_PATH/logs/enable_remote_access.err.log
    rm $MY_PATH/database/scripts/database_job.sql

    cd $MY_PATH

    errorHandler $LINENO "Enable Oracle remote HTTP access" $MY_PATH/logs/enable_remote_access.log $MY_PATH/logs/enable_remote_access.err.log

}


# ==================================================================================================
# createDBProperties() - creates a dp.properties-file
# ==================================================================================================

# Parameters: directory username password server

createDBProperties() {
 
	updateBackTitle
	
    if [ ! -d "$1" ]; then  
       dialog --colors --backtitle "$BACKTITLE" --msgbox "Error: failed to create properties file at $1db.properties." 10 70
	   return;
 	fi
	
	touch $1 > $MY_PATH/logs/createDBProperties.log 2> $MY_PATH/logs/createDBProperties.err.log

    SERVER_STRING="$DB_SERVER:$DB_PORT:$ORA_SSID"

    echo "# Created by i2b2 Wizard" > "$1db.properties" 
    echo "db.type=oracle" >> "$1db.properties"
    echo "db.username=$2" >> "$1db.properties"
    echo "db.password=$3" >> "$1db.properties"
    echo "db.server=$SERVER_STRING" >> "$1db.properties"
    echo "db.driver=oracle.jdbc.driver.OracleDriver" >> "$1db.properties"
    echo "db.url=jdbc:oracle:thin:@$SERVER_STRING" >> "$1db.properties"
    echo "$5" >> "$1db.properties"

	errorHandler $LINENO "createDBProperties for $1" $MY_PATH/logs/createDBProperties.log $MY_PATH/logs/createDBProperties.err.log

}


# ==================================================================================================
# testDBConnectivity() - Test if a database connection works
# ==================================================================================================

# Parameters: user password

testDBConnectivity() {

	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Testing database connectivity for '$1' ..." 5 60
	
	cd "$MY_PATH/database/"	
	DIR="$MY_PATH/database/"
	
	createDBProperties $DIR $1 $2
 
	echo "SELECT * FROM DUAL;" > "$MY_PATH/database/scripts/database_job.sql"
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/testDBConnectivity.log 2> $MY_PATH/logs/testDBConnectivity.err.log
	
	rm $MY_PATH/database/scripts/database_job.sql

	cd $MY_PATH

	errorHandler $LINENO "Test database connection for $1" $MY_PATH/logs/testDBConnectivity.log $MY_PATH/logs/testDBConnectivity.err.log

}



# ==================================================================================================
# fixTNSProblem()
# ==================================================================================================

# This tries to fix a problem with i2b2 1.6.03, which apperently does not close all JDBC connections and throws
# ORA-12519 error messages: "TNS:no appropriate service handler found".

fixTNSProblem() {

	if ([ ! "$DB_SERVER" = "localhost" ]); then 
		return
	fi

	progressBar 0 "ORA-12519 workaround: setting PROCESSES=500 ..."

	DIR="$MY_PATH/database/"
	createDBProperties $DIR $DB_SYSUSER $DB_SYSPASS

	I2B2DB_USR=$DB_USER
	I2B2DB_PWD=$DB_PASS

	FILE="$MY_PATH/database/scripts/database_job.sql"
	
	echo "alter system set processes=500 scope=spfile;" > $FILE
	echo "commit;" >> $FILE
 
	cd $MY_PATH/database
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/fixTNSProblem.log 2> $MY_PATH/logs/fixTNSProblem.err.log
	errorHandler $LINENO "Fix TNS Problem (1)" $MY_PATH/logs/fixTNSProblem.log $MY_PATH/logs/fixTNSProblem.err.log
		
	progressBar 10 "ORA-12519 workaround: Stopping Oracle database ..."

	/etc/init.d/oracle-xe stop > $MY_PATH/logs/stopOracle.log 2> $MY_PATH/logs/stopOracle.err.log
	errorHandler $LINENO "Fix TNS Problem (2)" $MY_PATH/logs/fixTNSProblem.log $MY_PATH/logs/fixTNSProblem.err.log
	
	progressBar 50 "ORA-12519 workaround: Starting Oracle database ..."
	/etc/init.d/oracle-xe start > $MY_PATH/logs/startOracle.log 2> $MY_PATH/logs/startOracle.err.log
	errorHandler $LINENO "Fix TNS Problem (2)" $MY_PATH/logs/startOracle.log $MY_PATH/logs/startOracle.err.log

}

# ==================================================================================================
# dropDatabaseUser() - Drop a database user
# ==================================================================================================

# Parameters: username


dropDatabaseUser() {
	
	cd "$MY_PATH/database/"
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $DB_SYSUSER $DB_SYSPASS

	echo "DROP USER $1 CASCADE;" > "$MY_PATH/database/scripts/database_job.sql"
		
	checkJavaInstallation
        $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/dropDBuser.log 2> $MY_PATH/logs/dropDBuser.err.log
	rm $MY_PATH/database/scripts/database_job.sql
	
	errorHandler $LINENO "Drop database user" $MY_PATH/logs/dropDBuser.log $MY_PATH/logs/dropDBuser.err.log

}
