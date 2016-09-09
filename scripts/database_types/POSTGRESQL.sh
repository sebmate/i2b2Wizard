#!/bin/bash
# ==================================================================================================
# installDBMS() - Install the DBMS Software
# ==================================================================================================

installDBMS() {

	# PostgresSQL installation:
	installPostgreSQL
	cd $MY_PATH
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

    #Command to convert an upper-case string to lower-case (POSTGRESQL-specific)
	DB_PROJ_USER=`echo ${2,,}`

    if [ "$2" = "$DB_SYSUSER" ]; then
		tmp_server="$DB_SERVER:$DB_PORT/i2b2"	
    else
		tmp_server="$DB_SERVER:$DB_PORT/i2b2?searchpath=$DB_PROJ_USER"
    fi
    
    echo "# Created by i2b2 Wizard" > "$1db.properties" 
    echo "db.type=postgresql" >> "$1db.properties"
    echo "db.username=$DB_PROJ_USER" >> "$1db.properties"
    echo "db.password=$3" >> "$1db.properties"
    echo "db.server=$tmp_server" >> "$1db.properties"
    echo "db.driver=org.postgresql.Driver" >> "$1db.properties"
    echo "db.url=jdbc:postgresql://$tmp_server" >> "$1db.properties"
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
 	
	echo "SELECT CURRENT_DATE;" > "$MY_PATH/database/scripts/database_job.sql"
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/testDBConnectivity.log 2> $MY_PATH/logs/testDBConnectivity.err.log	
	rm $MY_PATH/database/scripts/database_job.sql

	cd $MY_PATH
	errorHandler $LINENO "Test database connection for $1" $MY_PATH/logs/testDBConnectivity.log $MY_PATH/logs/testDBConnectivity.err.log

}

# ==================================================================================================
# dropDatabaseUser() - Drop a database user
# ==================================================================================================

# Parameters: username

dropDatabaseUser() {
	
	cd "$MY_PATH/database/"
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $DB_SYSUSER $DB_SYSPASS
	checkJavaInstallation

	echo "DROP SCHEMA IF EXISTS $1 CASCADE;" >> "$MY_PATH/database/scripts/database_job.sql"
	$ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/dropDBuser.log 2> $MY_PATH/logs/dropDBuser.err.log
	echo "DROP USER IF EXISTS $1;" > "$MY_PATH/database/scripts/database_job.sql"
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/dropDBuser.log 2> $MY_PATH/logs/dropDBuser.err.log

	rm $MY_PATH/database/scripts/database_job.sql
	errorHandler $LINENO "Drop database user" $MY_PATH/logs/dropDBuser.log $MY_PATH/logs/dropDBuser.err.log

}
