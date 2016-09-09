


# ==================================================================================================
# installDBMS() - Install the DBMS Software
# ==================================================================================================

installDBMS() {

	return

}

# ==================================================================================================
# enableRemoteOracle() - Enable remote access to the Oracle HTTP web-interface
# ==================================================================================================

enableRemoteOracle() {

    showMessageAndExit enableRemoteOracle $*

}


# ==================================================================================================
# createDBProperties() - creates a dp.properties-file
# ==================================================================================================

# Parameters: filename_with_path username password server additional_parameters

createDBProperties() {
 
	updateBackTitle
	
    if [ ! -d "$1" ]; then  
       dialog --colors --backtitle "$BACKTITLE" --msgbox "Error: failed to create properties file at $1db.properties." 10 70
	   return;
 	fi
		
	touch $1 > $MY_PATH/logs/createDBProperties.log 2> $MY_PATH/logs/createDBProperties.err.log

    echo "# Created by i2b2 Wizard" > "$1db.properties" 
    echo "db.type=sqlserver" >> "$1db.properties"
    echo "db.username=$2" >> "$1db.properties"
    echo "db.password=$3" >> "$1db.properties"
    echo "db.server=$4" >> "$1db.properties"
    echo "db.driver=com.microsoft.sqlserver.jdbc.SQLServerDriver" >> "$1db.properties"
    echo "db.url=jdbc:sqlserver://$DB_SERVER:$DB_PORT;databasename=$2" >> "$1db.properties"
    echo "db.project=demo" >> "$1db.properties"

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
	
	createDBProperties $DIR $1 $2 "$DB_SERVER:$DB_PORT:$ORA_SSID"
 
	echo "SELECT GETDATE()" > "$MY_PATH/database/scripts/database_job.sql"
	
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

	return
	#showMessageAndExit fixTNSProblem $*
}

# ==================================================================================================
# dropDatabaseUser() - Drop a database user
# ==================================================================================================

# Parameters: username

dropDatabaseUser() {
	
	cd "$MY_PATH/database/"
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $DB_SYSUSER $DB_SYSPASS "$DB_SERVER:$DB_PORT:$ORA_SSID"

	echo "DROP DATABASE $1;" > "$MY_PATH/database/scripts/database_job.sql"
	echo "DROP USER $1;" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DROP LOGIN $1;" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DROP SCHEMA $1;" >> "$MY_PATH/database/scripts/database_job.sql"
		
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/dropDBuser.log 2> $MY_PATH/logs/dropDBuser.err.log
	rm $MY_PATH/database/scripts/database_job.sql
	
	errorHandler $LINENO "Drop database user" $MY_PATH/logs/dropDBuser.log $MY_PATH/logs/dropDBuser.err.log

}
