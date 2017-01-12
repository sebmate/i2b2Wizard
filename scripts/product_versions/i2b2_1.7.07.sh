# i2b2 source path - where i2b2 gets expanded to:
I2B2_SRC=/i2b2src

# i2b2 <= 1.6
#BASE_APPDIR=/opt
#JBOSS_HOME=$BASE_APPDIR/jboss-4.2.2.GA
#ANT_HOME=$BASE_APPDIR/apache-ant-1.6.5
#JBOSS_LOG=$JBOSS_HOME/standalone/log/boot.log
#JBOSS_LOG_2=$JBOSS_HOME/standalone/log/server.log

# i2b2 >= 1.7
BASE_APPDIR=/opt
JBOSS_HOME=$BASE_APPDIR/jboss-as-7.1.1.Final
ANT_HOME=$BASE_APPDIR/apache-ant-1.8.2
JBOSS_LOG=$JBOSS_HOME/standalone/log/boot.log
JBOSS_LOG_2=$JBOSS_HOME/standalone/log/server.log

export JBOSS_HOME
export ANT_HOME

case "$PATH" in
   *$ANT_HOME*) ;;
   *) PATH=$PATH:$ANT_HOME/bin ;;
esac

export PATH

# To recreate this script for a new i2b2 version, please modify the file names and MD5 checksums below. With lots of luck, it will work out of the box ... ;-)

export FILECORESRC=i2b2core-src-1707.zip
export MD5CORESRC=f870577805a1881bf8218308c0e9dbad

export FILEDEMODATA=i2b2createdb-1707.zip
export MD5DEMODATA=6ce51b09c20779439ac1b26d19244b24

export FILEWEBCLIENT=i2b2webclient-1707.zip
export MD5WEBCLIENT=c6271c4d373a861e4b8861f31589aa3d

# This is used to create the path for the Jboss Datasources files. Use the "generic" version (which ends with .x) whenever
# possible. For a new version it might be necessary to create new templates in the config directory:

export DS_TEMPLATE_VERSION="1.7.x"

# The "release path" can be found in the ZIP demodata file. It is required for this script to work:

export RELEASEPATH=Release_1-7
export I2B2RELEASE=1-7

# Working-Directories for i2b2 Webservices: 
IM_APPDIR=$JBOSS_HOME/standalone/configuration/imapp
CRC_APPDIR=$JBOSS_HOME/standalone/configuration/crcapp
FR_APPDIR=$JBOSS_HOME/standalone/configuration/frapp
ONT_APPDIR=$JBOSS_HOME/standalone/configuration/ontologyapp
WORK_APPDIR=$JBOSS_HOME/standalone/configuration/workplaceapp

IM_APPDIR_FILE=$I2B2_SRC/edu.harvard.i2b2.im/etc/spring/im_application_directory.properties
CRC_APPDIR_FILE=$I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/crc_application_directory.properties
FR_APPDIR_FILE=$I2B2_SRC/edu.harvard.i2b2.fr/etc/spring/fr_application_directory.properties
ONT_APPDIR_FILE=$I2B2_SRC/edu.harvard.i2b2.ontology/etc/spring/ontology_application_directory.properties
WORK_APPDIR_FILE=$I2B2_SRC/edu.harvard.i2b2.workplace/etc/spring/workplace_application_directory.properties


# ==================================================================================================
# autoInstallApps() - installs the necessary applications for this i2b2 version
# ==================================================================================================

autoInstallApps() {

	if [ "$SYSTEM_SANE" = "yes" ]; then
        return;
    fi

	if [ "$IP_ADDR" = "" ]; then
		getIP
	fi
	
    stopJBoss

    autoPackageInstall verbose 'UnnecessaryPackage' # Used to check if the OS script can ignore unnecessary packages.
	#autoPackageInstall verbose 'SomethingStupid' # Used to check if the OS script can detect bad package names.
	

	if [ ! "$DOCKER" = "1" ]; then
       
        # This one is not installed on all systems by default:
        autoPackageInstall verbose 'unzip'
        autoPackageInstall verbose 'aptitude'
        autoPackageInstall verbose 'wget'
        autoPackageInstall verbose 'openjdk-7-jre'
        autoPackageInstall verbose 'openjdk-7-jdk'
        autoPackageInstall verbose 'curl'
        autoPackageInstall verbose 'libcurl3'
        autoPackageInstall verbose 'php5-curl'
        autoPackageInstall verbose 'apache2'
        autoPackageInstall verbose 'libaio1'
        autoPackageInstall verbose 'libapache2-mod-php5'

        # These should already be installed, but to be sure, let's invoke the install function:
        autoPackageInstall verbose 'perl'
        autoPackageInstall verbose 'sed'
        autoPackageInstall verbose 'bc'
   
    fi

    checkJavaInstallation
    autoDownloadPackages
    autoExpandSource 
	
	installAnt182
	installJBoss711
	
	restartApache
	
	installDBMS
	
	testDBConnectivity $DB_SYSUSER $DB_SYSPASS

    SYSTEM_SANE=yes
	saveValues

}


# ==================================================================================================
# autoExpandSource() - unzips the sourcecode (if necessary)
# ==================================================================================================

autoExpandSource() {

    # Expand i2b2 Source Code: 

    

	autoDownloadPackages
	
    if [ ! -d "$I2B2_SRC" ]; then  

        mkdir $I2B2_SRC

        # i2b2 workbench source:
        #progressBar 0 "Expanding i2b2 workbench source code ..."
        #unzip -o $MY_PATH/packages/$FILEWORKBENCH -d $I2B2_SRC > /dev/null
        #mv $I2B2_SRC/src/* $I2B2_SRC/
        #rm -r $I2B2_SRC/src
        
        # i2b2 hive source:
        progressBar 25 "Expanding i2b2 hive source code ..."
        unzip -o $MY_PATH/packages/$FILECORESRC -d $I2B2_SRC > /dev/null
		
		# TODO: automatically determine paths of ZIP file:
		
	    if [ -d "$I2B2_SRC/Server" ]; then  
			mv $I2B2_SRC/Server/* $I2B2_SRC/ > /dev/null
			rm -r $I2B2_SRC/Server > /dev/null
        fi
				
	    if [ -d "$I2B2_SRC/src" ]; then  
			mv $I2B2_SRC/src/* $I2B2_SRC/ > /dev/null
			rm -r $I2B2_SRC/src > /dev/null
        fi

	    if [ -d "$I2B2_SRC/i2b2core-src-1707" ]; then  
			mv $I2B2_SRC/i2b2core-src-1707/* $I2B2_SRC/ > /dev/null
			rm -r $I2B2_SRC/i2b2core-src-1707 > /dev/null
        fi
		
		if [ ! -d "$I2B2_SRC/edu.harvard.i2b2.crc" ]; then 
			updateBackTitle
			dialog --colors --backtitle "$BACKTITLE" --msgbox "ERROR: $I2B2_SRC/edu.harvard.i2b2.crc not found. Check unzip routine!" 6 60
			exit 1
		fi
				
        # i2b2 demodata:
        progressBar 50 "Expanding i2b2 demo data ..."
        unzip -o $MY_PATH/packages/$FILEDEMODATA -d $I2B2_SRC > /dev/null

	    if [ -d "$I2B2_SRC/i2b2-data-1.7.07" ]; then  
			mv $I2B2_SRC/i2b2-data-1.7.07/* $I2B2_SRC/ > /dev/null
			rm -r $I2B2_SRC/i2b2-data-1.7.07 > /dev/null
        fi
				
		if [ ! -d "$I2B2_SRC/edu.harvard.i2b2.data" ]; then 
			updateBackTitle
			dialog --colors --backtitle "$BACKTITLE" --msgbox "ERROR: $I2B2_SRC/edu.harvard.i2b2.data not found. Check unzip routine!" 6 60
			exit 1
		fi
		
		# Fix bugs in the i2b2 1.7 data:

		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Crcdata/scripts/procedures/oracle/INSERT_EID_MAP_FROMTEMP.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "\"I2B2DEMODATA\".\"INSERT_EID_MAP_FROMTEMP\"" "INSERT_EID_MAP_FROMTEMP";
	
		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Crcdata/scripts/procedures/oracle/UPDATE_OBSERVATION_FACT.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "\"I2B2DEMODATA\".\"UPDATE_OBSERVATION_FACT\"" "UPDATE_OBSERVATION_FACT";

		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Crcdata/scripts/procedures/postgresql/CREATE_TEMP_PROVIDER_TABLE.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "CREATE_TEMP_PROVIDER_TABLE.sql" " ";
	
		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/scripts/work_db_lookup_postgresql_insert_data.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "public" "i2b2workdata";
	
		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/scripts/ont_db_lookup_postgresql_insert_data.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "public" "i2b2metadata";

		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/scripts/im_db_lookup_postgresql_insert_data.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "public" "i2b2imdata";

		FILE=$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/scripts/crc_db_lookup_postgresql_insert_data.sql
		restoreOriginalFile $FILE
		changeInFile $FILE "public" "i2b2demodata";

	# ----

        # i2b2 webclient:
        progressBar 75 "Expanding i2b2 webclient ..."
        unzip -o $MY_PATH/packages/$FILEWEBCLIENT -d $I2B2_SRC > /dev/null

		if [ -d "$I2B2_SRC/i2b2webclient-1707" ]; then  
			mv $I2B2_SRC/i2b2webclient-1707/* $I2B2_SRC/ > /dev/null
			rm -r $I2B2_SRC/i2b2webclient-1707 > /dev/null
        fi
		
		if [ ! -d "$I2B2_SRC/webclient" ]; then 
			updateBackTitle
			dialog --colors --backtitle "$BACKTITLE" --msgbox "ERROR: $I2B2_SRC/webclient not found. Check unzip routine!" 6 60
			exit 1
		fi
		
		# TODO: automatically determine paths of ZIP file:

		#mv $I2B2_SRC/Webclient/* $I2B2_SRC/ > /dev/null
        #rm -r $I2B2_SRC/Webclient > /dev/null
        #mv $I2B2_SRC/src/* $I2B2_SRC/ > /dev/null
        #rm -r $I2B2_SRC/src > /dev/null
		
        # copy the jdbc-jars, we need them later ...
        cp $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/*.jar $MY_PATH/database/

    fi

	getWebserverDirectory
	
    if [ ! -d "$WEBSERVERDIRECTORY" ]; then  
        mkdir $WEBSERVERDIRECTORY/
    fi

    if [ ! -d "$WEBSERVERDIRECTORY/webclient" ]; then  
        cd $I2B2_SRC
        mv webclient $WEBSERVERDIRECTORY/
        mv admin $WEBSERVERDIRECTORY/
    fi

    cd $MY_PATH

}

# ==================================================================================================
# configureWebclient() - configures the i2b2 Webclient and Admin interface
# ==================================================================================================

configureWebclient() {

	getWebserverDirectory
	
	if [ ! -d "$WEBSERVERDIRECTORY/webclient" ]; then 
		autoExpandSource
	fi
	
	if [ "$IP_ADDR" = "" ]; then
		getIP
	fi

	FILE=$WEBSERVERDIRECTORY/webclient/i2b2_config_data.js
	
	if [ ! -f "$FILE.orig" ]; then  
		cp -i $FILE $FILE.orig
	fi

	cat $FILE.orig | sed -e 's/allowAnalysis: false/allowAnalysis: true/g;s/isSHRINE: true/isSHRINE: false/g;s/debug: false/debug: true/g;s/HarvardDemo/'"$HIVE_ID"'/g;s/i2b2demo/'"$HIVE_ID"'/g;s/webservices.i2b2.org/'"$IP_ADDR"':9090/g;s/services.i2b2.org/'"$IP_ADDR"':9090/g;s/rest/services/g' > $FILE
		
	FILE=$WEBSERVERDIRECTORY/admin/i2b2_config_data.js
	
	if [ ! -f "$FILE.orig" ]; then  
		cp -i $FILE $FILE.orig
	fi

	cat $FILE.orig | sed -e 's/HarvardDemo/'"$HIVE_ID"'/g;s/webservices.i2b2.org/'"$IP_ADDR"':9090/g;s/amdinOnly/adminOnly/g' > $FILE

}



# ==================================================================================================
# buildSource() - builds the i2b2 sourcecode
# ==================================================================================================

buildSource() {

    getJBossStatus
    if [ "$JBOSSSTATUS" = "1" ]; then  
        stopJBoss
    fi    

    	autoInstallApps

	checkJavaInstallation

 	autoExpandSource

	configureWebclient
	
	progressBar 0 "Configurating source code ..."

	# setup JBoss data sources:

	cd $MY_PATH

	cat $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/pm-ds.xml | sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g;s/DB_SERVER/'"$DB_SERVER"'/g;s/DB_PORT/'"$DB_PORT"'/g' > $I2B2_SRC/edu.harvard.i2b2.pm/etc/jboss/pm-ds.xml
	cat $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/ont-ds.xml| sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g;s/DB_SERVER/'"$DB_SERVER"'/g;s/DB_PORT/'"$DB_PORT"'/g' >  $I2B2_SRC/edu.harvard.i2b2.ontology/etc/jboss/ont-ds.xml
	cat $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml | sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g;s/DB_SERVER/'"$DB_SERVER"'/g;s/DB_PORT/'"$DB_PORT"'/g' >  $I2B2_SRC/edu.harvard.i2b2.crc/etc/jboss/crc-ds.xml
	#cat $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-jms-ds.xml | sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g' >  $I2B2_SRC/edu.harvard.i2b2.crc/etc/jboss/crc-jms-ds.xml
	cat $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/work-ds.xml | sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g;s/DB_SERVER/'"$DB_SERVER"'/g;s/DB_PORT/'"$DB_PORT"'/g' >  $I2B2_SRC/edu.harvard.i2b2.workplace/etc/jboss/work-ds.xml
	cat $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/im-ds.xml | sed -e 's/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g;s/I2B2HIVEPASS/'"$HIVE_PASS"'/g;s/I2B2HIVESCHEMA/'"$HIVE_SCHEMA"'/g;s/I2B2PMSCHEMA/'"$PM_SCHEMA"'/g;s/I2B2PMPASS/'"$PM_PASS"'/g;s/DB_SERVER/'"$DB_SERVER"'/g;s/DB_PORT/'"$DB_PORT"'/g' >  $I2B2_SRC/edu.harvard.i2b2.im/etc/jboss/im-ds.xml

	# configure working paths:
	echo "edu.harvard.i2b2.im.applicationdir=$IM_APPDIR" > $IM_APPDIR_FILE
	echo "edu.harvard.i2b2.crc.applicationdir=$CRC_APPDIR" > $CRC_APPDIR_FILE
	echo "edu.harvard.i2b2.frapplicationdir=$FR_APPDIR" > $FR_APPDIR_FILE
	echo "edu.harvard.i2b2.ontology.applicationdir=$ONT_APPDIR" > $ONT_APPDIR_FILE
	echo "edu.harvard.i2b2.workplace.applicationdir=$WORK_APPDIR" > $WORK_APPDIR_FILE

	
	# modify files to allow custom PM and HIVE schemas:

	# ---------------- IM: ----------------

	FILE="$I2B2_SRC/edu.harvard.i2b2.im/etc/spring/im.properties"
	if [ ! -f "$FILE.orig" ]; then  
		cp -i $FILE $FILE.orig
	fi    

	if [ $DBTYPE = "MSSQL" ]; then
		sed -e 's/imschema=i2b2hive/imschema=dbo/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Modify I2B2HIVE schema for I2B2IM, MSSQL"
	else
		sed -e 's/imschema=i2b2hive/imschema='"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Modify I2B2HIVE schema for I2B2IM, non-MSSQL"
	fi
	
	# ---------------- CRC: ---------------- 

	#Edit CRCLoaderApplicationContext.xml

	FILE="$I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/CRCLoaderApplicationContext.xml"
	if [ ! -f "$FILE.orig" ]; then  
		cp -i $FILE $FILE.orig
	fi    

	if [ $DBTYPE = "MSSQL" ]; then

		sed -e '58,58s/jdbc:oracle:thin:@127.0.0.1:1521:XE/jdbc:sqlserver:\/\/'"$DB_CONNECTIONSTRING"';DatabaseName=I2B2HIVE/g;57,57s/oracle.jdbc.driver.OracleDriver/com.microsoft.sqlserver.jdbc.SQLServerDriver/g;60,60s/demouser/'"$HIVE_PASS"'/g;59,59s/i2b2hive/'"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Change DB connection, MSSQL"
	fi
	if [ $DBTYPE = "POSTGRESQL" ]; then 

		sed -e '32,32s/jdbc:oracle:thin:@127.0.0.1:1521:XE/jdbc:postgresql:\/\/localhost:5432\/i2b2?searchpath='"$HIVE_SCHEMA"'/g;31,31s/oracle.jdbc.driver.OracleDriver/org.postgresql.Driver/g;34,34s/demouser/'"$HIVE_PASS"'/g;33,33s/i2b2hive/'"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Change DB connection, Postgres"

	else 
		
		sed -e '58,58s/127.0.0.1:1521:XE/'"$DB_CONNECTIONSTRING"'/g;60,60s/demouser/'"$HIVE_PASS"'/g;59,59s/i2b2hive/'"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Change DB connection, non-Postgres, non-MSSQL"	
	fi

	#Edit edu.harvard.i2b2.crc.loader.properties

	FILE="$I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/edu.harvard.i2b2.crc.loader.properties"
	if [ ! -f "$FILE.orig" ]; then  
		cp -i $FILE $FILE.orig
	fi    
	if [ $DBTYPE = "MSSQL" ]; then
		sed -e 's/schemaname=i2b2hive/schemaname=dbo/g;s/edu.harvard.i2b2.crc.loader.ds.lookup.servertype=ORACLE/edu.harvard.i2b2.crc.loader.ds.lookup.servertype=SQLSERVER/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Change servertype setting to SQLSERVER"
	fi
	if [ $DBTYPE = "POSTGRESQL" ]; then
		sed -e 's/schemaname=i2b2hive/schemaname='"$HIVE_SCHEMA"'/g;s/edu.harvard.i2b2.crc.loader.ds.lookup.servertype=ORACLE/edu.harvard.i2b2.crc.loader.ds.lookup.servertype=PostgreSQL/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Change servertype setting to PostgreSQL"

	else
		sed -e 's/schemaname=i2b2hive/schemaname='"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Set schema for I2B2HIVE"
	fi

	#Edit crc.properties

	FILE="$I2B2_SRC/edu.harvard.i2b2.crc/etc/spring/crc.properties"
	if [ ! -f "$FILE.orig" ]; then  
		cp -i $FILE $FILE.orig
	fi    
	if [ $DBTYPE = "MSSQL" ]; then
		sed -e 's/schemaname=i2b2hive/schemaname=dbo/g;s/queryprocessor.ds.lookup.servertype=ORACLE/queryprocessor.ds.lookup.servertype=SQLSERVER/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Change queryprocessor setting to SQLSERVER"
	fi
	if [ $DBTYPE = "POSTGRESQL" ]; then
		sed -e 's/schemaname=i2b2hive/schemaname='"$HIVE_SCHEMA"'/g;s/queryprocessor.ds.lookup.servertype=ORACLE/queryprocessor.ds.lookup.servertype=PostgreSQL/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Change queryprocessor setting to PostgreSQL"

	else
		sed -e 's/schemaname=i2b2hive/schemaname='"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Set schema for I2B2HIVE"
	fi


	# ---------------- ONT: ----------------

	FILE="$I2B2_SRC/edu.harvard.i2b2.ontology/etc/spring/ontology.properties"
	if [ ! -f "$FILE.orig" ]; then  
		cp -i $FILE $FILE.orig
	fi    

	if [ $DBTYPE = "MSSQL" ]; then
		sed -e 's/metadataschema=i2b2hive/metadataschema=dbo/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Set metadataschema to dbo"
	else
		sed -e 's/metadataschema=i2b2hive/metadataschema='"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Set metadataschema I2B2HIVE schema"
	fi
		
    FILE="$I2B2_SRC/edu.harvard.i2b2.ontology/etc/spring/OntologyApplicationContext.xml"
	if [ ! -f "$FILE.orig" ]; then  
		cp -i $FILE $FILE.orig
	fi 

	if [ $DBTYPE = "MSSQL" ]; then   	
		sed -e '23,23s/jdbc:oracle:thin:@localhost:1521:xe/jdbc:sqlserver:\/\/'"$DB_CONNECTIONSTRING"';DatabaseName=I2B2METADATA/g;22,22s/oracle.jdbc.driver.OracleDriver/com.microsoft.sqlserver.jdbc.SQLServerDriver/g;24,24s/metadata_uname/I2B2METADATA/g;25,25s/demouser/i2b2metadata/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Configure database connection, MSSQL"
	fi	

	if [ $DBTYPE = "POSTGRESQL" ]; then   	
		sed -e '23,23s/jdbc:oracle:thin:@localhost:1521:xe/jdbc:postgresql:\/\/localhost\/i2b2?searchpath=i2b2metadata/g;22,22s/oracle.jdbc.driver.OracleDriver/org.postgresql.Driver/g;24,24s/metadata_uname/i2b2metadata/g;25,25s/demouser/i2b2metadata/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Configure database connection, POSTGRESQL"
	fi

	# ---------------- WORK: ----------------
		
	FILE="$I2B2_SRC/edu.harvard.i2b2.workplace/etc/spring/workplace.properties"
	if [ ! -f "$FILE.orig" ]; then  
		cp -i $FILE $FILE.orig
	fi    

	if [ $DBTYPE = "MSSQL" ]; then
		sed -e 's/metadataschema=i2b2hive/metadataschema=dbo/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Configure database connection, POSTGRESQL"
	else
		sed -e 's/metadataschema=i2b2hive/metadataschema='"$HIVE_SCHEMA"'/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "buildSource(): Set metadataschema I2B2HIVE schema"
	fi
	
	# ---------- Deploy edu.harvard.i2b2.server-common: ---------- 

	progressBar 10 "Deploying edu.harvard.i2b2.server-common ..."

	#checkJavaInstallation

	cd $I2B2_SRC/edu.harvard.i2b2.server-common/
	
	$ANT_HOME/bin/ant clean dist deploy jboss_pre_deployment_setup > $MY_PATH/logs/deploy1.log 2> $MY_PATH/logs/deploy1.err.log

	cd $MY_PATH

	errorHandler $LINENO "Deploy edu.harvard.i2b2.server-common" $MY_PATH/logs/deploy1.log $MY_PATH/logs/deploy1.err.log
	
	# ---------- Deploy edu.harvard.i2b2.pm: ---------- 

	progressBar 20 "Deploying edu.harvard.i2b2.pm ..."

	cd $I2B2_SRC/edu.harvard.i2b2.pm/

	#checkJavaInstallation

    	$ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy2.log 2> $MY_PATH/logs/deploy2.err.log
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.pm" $MY_PATH/logs/deploy2.log $MY_PATH/logs/deploy2.err.log
	
	# http://localhost:9090/i2b2/services/listServices
	# should now list: PMService

	# ---------- Deploy edu.harvard.i2b2.ontology: ---------- 

	progressBar 30 "Deploying edu.harvard.i2b2.ontology ..."

	cd $I2B2_SRC/edu.harvard.i2b2.ontology/
	

	#checkJavaInstallation
        
	$ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy3.log 2> $MY_PATH/logs/deploy3.err.log
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.ontology" $MY_PATH/logs/deploy3.log $MY_PATH/logs/deploy3.err.log

	# ---------- Deploy edu.harvard.i2b2.im: ---------- 

	progressBar 45 "Deploying edu.harvard.i2b2.im ..."

	cd $I2B2_SRC/edu.harvard.i2b2.im/

	#checkJavaInstallation
    	
	$ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy4.log 2> $MY_PATH/logs/deploy4.err.log
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.im" $MY_PATH/logs/deploy4.log $MY_PATH/logs/deploy4.err.log

	# ---------- Deploy edu.harvard.i2b2.crc: ---------- 

	progressBar 60 "Deploying edu.harvard.i2b2.crc ..."

	cd $MY_PATH

	cd $I2B2_SRC/edu.harvard.i2b2.crc/

	#checkJavaInstallation

    $ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy5.log 2> $MY_PATH/logs/deploy5.err.log
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.crc" $MY_PATH/logs/deploy5.log $MY_PATH/logs/deploy5.err.log

	# ---------- Deploy edu.harvard.i2b2.workplace: ---------- 

	progressBar 80 "Deploying edu.harvard.i2b2.workplace ..."

	cd $I2B2_SRC/edu.harvard.i2b2.workplace/
	
	#checkJavaInstallation
    	
	$ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy6.log 2> $MY_PATH/logs/deploy6.err.log
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.workplace" $MY_PATH/logs/deploy6.log $MY_PATH/logs/deploy6.err.log

	# ---------- Deploy edu.harvard.i2b2.fr: ---------- 

	progressBar 90 "Deploying edu.harvard.i2b2.fr ..."

	cd $I2B2_SRC/edu.harvard.i2b2.fr/
	
	#checkJavaInstallation
    	
	$ANT_HOME/bin/ant -f master_build.xml clean build-all deploy > $MY_PATH/logs/deploy7.log 2> $MY_PATH/logs/deploy7.err.log
	
	cd $MY_PATH

	errorHandler $LINENO "Deployment of edu.harvard.i2b2.fr" $MY_PATH/logs/deploy7.log $MY_PATH/logs/deploy7.err.log

	# ---------- Set owner of the JBoss directory: ----------

	setFilePermissions
	
	progressBar 100 "Done!"

	sleep 2

	CONFIG_DIRTY=no
    setFilePermissions
	saveValues
}


# ==================================================================================================
# loadBoston() - loads the Boston Demodata
# ==================================================================================================

# Parameter: silent (if silent = 1, do not show that Boston Demodata is already loaded)

loadBoston() {

    cd $MY_PATH
 
    EXISTSBOSTON=`cat config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml | grep '<!--BOSTONSTART-->'`

    if ([ ! "$EXISTSBOSTON" = "" ] && [ ! "$1" = "1" ] ); then
		   updateBackTitle
           dialog --colors --backtitle "$BACKTITLE" --msgbox "Boston Demodata appears to be already loaded!" 6 60
    fi

	if [ ! "$EXISTSBOSTON" = "" ]; then
           return
    fi
	
    autoInstallApps
	
    # --------- Add Boston Demodata Datasources from config/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/: ---------

    mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml $MY_PATH/config/crc-ds.old
    mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/ont-ds.xml $MY_PATH/config/ont-ds.old
    mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/work-ds.xml $MY_PATH/config/work-ds.old
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/im-ds.xml $MY_PATH/config/im-ds.old

    cat $MY_PATH/config/crc-ds.old | sed -e '/<!--WIZARDINSERT-->/r '"$MY_PATH"'/config/ds-config/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/boston-crc-ds.ins' > $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml
    cat $MY_PATH/config/ont-ds.old | sed -e '/<!--WIZARDINSERT-->/r '"$MY_PATH"'/config/ds-config/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/boston-ont-ds.ins' > $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/ont-ds.xml
    cat $MY_PATH/config/work-ds.old | sed -e '/<!--WIZARDINSERT-->/r '"$MY_PATH"'/config/ds-config/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/boston-work-ds.ins' > $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/work-ds.xml
	cat $MY_PATH/config/im-ds.old | sed -e '/<!--WIZARDINSERT-->/r '"$MY_PATH"'/config/ds-config/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/boston-im-ds.ins' > $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/im-ds.xml

    rm $MY_PATH/config/crc-ds.old
    rm $MY_PATH/config/ont-ds.old
    rm $MY_PATH/config/work-ds.old
	rm $MY_PATH/config/im-ds.old

    stopJBoss
    autoInstallApps
    loadHive
    registerHive

	# --------- Create users for project "Demo" ---------
	progressBar 5 "Creating schema I2B2DEMODATA ..."

	# Create user I2B2DEMODATA
	
	cd "$MY_PATH/database/"
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $DB_SYSUSER $DB_SYSPASS
	
	FILE=$MY_PATH/database/scripts/create_"$DBTYPE"_users_single.sql
  
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"I2B2DEMODATA"'/g;s/I2B2DB_PWD/'"i2b2demodata"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (1)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1A.err.log > $MY_PATH/logs/loadhive1A.log
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1A.log $MY_PATH/logs/loadhive1A.err.log
	
	progressBar 7 "Creating schema I2B2METADATA ..."

	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi

	rm $FILE
	mv $FILE.orig $FILE

	# ---
	
	# Create user I2B2METADATA
	
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"I2B2METADATA"'/g;s/I2B2DB_PWD/'"i2b2metadata"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (2)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1A.err.log > $MY_PATH/logs/loadhive1A.log
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1A.log $MY_PATH/logs/loadhive1A.err.log

	progressBar 9 "Enabling full text indexing ..."

	
	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi

	progressBar 11 "Creating schema I2B2WORKDATA ..."
	
	rm $FILE
	mv $FILE.orig $FILE

	# ---
	# Create user I2B2WORKDATA
	
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"I2B2WORKDATA"'/g;s/I2B2DB_PWD/'"i2b2workdata"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (3)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1A.err.log > $MY_PATH/logs/loadhive1A.log
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1A.log $MY_PATH/logs/loadhive1A.err.log

	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi

	progressBar 13 "Creating schema IMDATA ..."

	
	rm $FILE
	mv $FILE.orig $FILE

	# Creating User IMDATA
	
	FILE=$MY_PATH/database/scripts/create_"$DBTYPE"_users_single.sql
 
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"I2B2IMDATA"'/g;s/I2B2DB_PWD/'"i2b2imdata"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (4)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	#checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1A.err.log > $MY_PATH/logs/loadhive1A.log
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1A.log $MY_PATH/logs/loadhive1A.err.log

	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi
	
	rm $FILE
	mv $FILE.orig $FILE


	# --------- Load "Metadata" ---------
	progressBar 15 "Loading Metadata (takes very long, progressbar may look stuck) ..."

	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Metadata/ 

	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Metadata/"
	createDBProperties $DIR i2b2metadata i2b2metadata "$DB_SERVER:$DB_PORT:$ORA_SSID" "db.project=demo"
	#echo "db.project=demo" >> $DIRdb.properties

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_metadata_tables_release_$I2B2RELEASE > $MY_PATH/logs/bostonload2.log 2> $MY_PATH/logs/bostonload2.err.log
	#Ignore any error here:
	errorHandler $LINENO "create_metadata_tables_release_$I2B2RELEASE" $MY_PATH/logs/bostonload2.log $MY_PATH/logs/bostonload2.err.log
	
	progressBar 20 "Loading Metadata (takes very long, progressbar may look stuck) ..."
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml db_metadata_load_data > $MY_PATH/logs/bostonload3.log 2> $MY_PATH/logs/bostonload3.err.log
	#Ignore any error here:
	errorHandler $LINENO "db_metadata_load_data" $MY_PATH/logs/bostonload3.log $MY_PATH/logs/bostonload3.err.log

	# --------- Load "Crcdata" ---------
	progressBar 45 "Loading Crcdata (takes very long, progressbar may look stuck) ..."
	
	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Crcdata/

	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Crcdata/"

	createDBProperties $DIR i2b2demodata i2b2demodata "$DB_SERVER:$DB_PORT:$ORA_SSID" "db.project=demo"

	#echo "db.project=demo" >> $DIRdb.properties
  
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_crcdata_tables_release_$I2B2RELEASE > $MY_PATH/logs/bostonload4.log 2> $MY_PATH/logs/bostonload4.err.log
	errorHandler $LINENO "create_crcdata_tables_release_$I2B2RELEASE" $MY_PATH/logs/bostonload4.log $MY_PATH/logs/bostonload4.err.log
	
	progressBar 50 "Loading Crcdata (takes very long, progressbar may look stuck) ..."
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_procedures_release_$I2B2RELEASE > $MY_PATH/logs/bostonload5.log 2> $MY_PATH/logs/bostonload5.err.log
	errorHandler $LINENO "create_procedures_release_$I2B2RELEASE" $MY_PATH/logs/bostonload5.log $MY_PATH/logs/bostonload5.err.log

	progressBar 55 "Loading Crcdata (takes very long, progressbar may look stuck) ..."
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml db_demodata_load_data > $MY_PATH/logs/bostonload6.log 2> $MY_PATH/logs/bostonload6.err.log
	errorHandler $LINENO "db_demodata_load_data" $MY_PATH/logs/bostonload6.log $MY_PATH/logs/bostonload6.err.log

	# --------- Load "Workdata" ---------
	progressBar 80 "Loading Workdata ..."


	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Workdata/

	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Workdata/"
	createDBProperties $DIR i2b2workdata i2b2workdata "$DB_SERVER:$DB_PORT:$ORA_SSID" "db.project=demo"
	#echo "db.project=demo" >> $DIRdb.properties

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_workdata_tables_release_$I2B2RELEASE > $MY_PATH/logs/bostonload7.log 2> $MY_PATH/logs/bostonload7.err.log
	errorHandler $LINENO "create_workdata_tables_release_$I2B2RELEASE" $MY_PATH/logs/bostonload7.log $MY_PATH/logs/bostonload7.err.log
	
	progressBar 85 "Loading Workdata ..."

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml db_workdata_load_data > $MY_PATH/logs/bostonload8.log 2> $MY_PATH/logs/bostonload8.err.log
	errorHandler $LINENO "db_workdata_load_data" $MY_PATH/logs/bostonload8.log $MY_PATH/logs/bostonload8.err.log

	# --------- Load "Imdata" ---------
	progressBar 90 "Loading Imdata ..."

	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Imdata/

	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Imdata/"
	createDBProperties $DIR i2b2imdata i2b2imdata "$DB_SERVER:$DB_PORT:$ORA_SSID" "db.project=demo"
	
	$ANT_HOME/bin/ant -f data_build.xml create_imdata_tables_release_$I2B2RELEASE > $MY_PATH/logs/bostonload9.log 2> $MY_PATH/logs/bostonload9.err.log
	errorHandler $LINENO "create_imdata_tables_release_$I2B2RELEASE" $MY_PATH/logs/bostonload9.log $MY_PATH/logs/bostonload9.err.log
	
	progressBar 95 "Loading Imdata ..."

    $ANT_HOME/bin/ant -f data_build.xml db_imdata_load_data > $MY_PATH/logs/bostonload10.log 2> $MY_PATH/logs/bostonload10.err.log
	errorHandler $LINENO "db_imdata_load_data" $MY_PATH/logs/bostonload10.log $MY_PATH/logs/bostonload10.err.log
	
	progressBar 95 "Loading Imdata ..."
	
	# Append the user name to the list-file:		
	touch $MY_PATH/config/userlist.dat
	echo "i2b2#i2b2#demouser#" >> $MY_PATH/config/userlist.dat
	echo "demo#demo#demouser#" >> $MY_PATH/config/userlist.dat
	
	# Append the project name to the list-file:		
	touch $MY_PATH/config/projectlist.dat
	echo "Demo#I2B2METADATA;I2B2DEMODATA;I2B2WORKDATA;I2B2IMDATA#I2B2METADATA;I2B2DEMODATA;I2B2WORKDATA;I2B2IMDATA#" >> $MY_PATH/config/projectlist.dat

	progressBar 100 "Done!"
	sleep 2
    
	
	removeBostonRelated
    loadBostonRelated
	registerHive
    
        LAST_PROJECT=Demo	
	CONFIG_DIRTY=yes
	saveValues
}

# ==================================================================================================
# dropBoston() - removes the Boston Demodata
# ==================================================================================================

dropBoston() {

    EXISTSBOSTON=`cat config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml | grep '<!--BOSTONSTART-->'`

    if [ "$EXISTSBOSTON" = "" ]; then
		updateBackTitle
        dialog --colors --backtitle "$BACKTITLE" --msgbox "ERROR: Boston Demodata appears not to be loaded!" 6 60
        return
    fi

    stopJBoss	

	progressBar 0 "Removing I2B2DEMODATA ..."
	dropDatabaseUser I2B2DEMODATA
	progressBar 20 "Removing I2B2METADATA ..."
	dropDatabaseUser I2B2METADATA
	progressBar 40 "Removing I2B2WORKDATA ..."
	dropDatabaseUser I2B2WORKDATA
	progressBar 60 "Removing I2B2IMDATA ..."
	dropDatabaseUser I2B2IMDATA
	progressBar 80 "Unregistering Demo project ..."
	
	# --------- Remove Boston Demodata Datasources: ---------

	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml $MY_PATH/config/crc-ds.old
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/ont-ds.xml $MY_PATH/config/ont-ds.old
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/work-ds.xml $MY_PATH/config/work-ds.old
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/im-ds.xml $MY_PATH/config/im-ds.old

	# see: http://ilfilosofo.com/blog/2008/04/26/sed-multi-line-search-and-replace

	sed -n '1h;1!H;${;g;s/<!--BOSTONSTART-->.*<!--BOSTONEND-->//g;p;}' <$MY_PATH/config/crc-ds.old >$MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml
	sed -n '1h;1!H;${;g;s/<!--BOSTONSTART-->.*<!--BOSTONEND-->//g;p;}' <$MY_PATH/config/ont-ds.old >$MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/ont-ds.xml
	sed -n '1h;1!H;${;g;s/<!--BOSTONSTART-->.*<!--BOSTONEND-->//g;p;}' <$MY_PATH/config/work-ds.old >$MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/work-ds.xml
	sed -n '1h;1!H;${;g;s/<!--BOSTONSTART-->.*<!--BOSTONEND-->//g;p;}' <$MY_PATH/config/im-ds.old >$MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/im-ds.xml

	rm $MY_PATH/config/crc-ds.old
	rm $MY_PATH/config/ont-ds.old
	rm $MY_PATH/config/work-ds.old
	rm $MY_PATH/config/im-ds.old
	
	mv $MY_PATH/config/projectlist.dat $MY_PATH/config/projectlist_old.dat 
	cat $MY_PATH/config/projectlist_old.dat  | grep -v "I2B2METADATA" >> $MY_PATH/config/projectlist.dat 
	rm $MY_PATH/config/projectlist_old.dat 

	mv $MY_PATH/config/userlist.dat $MY_PATH/config/userlist_old.dat 
	cat $MY_PATH/config/userlist_old.dat  | grep -v "#demo#" >> $MY_PATH/config/userlist.dat 
	rm $MY_PATH/config/userlist_old.dat 

	mv $MY_PATH/config/userlist.dat $MY_PATH/config/userlist_old.dat 
	cat $MY_PATH/config/userlist_old.dat  | grep -v "#i2b2#" >> $MY_PATH/config/userlist.dat 
	rm $MY_PATH/config/userlist_old.dat 

	progressBar 100 "Boston Demo Data dropped!"
	sleep 2

	#errorHandler $LINENO "Drop Boston Demodata" $MY_PATH/logs/bostondrop.log $MY_PATH/logs/bostondrop.err.log

    removeBostonRelated
	CONFIG_DIRTY=yes
	saveValues
	
}


# ==================================================================================================
# registerCells() - updates the IP of the Cells in $HIVE_SCHEMA 
# ==================================================================================================

registerCells() {
	
	getIP
    
	progressBar 0 "Registering i2b2 hive cells ..."
	
	cd "$MY_PATH/database/"
	
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $PM_SCHEMA $PM_PASS

	echo "TRUNCATE TABLE PM_CELL_DATA;" > "$MY_PATH/database/scripts/database_job.sql"
	echo "Insert into PM_CELL_DATA (CELL_ID,PROJECT_PATH,NAME,METHOD_CD,URL,CAN_OVERRIDE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('CRC','/','Data Repository','REST','http://$IP_ADDR:9090/i2b2/services/QueryToolService/',1,null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "Insert into PM_CELL_DATA (CELL_ID,PROJECT_PATH,NAME,METHOD_CD,URL,CAN_OVERRIDE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('FRC','/','File Repository ','SOAP','http://$IP_ADDR:9090/i2b2/services/FRService/',1,null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "Insert into PM_CELL_DATA (CELL_ID,PROJECT_PATH,NAME,METHOD_CD,URL,CAN_OVERRIDE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('ONT','/','Ontology Cell','REST','http://$IP_ADDR:9090/i2b2/services/OntologyService/',1,null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "Insert into PM_CELL_DATA (CELL_ID,PROJECT_PATH,NAME,METHOD_CD,URL,CAN_OVERRIDE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('WORK','/','Workplace Cell','REST','http://$IP_ADDR:9090/i2b2/services/WorkplaceService/',1,null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "Insert into PM_CELL_DATA (CELL_ID,PROJECT_PATH,NAME,METHOD_CD,URL,CAN_OVERRIDE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('IM','/','Identity Management Cell','REST','http://$IP_ADDR:9090/i2b2/services/IMService/',1,null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job 2> $MY_PATH/logs/registercells.err.log > $MY_PATH/logs/registercells.log
	rm $MY_PATH/database/scripts/database_job.sql

	configureWebclient
		
	progressBar 100 "i2b2 hive cells registered!"
	sleep 2

    errorHandler $LINENO "Register i2b2 hive cells in $PM_SCHEMA.PM_CELL_DATA" $MY_PATH/logs/registercells.log $MY_PATH/logs/registercells.err.log
}

# ==================================================================================================
# registerHive() - updates the HIVE_ID in $PM_SCHEMA and $HIVE_SCHEMA 
# ==================================================================================================

registerHive() {
	
    stopJBoss

	# --------- Registering Hive ID: --------- 

	progressBar 0 "Registering Hive ID in $PM_SCHEMA ..."
	cd "$MY_PATH/database/"
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $PM_SCHEMA $PM_PASS
	echo "TRUNCATE TABLE PM_HIVE_DATA;" > "$MY_PATH/database/scripts/database_job.sql"
	echo "Insert into PM_HIVE_DATA (DOMAIN_ID,HELPURL,DOMAIN_NAME,ENVIRONMENT_CD,ACTIVE,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('i2b2','http://www.i2b2.org','$HIVE_ID','DEVELOPMENT',1,null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job 2> $MY_PATH/logs/registerhive1.err.log > $MY_PATH/logs/registerhive1.log
	rm $MY_PATH/database/scripts/database_job.sql

    errorHandler $LINENO "Register Hive ID in I2B2PM" $MY_PATH/logs/registerhive1.log $MY_PATH/logs/registerhive1.err.log

	progressBar 50 "Registering Hive ID in $HIVE_SCHEMA ..."
	cd "$MY_PATH/database/"
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $HIVE_SCHEMA $HIVE_PASS
	echo "UPDATE WORK_DB_LOOKUP SET C_DOMAIN_ID = '$HIVE_ID';" > "$MY_PATH/database/scripts/database_job.sql"
	echo "UPDATE CRC_DB_LOOKUP SET C_DOMAIN_ID = '$HIVE_ID';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "UPDATE ONT_DB_LOOKUP SET C_DOMAIN_ID = '$HIVE_ID';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "UPDATE IM_DB_LOOKUP SET C_DOMAIN_ID = '$HIVE_ID';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job 2> $MY_PATH/logs/registerhive2.err.log > $MY_PATH/logs/registerhive2.log
	rm $MY_PATH/database/scripts/database_job.sql

	configureWebclient
	
	progressBar 100 "Hive registered!"
	sleep 2
 
    errorHandler $LINENO "Register Hive ID in $HIVE_SCHEMA " $MY_PATH/logs/registerhive2.log $MY_PATH/logs/registerhive2.err.log

}


# ==================================================================================================
# removeBostonRelated() - Removes entries in $HIVE_SCHEMA and $PM_SCHEMA related to Boston Demodata
# ==================================================================================================

removeBostonRelated() {

	# --------- Remove all entries related to Demo (Boston Demodata) in $HIVE_SCHEMA and $PM_SCHEMA: --------- 

	progressBar 0 "Removing entries in $HIVE_SCHEMA related to Boston Demodata ..."

	cd "$MY_PATH/database/"

	DIR="$MY_PATH/database/"
	createDBProperties $DIR $HIVE_SCHEMA $HIVE_PASS

	echo "DELETE FROM CRC_DB_LOOKUP WHERE C_PROJECT_PATH = '/Demo/';" > "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM CRC_DB_LOOKUP WHERE C_PROJECT_PATH = '/Demo2/';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM ONT_DB_LOOKUP WHERE C_PROJECT_PATH = 'Demo/';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM ONT_DB_LOOKUP WHERE C_PROJECT_PATH = 'Demo2/';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM WORK_DB_LOOKUP WHERE C_PROJECT_PATH = 'Demo/';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM WORK_DB_LOOKUP WHERE C_PROJECT_PATH = 'Demo2/';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM IM_DB_LOOKUP WHERE C_PROJECT_PATH = 'Demo/';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM IM_DB_LOOKUP WHERE C_PROJECT_PATH = 'Demo2/';" >> "$MY_PATH/database/scripts/database_job.sql"

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job 2> $MY_PATH/logs/remove_boston_related1.err.log > $MY_PATH/logs/remove_boston_related1.log
	
	errorHandler $LINENO "remove_boston_related 1" $MY_PATH/logs/remove_boston_related1.log $MY_PATH/logs/remove_boston_related1.err.log
	
	rm $MY_PATH/database/scripts/database_job.sql

	progressBar 50 "Removing entries in $PM_SCHEMA related to Boston Demodata ..."

	DIR="$MY_PATH/database/"
	createDBProperties $DIR $PM_SCHEMA $PM_PASS

	echo "DELETE FROM PM_HIVE_DATA WHERE DOMAIN_NAME = 'i2b2demo';" > "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM PM_PROJECT_DATA WHERE PROJECT_ID = 'Demo';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM PM_PROJECT_DATA WHERE PROJECT_ID = 'Demo2';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM PM_PROJECT_USER_ROLES WHERE PROJECT_ID = 'Demo';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM PM_PROJECT_USER_ROLES WHERE PROJECT_ID = 'Demo2';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM PM_USER_DATA WHERE USER_ID = 'demo';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM PM_USER_DATA WHERE USER_ID = 'i2b2';" >> "$MY_PATH/database/scripts/database_job.sql"

	echo "TRUNCATE TABLE PM_CELL_DATA;" >> "$MY_PATH/database/scripts/database_job.sql"

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job 2> $MY_PATH/logs/remove_boston_related2.err.log > $MY_PATH/logs/remove_boston_related2.log
	
	errorHandler $LINENO "remove_boston_related 2" $MY_PATH/logs/remove_boston_related2.log $MY_PATH/logs/remove_boston_related2.err.log
	
	rm $MY_PATH/database/scripts/database_job.sql

	progressBar 100 "Entries related to Boston Demodata removed!"
	sleep 2
	
	CONFIG_DIRTY=yes
	saveValues
	
}



# ==================================================================================================
# loadBostonRelated() - Inserts entries in $HIVE_SCHEMA and $PM_SCHEMA related to Boston Demodata
# ==================================================================================================

loadBostonRelated() {

	# --------- Insert all entries related to Demo (Boston Demodata) in $HIVE_SCHEMA : --------- 

	progressBar 0 "Inserting entries in $PM_SCHEMA related to Boston Demodata ..."
	
	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Pmdata/
	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Pmdata/"
	createDBProperties $DIR $PM_SCHEMA $PM_PASS

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml db_pmdata_load_data 2> $MY_PATH/logs/db_pmdata_load_data.err.log > $MY_PATH/logs/db_pmdata_load_data.log

	errorHandler $LINENO "db_pmdata_load_data" $MY_PATH/logs/db_pmdata_load_data.log $MY_PATH/logs/db_pmdata_load_data.err.log
	
	progressBar 50 "Inserting entries in $HIVE_SCHEMA related to Boston Demodata ..."
	
	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/
	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/"
	createDBProperties $DIR $HIVE_SCHEMA $HIVE_PASS

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml db_hivedata_load_data 2> $MY_PATH/logs/db_hivedata_load_data.err.log > $MY_PATH/logs/db_hivedata_load_data.log

	errorHandler $LINENO "db_hivedata_load_data" $MY_PATH/logs/db_hivedata_load_data.log $MY_PATH/logs/db_hivedata_load_data.err.log
	
	#cd "$MY_PATH/database/"
	#DIR="$MY_PATH/database/"
	#createDBProperties $DIR $HIVE_SCHEMA $HIVE_PASS
	#checkJavaInstallation
    #$ANT_HOME/bin/ant -f data_build.xml insert_boston_related_hive 2>> $MY_PATH/logs/insert_boston_related_hive.err.log >> #$MY_PATH/logs/insert_boston_related_hive.log
	#	errorHandler $LINENO "insert_boston_related_hive" $MY_PATH/logs/insert_boston_related_hive.log $MY_PATH/logs/insert_boston_related_hive.err.log
	#progressBar 50 "Inserting entries in $PM_SCHEMA related to Boston Demodata ..."
	#DIR="$MY_PATH/database/"
	#createDBProperties $DIR $PM_SCHEMA $PM_PASS
	#checkJavaInstallation
    #$ANT_HOME/bin/ant -f data_build.xml insert_boston_related_pm 2>> $MY_PATH/logs/insert_boston_related_pm.err.log >> $MY_PATH/logs/insert_boston_related_pm.log
	#errorHandler $LINENO "insert_boston_related_pm" $MY_PATH/logs/insert_boston_related_pm.log $MY_PATH/logs/insert_boston_related_pm.err.log
	
	progressBar 100 "Entries related to Boston Demodata loaded!"
	sleep 2
	CONFIG_DIRTY=yes
}


# ==================================================================================================
# loadHive() - loads the schemata $PM_SCHEMA and $HIVE_SCHEMA
# ==================================================================================================

loadHive() {

    if [ "$PM_HIVE_LOADED" = "yes" ]; then
        return;
    fi

    stopJBoss
    autoInstallApps

	# ---------- Expand Source Code: ---------- 
	progressBar 0 "Expanding i2b2 source code ..."
	
	autoExpandSource
	
	
	# --------- Create users $HIVE_SCHEMA and $PM_SCHEMA---------
	
	# Creating User $PM_SCHEMA
	progressBar 10 "Creating User $PM_SCHEMA ..."
	
	FILE=$MY_PATH/database/scripts/create_"$DBTYPE"_users_single.sql
  
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"$PM_SCHEMA"'/g;s/I2B2DB_PWD/'"$PM_PASS"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (5)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1A.err.log > $MY_PATH/logs/loadhive1A.log
	rm $FILE
	mv $FILE.orig $FILE
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1A.log $MY_PATH/logs/loadhive1A.err.log

    	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi

	
	# Creating User $HIVE_SCHEMA
	progressBar 15 "Creating User $HIVE_SCHEMA ..."
	
	FILE=$MY_PATH/database/scripts/create_"$DBTYPE"_users_single.sql
 
	if [ ! -f "$FILE.orig" ]; then  
	   cp -i $FILE $FILE.orig
	fi

	sed -e 's/I2B2DB_USR/'"$HIVE_SCHEMA"'/g;s/I2B2DB_PWD/'"$HIVE_PASS"'/g;' <$FILE.orig >$FILE 
	checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (6)"

	DIR2="$MY_PATH/database/"
	createDBProperties $DIR2 $DB_SYSUSER $DB_SYSPASS

	cd $MY_PATH/database

	checkJavaInstallation
	$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single 2> $MY_PATH/logs/loadhive1B.err.log > $MY_PATH/logs/loadhive1B.log
	errorHandler $LINENO create_"$DBTYPE"_users_single $MY_PATH/logs/loadhive1B.log $MY_PATH/logs/loadhive1B.err.log

	if [ $DBTYPE = "MSSQL" ]; then  
		$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
		errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
	fi
	
	rm $FILE
	mv $FILE.orig $FILE
	

	testDBConnectivity $DB_SYSUSER $DB_SYSPASS
	testDBConnectivity $HIVE_SCHEMA $HIVE_PASS
	testDBConnectivity $PM_SCHEMA $PM_PASS

	
	# --------- Load "Hivedata" ---------
	progressBar 20 "Loading Hivedata ..."

	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/

	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Hivedata/"
	createDBProperties $DIR $HIVE_SCHEMA $HIVE_PASS

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_hivedata_tables_release_$I2B2RELEASE 2> $MY_PATH/logs/loadhive2.err.log > $MY_PATH/logs/loadhive2.log
	errorHandler $LINENO "create_hivedata_tables_release_$I2B2RELEASE" $MY_PATH/logs/loadhive2.log $MY_PATH/logs/loadhive2.err.log
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml db_hivedata_load_data 2> $MY_PATH/logs/loadhive3.err.log > $MY_PATH/logs/loadhive3.log
	errorHandler $LINENO "db_hivedata_load_data" $MY_PATH/logs/loadhive3.log $MY_PATH/logs/loadhive3.err.log
	
	
	# --------- Load "Pmdata" ---------
	progressBar 40 "Loading Pmdata ..."

	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Pmdata/

	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Pmdata/"
	createDBProperties $DIR $PM_SCHEMA $PM_PASS

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_pmdata_tables_release_$I2B2RELEASE > $MY_PATH/logs/loadhive4.err.log > $MY_PATH/logs/loadhive4.log
	errorHandler $LINENO "create_pmdata_tables_release_$I2B2RELEASE" $MY_PATH/logs/loadhive4.log $MY_PATH/logs/loadhive4.err.log
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_triggers_release_$I2B2RELEASE 2> $MY_PATH/logs/loadhive5.err.log > $MY_PATH/logs/loadhive5.log
	errorHandler $LINENO "create_triggers_release_$I2B2RELEASE" $MY_PATH/logs/loadhive5.log $MY_PATH/logs/loadhive5.err.log
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml db_pmdata_load_data 2> $MY_PATH/logs/loadhive6.err.log > $MY_PATH/logs/loadhive6.log
	errorHandler $LINENO "db_pmdata_load_data" $MY_PATH/logs/loadhive6.log $MY_PATH/logs/loadhive6.err.log


    # --------- Register Cells and Hive ID: --------- 
    
    removeBostonRelated
    registerCells
    registerHive
	
    CONFIG_DIRTY=yes
    PM_HIVE_LOADED=yes
	
	saveValues
}


# ==================================================================================================
# dropHive() - removes the schemata $PM_SCHEMA and $HIVE_SCHEMA 
# ==================================================================================================

dropHive() {

	updateBackTitle
	
    dialog --colors --backtitle "$BACKTITLE" --title " Drop $PM_SCHEMA and $HIVE_SCHEMA"\
           --yesno "This is a very, very bad idea, because it will render you installation unusable. Really proceed?" 6 70 
    SURE=${?}
    if [ $SURE = 1 ]; then  
        return;
    fi

    dialog --colors --backtitle "$BACKTITLE" --title " Drop $PM_SCHEMA and $HIVE_SCHEMA "\
           --yesno "Are you REALLY sure?" 5 50 
    SURE=${?}
    if [ $SURE = 1 ]; then  
        return;
    fi

    stopJBoss

	progressBar 0 "Dropping $HIVE_SCHEMA and $PM_SCHEMA ..."

	dropDatabaseUser $HIVE_SCHEMA
	dropDatabaseUser $PM_SCHEMA
	
	progressBar 100 "$HIVE_SCHEMA and $PM_SCHEMA dropped!"
	sleep 2

	#errorHandler $LINENO "Remove $PM_SCHEMA and $HIVE_SCHEMA" $MY_PATH/logs/hivedrop.log $MY_PATH/logs/hivedrop.err.log

    CONFIG_DIRTY=yes
    PM_HIVE_LOADED=no
	
	saveValues
}   


# ==================================================================================================
# createProject() - creates a new i2b2 project
# ==================================================================================================

createProject() {
   		
	if [ "$SILENT" = "1" ]; then  

		PROJ_NAME="My Project"
		DB_PASS="mypassword"
		DB_CREATE="yes"
	
	else
		updateBackTitle
		
		dialog --colors --backtitle "$BACKTITLE"  --title " New i2b2 Project "\
			--form "Use [up] [down] to select input field, [tab] to select buttons " 15 70 8 \
			"Project Name:" 2 4 "My Project" 2 33 25 0\
			"Database Password:" 3 4 "mypassword" 3 33 25 0\
			"Auto create DB User?" 5 4 "$DB_ALLOW" 5 33 4 0\
			"Import Boston Demodata?" 6 4 "no" 6 33 4 0\
            "Use CHAR semantics?" 7 4 "yes" 7 33 4 0\
			2>$TEMPVAR
			
		if [ ${?} -ne 0 ]; then return; fi   

		PROJ_NAME=`sed -n 1p $TEMPVAR`
		DB_PASS=`sed -n 2p $TEMPVAR`
		DB_CREATE=`sed -n 3p $TEMPVAR`
		IMPORT_BOSTON=`sed -n 4p $TEMPVAR`
		CHAR_SEMANTICS=`sed -n 5p $TEMPVAR`
	fi

    TMP_ORA_STRING="$DB_SERVER:$DB_PORT:$ORA_SSID"
	
    LAST_PROJECT="$PROJ_NAME"
	saveValues
	
	PROJ_NAME_NOSPACES=`echo $PROJ_NAME | sed -e "s/ //g"`
	
	DB_SYSPASS=$DB_SYSPASS
    DB_SYSUSER=$DB_SYSUSER
   
    DB_USER="$DB_SCHEMAPREFIX"`echo $PROJ_NAME | sed -e "s/ //g;y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/"`

	#Command to convert an upper-case string to lower-case (required for postgres):
	DB_USER=`echo ${DB_USER,,}`
	
	autoInstallApps
	
	if [ "$IMPORT_BOSTON" = "yes" ]; then
		loadBoston 1
    fi
	
    cd $MY_PATH

    EXISTSPROJECT=`cat $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml | grep '<!--'"$PROJ_NAME"'START-->'`
    if [ ! "$EXISTSPROJECT" = "" ]; then
		updateBackTitle
        dialog --colors --backtitle "$BACKTITLE" --msgbox "ERROR: A project with this name seems to already exist (1) - aborting!" 6 75
        return
    fi
    EXISTSPROJECT=`cat $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml | grep "<user-name>$DB_USER</user-name>"`
    if [ ! "$EXISTSPROJECT" = "" ]; then
		updateBackTitle
        dialog --colors --backtitle "$BACKTITLE" --msgbox "ERROR: A project with this name seems to already exist (2) - aborting!" 6 75
        return
    fi
	
	if [ "$DB_USER" = "I2B2DEMO" ]; then
		updateBackTitle
        dialog --colors --backtitle "$BACKTITLE" --msgbox "ERROR: The project name 'Demo' is reserved for the Boston Demodata - aborting!" 6 75
        return
    fi

    stopJBoss
    autoInstallApps
    loadHive
	
	testDBConnectivity $DB_SYSUSER $DB_SYSPASS
	testDBConnectivity $HIVE_SCHEMA $HIVE_PASS
	testDBConnectivity $PM_SCHEMA $PM_PASS
	
	I2B2DB_USR=$DB_USER
	I2B2DB_PWD=$DB_PASS

	if [ "$DB_CREATE" = "yes" ]; then

		# --------- Create user for project ---------
		progressBar 0 "Creating schema $DB_USER ..."
		DIR="$MY_PATH/database/"
		createDBProperties $DIR $DB_SYSUSER $DB_SYSPASS
		#cd $MY_PATH

  
		FILE="$MY_PATH/database/scripts/create_"$DBTYPE"_users_single.sql"
  
		if [ ! -f "$FILE.orig" ]; then  
			cp -i $FILE $FILE.orig
		fi

		sed -e 's/I2B2DB_USR/'"$I2B2DB_USR"'/g;s/I2B2DB_PWD/'"$I2B2DB_PWD"'/g;' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "loadBoston(): modify create_$DBTYPE_users_single.sql (6)"

		cd $MY_PATH/database
		checkJavaInstallation
  		$ANT_HOME/bin/ant -f data_build.xml create_"$DBTYPE"_users_single > $MY_PATH/logs/createproject1.log 2> $MY_PATH/logs/createproject1.err.log
		
		errorHandler $LINENO "Create project" $MY_PATH/logs/createproject1.log $MY_PATH/logs/createproject1.err.log
		
		if [ $DBTYPE = "MSSQL" ]; then  
			$ANT_HOME/bin/ant -f data_build.xml MSSQL_enable_fulltext 2> $MY_PATH/logs/loadhive1C.err.log > $MY_PATH/logs/loadhive1C.log
			errorHandler $LINENO MSSQL_enable_fulltext $MY_PATH/logs/loadhive1C.log $MY_PATH/logs/loadhive1C.err.log
		fi
		
		rm $FILE
		mv $FILE.orig $FILE
		
		testDBConnectivity $I2B2DB_USR $I2B2DB_PWD
    fi

	# --------- Configure for CHAR semantics ---------	
	
	if [ "$CHAR_SEMANTICS" = "yes" ]; then
			
		FILE="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Metadata/scripts/create_oracle_i2b2metadata_tables.sql"
		
		if [ ! -f "$FILE" ]; then  
			updateBackTitle
			dialog --colors --backtitle "$BACKTITLE" --msgbox "Could not switch to CHAR semantics, file not found!"
		else
			if [ ! -f "$FILE.orig" ]; then  
				cp -i $FILE $FILE.orig
			fi
			sed '1i\
				ALTER SESSION SET NLS_LENGTH_SEMANTICS=CHAR;' <$FILE.orig >$FILE 
			checkFileChanged $FILE.orig $FILE "createProject(): configure for char-semantics (1)"
		fi
				
		FILE="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Crcdata/scripts/crc_create_datamart_oracle.sql"
		if [ ! -f "$FILE" ]; then  
			updateBackTitle
			dialog --colors --backtitle "$BACKTITLE" --msgbox "Could not switch to CHAR semantics, file not found!"
		else
			if [ ! -f "$FILE.orig" ]; then  
				cp -i $FILE $FILE.orig
			fi
			
			sed '1i\
				ALTER SESSION SET NLS_LENGTH_SEMANTICS=CHAR;' <$FILE.orig >$FILE 
			checkFileChanged $FILE.orig $FILE "createProject(): configure for char-semantics (2)"
		fi
	fi
	
	# --------- Load "Metadata" ---------
	progressBar 20 "Creating ONT tables ..."

	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Metadata/ 

	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Metadata/"
	createDBProperties $DIR $I2B2DB_USR $I2B2DB_PWD

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_metadata_tables_release_$I2B2RELEASE > $MY_PATH/logs/createproject2.log 2> $MY_PATH/logs/createproject2.err.log
	errorHandler $LINENO "Create project" $MY_PATH/logs/createproject2.log $MY_PATH/logs/createproject2.err.log
	
	# Also create initial entry in TABLE_ACCESS: 

	cd "$MY_PATH/database/"
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $I2B2DB_USR $I2B2DB_PWD

	echo "Insert into TABLE_ACCESS (C_TABLE_CD,C_TABLE_NAME,C_PROTECTED_ACCESS,C_HLEVEL,C_FULLNAME,C_NAME,C_SYNONYM_CD,C_VISUALATTRIBUTES,C_TOTALNUM,C_BASECODE,C_FACTTABLECOLUMN,C_DIMTABLENAME,C_COLUMNNAME,C_COLUMNDATATYPE,C_OPERATOR,C_DIMCODE,C_TOOLTIP,C_ENTRY_DATE,C_CHANGE_DATE,C_STATUS_CD) values ('i2b2','i2b2','N',0,'\i2b2\','Ontology','N','CA ',null,null,'concept_cd','concept_dimension','concept_path','T','LIKE','\i2b2\','Ontology',null,null,null);" > "$MY_PATH/database/scripts/database_job.sql"
	echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"


	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/createproject3.log 2> $MY_PATH/logs/createproject3.err.log
	errorHandler $LINENO "Create project" $MY_PATH/logs/createproject3.log $MY_PATH/logs/createproject3.err.log

	rm $MY_PATH/database/scripts/database_job.sql

	# --------- Load "Demodata" ---------
	progressBar 50 "Creating CRC tables ..."

	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Crcdata/

	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Crcdata/"
	createDBProperties $DIR $I2B2DB_USR $I2B2DB_PWD

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_crcdata_tables_release_$I2B2RELEASE > $MY_PATH/logs/createproject4.log 2> $MY_PATH/logs/createproject4.err.log
	errorHandler $LINENO "Create project" $MY_PATH/logs/createproject4.log $MY_PATH/logs/createproject4.err.log
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_procedures_release_$I2B2RELEASE > $MY_PATH/logs/createproject5.log 2> $MY_PATH/logs/createproject5.err.log
	errorHandler $LINENO "Create project" $MY_PATH/logs/createproject5.log $MY_PATH/logs/createproject5.err.log

	# --------- Load "Workdata" ---------
	progressBar 75 "Creating WORK tables ..."

	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Workdata/

	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Workdata/"
	createDBProperties $DIR $I2B2DB_USR $I2B2DB_PWD

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml create_workdata_tables_release_$I2B2RELEASE > $MY_PATH/logs/createproject6.log 2> $MY_PATH/logs/createproject6.err.log
	errorHandler $LINENO "Create project" $MY_PATH/logs/createproject6.log $MY_PATH/logs/createproject6.err.log

	# Also create the entries in WORKDATA_ACCESS. Not sure if this is OK this way: 

	cd "$MY_PATH/database/"

	DIR="$MY_PATH/database/"
	createDBProperties $DIR $I2B2DB_USR $I2B2DB_PWD

	echo "INSERT INTO WORKPLACE_ACCESS(C_TABLE_CD, C_TABLE_NAME, C_PROTECTED_ACCESS, C_HLEVEL, C_NAME, C_USER_ID, C_GROUP_ID, C_SHARE_ID, C_INDEX, C_PARENT_INDEX, C_VISUALATTRIBUTES, C_TOOLTIP) VALUES('demo', 'WORKPLACE','N', 0, '@', '@', '@', 'N', 0, NULL, 'CA', '@');" > "$MY_PATH/database/scripts/database_job.sql"
	echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"


	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/createproject7.log 2> $MY_PATH/logs/createproject7.err.log
	errorHandler $LINENO "Create project" $MY_PATH/logs/createproject7.log $MY_PATH/logs/createproject7.err.log
	
	rm $MY_PATH/database/scripts/database_job.sql

	# --------- Load "Imdata" ---------

	progressBar 80 "Creating IM tables ..."

	cd $I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Imdata/

	DIR="$I2B2_SRC/edu.harvard.i2b2.data/$RELEASEPATH/NewInstall/Imdata/"
	createDBProperties $DIR $I2B2DB_USR $I2B2DB_PWD
	
	$ANT_HOME/bin/ant -f data_build.xml create_imdata_tables_release_$I2B2RELEASE > $MY_PATH/logs/createproject8.log 2> $MY_PATH/logs/createproject8.err.log
	errorHandler $LINENO "create_imdata_tables_release_$I2B2RELEASE" $MY_PATH/logs/createproject8.log $MY_PATH/logs/createproject8.err.log

	# --------- Load sample Staging Tables ---------
	# TODO: Improve/Implement for non-ORACLE DBs:
	#if ([ $DBTYPE = "ORACLE" ]); then
	#	progressBar 75 "Creating staging tables ..."
	#	cd "$MY_PATH/database/"
	#	DIR="$MY_PATH/database/"
	#	createDBProperties $DIR $I2B2DB_USR $I2B2DB_PWD
	#	checkJavaInstallation
	#	$ANT_HOME/bin/ant -f data_build.xml insert_stg_examples > $MY_PATH/logs/createproject8.log 2> $MY_PATH/logs/createproject8.err.log
	#	errorHandler $LINENO "Create project" $MY_PATH/logs/createproject8.log $MY_PATH/logs/createproject8.err.log
	#fi

	# Copy the Boston Demodata to the new project:
	
	
    if [ $IMPORT_BOSTON = "yes" ]; then
    
		if [ $DBTYPE = "MSSQL" ]; then
		
			progressBar 80 "Copying demo data (takes long, progressbar may look stuck) ..."
			cd "$MY_PATH/database/"
			DIR="$MY_PATH/database/"
			createDBProperties $DIR $DB_SYSUSER $DB_SYSPASS

			# TODO: check if this preserves the constraints on the tables:
		
			echo "DROP TABLE $I2B2DB_USR.dbo.I2B2;" > "$MY_PATH/database/scripts/database_job.sql"
			echo "DROP TABLE $I2B2DB_USR.dbo.CONCEPT_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "DROP TABLE $I2B2DB_USR.dbo.PATIENT_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "DROP TABLE $I2B2DB_USR.dbo.OBSERVATION_FACT;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "DROP TABLE $I2B2DB_USR.dbo.VISIT_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "DROP TABLE $I2B2DB_USR.dbo.ENCOUNTER_MAPPING;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "DROP TABLE $I2B2DB_USR.dbo.PROVIDER_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "DROP TABLE $I2B2DB_USR.dbo.QT_BREAKDOWN_PATH;" >> "$MY_PATH/database/scripts/database_job.sql"
		
			echo "SELECT * INTO $I2B2DB_USR.dbo.I2B2 FROM I2B2METADATA.dbo.I2B2;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "SELECT * INTO $I2B2DB_USR.dbo.CONCEPT_DIMENSION FROM I2B2DEMODATA.dbo.CONCEPT_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "SELECT * INTO $I2B2DB_USR.dbo.PATIENT_DIMENSION FROM I2B2DEMODATA.dbo.PATIENT_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "SELECT * INTO $I2B2DB_USR.dbo.OBSERVATION_FACT FROM I2B2DEMODATA.dbo.OBSERVATION_FACT;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "SELECT * INTO $I2B2DB_USR.dbo.VISIT_DIMENSION FROM I2B2DEMODATA.dbo.VISIT_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "SELECT * INTO $I2B2DB_USR.dbo.ENCOUNTER_MAPPING FROM I2B2DEMODATA.dbo.ENCOUNTER_MAPPING;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "SELECT * INTO $I2B2DB_USR.dbo.PROVIDER_DIMENSION FROM I2B2DEMODATA.dbo.PROVIDER_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "SELECT * INTO $I2B2DB_USR.dbo.QT_BREAKDOWN_PATH FROM I2B2DEMODATA.dbo.QT_BREAKDOWN_PATH;" >> "$MY_PATH/database/scripts/database_job.sql"
		
			echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"
			checkJavaInstallation
			$ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/createproject8a.log 2> $MY_PATH/logs/createproject8a.err.log
			errorHandler $LINENO "Create project" $MY_PATH/logs/createproject8a.log $MY_PATH/logs/createproject8a.err.log
		fi

		if [ $DBTYPE = "ORACLE" ]; then
		
			progressBar 80 "Granting access to Boston Demodata ..."
			cd "$MY_PATH/database/"
			DIR="$MY_PATH/database/"
			createDBProperties $DIR $DB_SYSUSER $DB_SYSPASS

			echo "GRANT SELECT ON I2B2METADATA.I2B2 TO $I2B2DB_USR;" > "$MY_PATH/database/scripts/database_job.sql"
			echo "GRANT SELECT ON I2B2DEMODATA.CONCEPT_DIMENSION TO $I2B2DB_USR;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "GRANT SELECT ON I2B2DEMODATA.PATIENT_DIMENSION TO $I2B2DB_USR;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "GRANT SELECT ON I2B2DEMODATA.OBSERVATION_FACT TO $I2B2DB_USR;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "GRANT SELECT ON I2B2DEMODATA.VISIT_DIMENSION TO $I2B2DB_USR;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "GRANT SELECT ON I2B2DEMODATA.ENCOUNTER_MAPPING TO $I2B2DB_USR;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "GRANT SELECT ON I2B2DEMODATA.PROVIDER_DIMENSION TO $I2B2DB_USR;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "GRANT SELECT ON I2B2DEMODATA.QT_BREAKDOWN_PATH TO $I2B2DB_USR;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"

			checkJavaInstallation
			$ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/createproject8b1.log 2> $MY_PATH/logs/createproject8b1.err.log
			errorHandler $LINENO "Grant access to Boston Demodata" $MY_PATH/logs/createproject8b1.log $MY_PATH/logs/createproject8b1.err.log

			progressBar 83 "Copying demo data (takes long, progressbar may look stuck) ..."
			cd "$MY_PATH/database/"
			DIR="$MY_PATH/database/"
			createDBProperties $DIR $I2B2DB_USR $DB_PASS

			echo "TRUNCATE TABLE I2B2;" > "$MY_PATH/database/scripts/database_job.sql"
			echo "TRUNCATE TABLE CONCEPT_DIMENSION ;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "TRUNCATE TABLE PATIENT_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "TRUNCATE TABLE OBSERVATION_FACT;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "TRUNCATE TABLE VISIT_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "TRUNCATE TABLE ENCOUNTER_MAPPING;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "TRUNCATE TABLE PROVIDER_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "TRUNCATE TABLE QT_BREAKDOWN_PATH;" >> "$MY_PATH/database/scripts/database_job.sql"

			# Warning: this does not preserve the constraints:
			#echo "CREATE TABLE I2B2 AS (SELECT * FROM I2B2METADATA.I2B2);" >> "$MY_PATH/database/scripts/database_job.sql"
			#echo "CREATE TABLE CONCEPT_DIMENSION AS (SELECT * FROM I2B2DEMODATA.CONCEPT_DIMENSION);" >> "$MY_PATH/database/scripts/database_job.sql"
			#echo "CREATE TABLE PATIENT_DIMENSION AS (SELECT * FROM I2B2DEMODATA.PATIENT_DIMENSION);" >> "$MY_PATH/database/scripts/database_job.sql"
			#echo "CREATE TABLE OBSERVATION_FACT AS (SELECT * FROM I2B2DEMODATA.OBSERVATION_FACT);" >> "$MY_PATH/database/scripts/database_job.sql"
			#echo "CREATE TABLE VISIT_DIMENSION AS (SELECT * FROM I2B2DEMODATA.VISIT_DIMENSION);" >> "$MY_PATH/database/scripts/database_job.sql"
			#echo "CREATE TABLE ENCOUNTER_MAPPING AS (SELECT * FROM I2B2DEMODATA.ENCOUNTER_MAPPING);" >> "$MY_PATH/database/scripts/database_job.sql"
			#echo "CREATE TABLE PROVIDER_DIMENSION AS (SELECT * FROM I2B2DEMODATA.PROVIDER_DIMENSION);" >> "$MY_PATH/database/scripts/database_job.sql"
			#echo "CREATE TABLE QT_BREAKDOWN_PATH AS (SELECT * FROM I2B2DEMODATA.QT_BREAKDOWN_PATH);" >> "$MY_PATH/database/scripts/database_job.sql"
			#echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"

			echo "INSERT INTO I2B2 SELECT * FROM I2B2METADATA.I2B2;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "INSERT INTO CONCEPT_DIMENSION SELECT * FROM I2B2DEMODATA.CONCEPT_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "INSERT INTO PATIENT_DIMENSION SELECT * FROM I2B2DEMODATA.PATIENT_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "INSERT INTO OBSERVATION_FACT SELECT * FROM I2B2DEMODATA.OBSERVATION_FACT;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "INSERT INTO VISIT_DIMENSION SELECT * FROM I2B2DEMODATA.VISIT_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "INSERT INTO ENCOUNTER_MAPPING SELECT * FROM I2B2DEMODATA.ENCOUNTER_MAPPING;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "INSERT INTO PROVIDER_DIMENSION SELECT * FROM I2B2DEMODATA.PROVIDER_DIMENSION;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "INSERT INTO QT_BREAKDOWN_PATH SELECT * FROM I2B2DEMODATA.QT_BREAKDOWN_PATH;" >> "$MY_PATH/database/scripts/database_job.sql"
			echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"
		
			checkJavaInstallation
			$ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/createproject8b2.log 2> $MY_PATH/logs/createproject8b2.err.log
			errorHandler $LINENO "Create project" $MY_PATH/logs/createproject8b2.log $MY_PATH/logs/createproject8b2.err.log

		fi
	fi
	
	# --------- Add JBoss Datasources to XML: ---------

	progressBar 94 "Registering JBoss datasources ..."

	cat $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-crc-ds.ins | sed -e 's/PROJECTNAME/'"$PROJ_NAME"'/g;s/NOSPACES/'"$PROJ_NAME_NOSPACES"'/g;s/DBUSER/'"$DB_USER"'/g;s/DBPASS/'"$DB_PASS"'/g;s/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g' > $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-crc-ds.tmp
	cat $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-ont-ds.ins | sed -e 's/PROJECTNAME/'"$PROJ_NAME"'/g;s/NOSPACES/'"$PROJ_NAME_NOSPACES"'/g;s/DBUSER/'"$DB_USER"'/g;s/DBPASS/'"$DB_PASS"'/g;s/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g' > $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-ont-ds.tmp
	cat $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-work-ds.ins | sed -e 's/PROJECTNAME/'"$PROJ_NAME"'/g;s/NOSPACES/'"$PROJ_NAME_NOSPACES"'/g;s/DBUSER/'"$DB_USER"'/g;s/DBPASS/'"$DB_PASS"'/g;s/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g' > $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-work-ds.tmp
	cat $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-im-ds.ins | sed -e 's/PROJECTNAME/'"$PROJ_NAME"'/g;s/NOSPACES/'"$PROJ_NAME_NOSPACES"'/g;s/DBUSER/'"$DB_USER"'/g;s/DBPASS/'"$DB_PASS"'/g;s/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g' > $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-im-ds.tmp
 
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml $MY_PATH/config/crc-ds.old
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/ont-ds.xml $MY_PATH/config/ont-ds.old
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/work-ds.xml $MY_PATH/config/work-ds.old
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/im-ds.xml $MY_PATH/config/im-ds.old

	cat $MY_PATH/config/crc-ds.old | sed -e '/<!--WIZARDINSERT-->/r '"$MY_PATH"'/config/ds-config/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/generic-crc-ds.tmp' > $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml
	cat $MY_PATH/config/ont-ds.old | sed -e '/<!--WIZARDINSERT-->/r '"$MY_PATH"'/config/ds-config/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/generic-ont-ds.tmp' > $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/ont-ds.xml
	cat $MY_PATH/config/work-ds.old | sed -e '/<!--WIZARDINSERT-->/r '"$MY_PATH"'/config/ds-config/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/generic-work-ds.tmp' > $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/work-ds.xml
	cat $MY_PATH/config/im-ds.old | sed -e '/<!--WIZARDINSERT-->/r '"$MY_PATH"'/config/ds-config/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/generic-im-ds.tmp' > $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/im-ds.xml

	rm $MY_PATH/config/crc-ds.old
	rm $MY_PATH/config/ont-ds.old
	rm $MY_PATH/config/work-ds.old
	rm $MY_PATH/config/im-ds.old

	rm $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-crc-ds.tmp
	rm $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-ont-ds.tmp
	rm $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-work-ds.tmp
	rm $MY_PATH/config/ds-config/inserts/$DS_TEMPLATE_VERSION/$DBTYPE/generic-im-ds.tmp

	# --------- Register the JBoss Datasources in $HIVE_SCHEMA : ---------

	progressBar 95 "Registering JBoss datasources in $HIVE_SCHEMA ..."
	
	cd "$MY_PATH/database/"
	
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $HIVE_SCHEMA $HIVE_PASS
	
	if ([ $DBTYPE = "MSSQL" ]); then
	
		echo "Insert into CRC_DB_LOOKUP (C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID,C_DB_FULLSCHEMA,C_DB_DATASOURCE,C_DB_SERVERTYPE,C_DB_NICENAME,C_DB_TOOLTIP,C_ENTRY_DATE,C_CHANGE_DATE,C_STATUS_CD) values ('$HIVE_ID','/$PROJ_NAME_NOSPACES/','@','$DB_USER.dbo','java:/QueryTool"$PROJ_NAME_NOSPACES"DS','SQLSERVER','$PROJ_NAME',null,null,null,null);" > "$MY_PATH/database/scripts/database_job.sql"
		echo "Insert into ONT_DB_LOOKUP (C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID,C_DB_FULLSCHEMA,C_DB_DATASOURCE,C_DB_SERVERTYPE,C_DB_NICENAME,C_DB_TOOLTIP,C_ENTRY_DATE,C_CHANGE_DATE,C_STATUS_CD) values ('$HIVE_ID','$PROJ_NAME_NOSPACES/','@','$DB_USER.dbo','java:/Ontology"$PROJ_NAME_NOSPACES"DS','SQLSERVER','$PROJ_NAME',null,null,null,null);" >> "$MY_PATH/database/scripts/database_job.sql"
		echo "Insert into WORK_DB_LOOKUP (C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID,C_DB_FULLSCHEMA,C_DB_DATASOURCE,C_DB_SERVERTYPE,C_DB_NICENAME,C_DB_TOOLTIP,C_ENTRY_DATE,C_CHANGE_DATE,C_STATUS_CD) values ('$HIVE_ID','$PROJ_NAME_NOSPACES/','@','$DB_USER.dbo','java:/Workplace"$PROJ_NAME_NOSPACES"DS','SQLSERVER','$PROJ_NAME',null,null,null,null);" >> "$MY_PATH/database/scripts/database_job.sql"
		echo "Insert into IM_DB_LOOKUP (C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID,C_DB_FULLSCHEMA,C_DB_DATASOURCE,C_DB_SERVERTYPE,C_DB_NICENAME,C_DB_TOOLTIP,C_ENTRY_DATE,C_CHANGE_DATE,C_STATUS_CD) values ('$HIVE_ID','$PROJ_NAME_NOSPACES/','@','$DB_USER.dbo','java:/IM"$PROJ_NAME_NOSPACES"DS','SQLSERVER','$PROJ_NAME',null,null,null,null);" >> "$MY_PATH/database/scripts/database_job.sql"
		echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"
	
	else
	
		echo "Insert into CRC_DB_LOOKUP (C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID,C_DB_FULLSCHEMA,C_DB_DATASOURCE,C_DB_SERVERTYPE,C_DB_NICENAME,C_DB_TOOLTIP,C_ENTRY_DATE,C_CHANGE_DATE,C_STATUS_CD) values ('$HIVE_ID','/$PROJ_NAME_NOSPACES/','@','$DB_USER','java:/QueryTool"$PROJ_NAME_NOSPACES"DS','$DBTYPE','$PROJ_NAME',null,null,null,null);" > "$MY_PATH/database/scripts/database_job.sql"
		echo "Insert into ONT_DB_LOOKUP (C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID,C_DB_FULLSCHEMA,C_DB_DATASOURCE,C_DB_SERVERTYPE,C_DB_NICENAME,C_DB_TOOLTIP,C_ENTRY_DATE,C_CHANGE_DATE,C_STATUS_CD) values ('$HIVE_ID','$PROJ_NAME_NOSPACES/','@','$DB_USER','java:/Ontology"$PROJ_NAME_NOSPACES"DS','$DBTYPE','$PROJ_NAME',null,null,null,null);" >> "$MY_PATH/database/scripts/database_job.sql"
		echo "Insert into WORK_DB_LOOKUP (C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID,C_DB_FULLSCHEMA,C_DB_DATASOURCE,C_DB_SERVERTYPE,C_DB_NICENAME,C_DB_TOOLTIP,C_ENTRY_DATE,C_CHANGE_DATE,C_STATUS_CD) values ('$HIVE_ID','$PROJ_NAME_NOSPACES/','@','$DB_USER','java:/Workplace"$PROJ_NAME_NOSPACES"DS','$DBTYPE','$PROJ_NAME',null,null,null,null);" >> "$MY_PATH/database/scripts/database_job.sql"
		echo "Insert into IM_DB_LOOKUP (C_DOMAIN_ID,C_PROJECT_PATH,C_OWNER_ID,C_DB_FULLSCHEMA,C_DB_DATASOURCE,C_DB_SERVERTYPE,C_DB_NICENAME,C_DB_TOOLTIP,C_ENTRY_DATE,C_CHANGE_DATE,C_STATUS_CD) values ('$HIVE_ID','$PROJ_NAME_NOSPACES/','@','$DB_USER','java:/IM"$PROJ_NAME_NOSPACES"DS','$DBTYPE','$PROJ_NAME',null,null,null,null);" >> "$MY_PATH/database/scripts/database_job.sql"
		echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"

	fi

		
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/createproject9.log 2> $MY_PATH/logs/createproject9.err.log
	errorHandler $LINENO "Create project" $MY_PATH/logs/createproject9.log $MY_PATH/logs/createproject9.err.log
	
	rm $MY_PATH/database/scripts/database_job.sql

	cd $MY_PATH

	# --------- Write the attributes to I2B2PM: ---------

	progressBar 99 "Registering project in $PM_SCHEMA ..."
	
	cd "$MY_PATH/database/"
	
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $PM_SCHEMA $PM_PASS

	echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$PROJ_NAME_NOSPACES','OBFSC_SERVICE_ACCOUNT','USER',null,null,null,'A');" > "$MY_PATH/database/scripts/database_job.sql"
	echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$PROJ_NAME_NOSPACES','OBFSC_SERVICE_ACCOUNT','DATA_OBFSC',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$PROJ_NAME_NOSPACES','AGG_SERVICE_ACCOUNT','DATA_AGG',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$PROJ_NAME_NOSPACES','AGG_SERVICE_ACCOUNT','DATA_OBFSC',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$PROJ_NAME_NOSPACES','AGG_SERVICE_ACCOUNT','USER',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "Insert into PM_PROJECT_DATA (PROJECT_ID,PROJECT_NAME,PROJECT_WIKI,PROJECT_KEY,PROJECT_PATH,PROJECT_DESCRIPTION,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$PROJ_NAME_NOSPACES','$PROJ_NAME','http://www.i2b2.org',null,'/$PROJ_NAME_NOSPACES',null,null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/createproject10.log 2> $MY_PATH/logs/createproject10.err.log
	errorHandler $LINENO "Create project" $MY_PATH/logs/createproject10.log $MY_PATH/logs/createproject10.err.log
	
	rm $MY_PATH/database/scripts/database_job.sql

	cd $MY_PATH

   	# "Wizard ETL" is no longer supported, it is replaced with the above routine to copy the Boston Demodata to the new project:
	
	# --------- Register ETL-Job: ---------
	#if ([ $DBTYPE = "ORACLE" ]); then
	#	mv $MY_PATH/ETL/run_etl.xml $MY_PATH/ETL/run_etl.old
	#	cat $MY_PATH/ETL/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/generic_etl_job.ins | sed -e 's/PROJECTNAME/'"$PROJ_NAME"'/g;s/NOSPACES/'"$PROJ_NAME_NOSPACES"'/g;s/DBUSER/'"$DB_USER"'/g;s/DBPASS/'"$DB_PASS"'/g;s/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g' > $MY_PATH/ETL/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/generic_etl_job.tmp
	#	cat $MY_PATH/ETL/run_etl.old | sed -e '/<!--WIZARDINSERT-->/r '"$MY_PATH"'/ETL/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/generic_etl_job.tmp' > $MY_PATH/ETL/run_etl.xml
	#	rm $MY_PATH/ETL/run_etl.old
	#	rm $MY_PATH/ETL/inserts/'"$DS_TEMPLATE_VERSION"'/'"$DBTYPE"'/generic_etl_job.tmp
	#	# --------- Copy SQL Template: ---------
	#	# avoid overwriting an old file:
	#	if [ -f "$MY_PATH/ETL/scripts/$PROJ_NAME_NOSPACES.sql" ]; then  
	#		TIMESTAMP=`date`
	#		mv "$MY_PATH/ETL/scripts/$PROJ_NAME_NOSPACES.sql" "$MY_PATH/ETL/scripts/$PROJ_NAME_NOSPACES-$TIMESTAMP.backup"
	#	fi
	#	cat $MY_PATH/ETL/Template.sql | sed -e 's/--==PROJECTNAME==--/'"$PROJ_NAME"'/g;s/--==DBUSER==--/'"$DB_USER"'/g;s/--==DBPASS==--/'"$DB_PASS"'/g;s/--==DB_SERVER==--/'"$DB_SERVER"'/g;s/--==DB_PORT==--/'"$DB_PORT"'/g;s/--==ORA_SSID==--/'"$ORA_SSID"'/g;' > $MY_PATH/ETL/scripts/$PROJ_NAME_NOSPACES.sql
	#fi

	# Append the project name to the list-file:

	touch $MY_PATH/config/projectlist.dat
	echo "$PROJ_NAME#$DB_USER#$DB_PASS#" >> $MY_PATH/config/projectlist.dat

	progressBar 100 "Done!"
	sleep 2
    cd $MY_PATH
   
   	# "Wizard ETL" is no longer supported, it is replaced with the above routine to copy the Boston Demodata to the new project:
	#if ([ $DBTYPE = "ORACLE" ]); then
	#	runETL $PROJ_NAME_NOSPACES
	#fi

    CONFIG_DIRTY=yes
	saveValues
}




# ==================================================================================================
# removeProject() - removes an i2b2 project
# ==================================================================================================

removeProject() {


	updateBackTitle
	
    #dialog --colors --backtitle "$BACKTITLE" --msgbox "Not implemented yet!" 6 40

    if [ -f "$MY_PATH/logs/removeproject.log" ]; then  
        rm $MY_PATH/logs/removeproject.log
    fi
    if [ -f "$MY_PATH/logs/removeproject.err.log" ]; then  
        rm $MY_PATH/logs/removeproject.err.log
    fi

	
	if [ "$SILENT" = "1" ]; then  

		PROJ_NAME="My Project"
		DB_REM="yes"
		
	else
		
		dialog --colors --backtitle "$BACKTITLE" --title " Remove i2b2 Project " \
			--form "Remove i2b2 project\nUse [up] [down] to select input field, [tab] to select buttons " 18 70 10 \
			"Project Name:" 2 4 "$LAST_PROJECT" 2 33 25 0\
			"Auto remove Oracle User?" 4 4 "yes" 4 33 4 0\
			2>$TEMPVAR
			
		if [ ${?} -ne 0 ]; then return; fi   

		PROJ_NAME=`sed -n 1p $TEMPVAR`
		DB_REM=`sed -n 2p $TEMPVAR`
		
		LAST_PROJECT=$PROJ_NAME
		saveValues
		
	fi

    PROJ_NAME_NOSPACES=`echo $PROJ_NAME | sed -e "s/ //g"`

    DB_SYSPASS=$DB_SYSPASS
    DB_SYSUSER=$DB_SYSUSER
 
    DB_USER="$DB_SCHEMAPREFIX"`echo $PROJ_NAME | sed -e "s/ //g;y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/"`
	DB_USER=`echo ${DB_USER,,}`
	
	if [ "$DB_USER" = "I2B2DEMO" ]; then
        dialog --colors --backtitle "$BACKTITLE" --msgbox "ERROR: The project name 'Demo' is reserved for the Boston Demodata. Please use 'Remove Boston Demodata' to remove this project." 6 75
        return
    fi
    
    EXISTSPROJECT=`cat $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml | grep '<!--'"$PROJ_NAME"'START-->'`
    if [ "$EXISTSPROJECT" = "" ]; then
		mv $MY_PATH/config/projectlist.dat $MY_PATH/config/projectlist_old.dat 
		cat $MY_PATH/config/projectlist_old.dat  | grep -v $DB_USER >> $MY_PATH/config/projectlist.dat 
		rm $MY_PATH/config/projectlist_old.dat 
		dialog --colors --backtitle "$BACKTITLE" --msgbox "ERROR: A project with this name seems not to exist - aborting!" 6 72
		return
    fi

	testDBConnectivity $DB_SYSUSER $DB_SYSPASS
	testDBConnectivity $HIVE_SCHEMA $HIVE_PASS
	testDBConnectivity $PM_SCHEMA $PM_PASS

    stopJBoss
   
	if [ "$DB_REM" = "yes" ]; then
		# --------- Remove project user ---------
		progressBar 0 "Removing schema $DB_USER ..."
		dropDatabaseUser $DB_USER
	fi

	# --------- Remove JBoss Datasources: ---------
 
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml $MY_PATH/config/crc-ds.old
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/ont-ds.xml $MY_PATH/config/ont-ds.old
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/work-ds.xml $MY_PATH/config/work-ds.old
	mv $MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/im-ds.xml $MY_PATH/config/im-ds.old
   
	# see: http://ilfilosofo.com/blog/2008/04/26/sed-multi-line-search-and-replace
  
	sed -n '1h;1!H;${;g;s/<!--'"$PROJ_NAME"'START-->.*<!--'"$PROJ_NAME"'END-->//g;p;}' <$MY_PATH/config/crc-ds.old >$MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/crc-ds.xml
	sed -n '1h;1!H;${;g;s/<!--'"$PROJ_NAME"'START-->.*<!--'"$PROJ_NAME"'END-->//g;p;}' <$MY_PATH/config/ont-ds.old >$MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/ont-ds.xml
	sed -n '1h;1!H;${;g;s/<!--'"$PROJ_NAME"'START-->.*<!--'"$PROJ_NAME"'END-->//g;p;}' <$MY_PATH/config/work-ds.old >$MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/work-ds.xml
	sed -n '1h;1!H;${;g;s/<!--'"$PROJ_NAME"'START-->.*<!--'"$PROJ_NAME"'END-->//g;p;}' <$MY_PATH/config/im-ds.old >$MY_PATH/config/ds-config/$DS_TEMPLATE_VERSION/$DBTYPE/im-ds.xml

	rm $MY_PATH/config/crc-ds.old
	rm $MY_PATH/config/ont-ds.old
	rm $MY_PATH/config/work-ds.old
	rm $MY_PATH/config/im-ds.old
 
	mv $MY_PATH/config/projectlist.dat $MY_PATH/config/projectlist_old.dat 
	cat $MY_PATH/config/projectlist_old.dat  | grep -v "$DB_USER#" >> $MY_PATH/config/projectlist.dat 
	rm $MY_PATH/config/projectlist_old.dat 

	# --------- Remove ETL targets: ---------
	#mv $MY_PATH/ETL/run_etl.xml $MY_PATH/ETL/run_etl.old
	## see: http://ilfilosofo.com/blog/2008/04/26/sed-multi-line-search-and-replace
	#sed -n '1h;1!H;${;g;s/<!--'"$PROJ_NAME"'START-->.*<!--'"$PROJ_NAME"'END-->//g;p;}' <$MY_PATH/ETL/run_etl.old >$MY_PATH/ETL/run_etl.xml
	#rm $MY_PATH/ETL/run_etl.old
 
	# --------- Remove entries from the *_DB_LOOKUP-tables in $HIVE_SCHEMA : --------- 

	cd "$MY_PATH/database/"
	
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $HIVE_SCHEMA $HIVE_PASS
 
	echo "DELETE FROM CRC_DB_LOOKUP WHERE C_DB_FULLSCHEMA='"$DB_USER"';" > "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM ONT_DB_LOOKUP WHERE C_DB_FULLSCHEMA='"$DB_USER"';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM WORK_DB_LOOKUP WHERE C_DB_FULLSCHEMA='"$DB_USER"';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM IM_DB_LOOKUP WHERE C_DB_FULLSCHEMA='"$DB_USER"';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job >> $MY_PATH/logs/removeproject.log 2>> $MY_PATH/logs/removeproject.err.log
	rm $MY_PATH/database/scripts/database_job.sql

	cd $MY_PATH

	# --------- Unregister project in PM_PROJECT_USER_ROLES ---------

	progressBar 99 "Unregistering project in PM_PROJECT_USER_ROLES ..."
	
	cd "$MY_PATH/database/"
	
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $PM_SCHEMA $PM_PASS
 
	echo "DELETE FROM PM_PROJECT_USER_ROLES WHERE PROJECT_ID =
	'$PROJ_NAME_NOSPACES';" > "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM PM_PROJECT_DATA WHERE PROJECT_ID = '$PROJ_NAME_NOSPACES';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job >> $MY_PATH/logs/removeproject.log 2>> $MY_PATH/logs/removeproject.err.log
	
	rm $MY_PATH/database/scripts/database_job.sql

	cd $MY_PATH
	
	progressBar 100 "Done!"
	sleep 2
  
    errorHandler $LINENO "Remove Project" $MY_PATH/logs/removeproject.log $MY_PATH/logs/removeproject.err.log

	CONFIG_DIRTY=yes
	saveValues

}


# ==================================================================================================
# removeUser() - removes an i2b2 user
# ==================================================================================================

removeUser() {

	updateBackTitle
	
	if [ "$SILENT" = "1" ]; then  

		USER_ID="test"

	else

		dialog --colors --backtitle "$BACKTITLE" \
			   --inputbox "Please enter the User ID:" 8 52 "$LAST_USER" 2>$TEMPVAR

		if [ ${?} -ne 0 ]; then return; fi   

		USER_ID=`cat $TEMPVAR`
		
	fi

	testDBConnectivity $DB_SYSUSER $DB_SYSPASS
	testDBConnectivity $HIVE_SCHEMA $HIVE_PASS
	testDBConnectivity $PM_SCHEMA $PM_PASS
	
	# --------- Remove the user from I2B2PM: ---------

	progressBar 0 "Removing User from $PM_SCHEMA ..."
	
	cd "$MY_PATH/database/"
	
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $PM_SCHEMA $PM_PASS

	echo "DELETE FROM PM_USER_DATA WHERE USER_ID = '$USER_ID';" > "$MY_PATH/database/scripts/database_job.sql"
	echo "DELETE FROM PM_PROJECT_USER_ROLES WHERE USER_ID = '$USER_ID';" >> "$MY_PATH/database/scripts/database_job.sql"
	echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"

	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/delete_user.log 2> $MY_PATH/logs/delete_user.err.log
	rm $MY_PATH/database/scripts/database_job.sql

	cd $MY_PATH

	# Remove the user from the list-file:
	
	mv $MY_PATH/config/userlist.dat $MY_PATH/config/userlist_old.dat 
	cat $MY_PATH/config/userlist_old.dat  | grep -v "$USER_ID#" >> $MY_PATH/config/userlist.dat 
	rm $MY_PATH/config/userlist_old.dat 

	progressBar 100 "Done!"
	sleep 2
  
    errorHandler $LINENO "Delete User" $MY_PATH/logs/delete_user.log $MY_PATH/logs/delete_user.err.log

}



# ==================================================================================================
# createUser() - creates a new i2b2 user
# ==================================================================================================

createUser() {

	updateBackTitle
	
	if [ "$SILENT" = "1" ]; then  

		NEW_USER="test"
		NEW_FULL="Silent Install Test User"
		NEW_PASS="demouser"
	
	else
	
		dialog --colors --backtitle "$BACKTITLE"  --title " New i2b2 User "\
			--form "Use [up] [down] to select input field, [tab] to select buttons " 12 68 5 \
			"User ID:" 2 4 "i2b2user" 2 23 33 0\
			"Full Name:" 3 4 "Test User" 3 23 33 0\
			"Password:" 4 4 "demouser" 4 23 "-33" 0\
			" " 5 4 "(Change password in webclient!)" 5 23 "-33" 0\
			2>$TEMPVAR
			
		if [ ${?} -ne 0 ]; then return; fi   
		
		NEW_USER=`sed -n 1p $TEMPVAR`
		NEW_FULL=`sed -n 2p $TEMPVAR`
		NEW_PASS=`sed -n 3p $TEMPVAR`
	
	fi

		
    LAST_USER=$NEW_USER
    
    # since this doen't seem to work, ...
    #NEW_PASS=`echo -n $NEW_PASS | md5sum -t | sed -e 's/[ -]//g'`
    
    # ... we use the password 'demouser':
    NEW_PASS='9117d59a69dc49807671a51f10ab7f'

    loadHive

	testDBConnectivity $DB_SYSUSER $DB_SYSPASS
	testDBConnectivity $HIVE_SCHEMA $HIVE_PASS
	testDBConnectivity $PM_SCHEMA $PM_PASS
	
    UCASE_USER=`echo $NEW_USER | sed -e "s/ //g;y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/"`
	if [ "$UCASE_USER" = "I2B2" ]; then
		updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --msgbox "ERROR: The user name 'i2b2' is reserved for the Boston Demodata - aborting!" 6 75
        return
    fi
	if [ "$UCASE_USER" = "DEMO" ]; then
		updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --msgbox "ERROR: The user name 'demo' is reserved for the Boston Demodata - aborting!" 6 75
        return
    fi
	
	# --------- Register the user in I2B2PM: ---------

	progressBar 0 "Registering User in $PM_SCHEMA ..."
	
	cd "$MY_PATH/database/"
	
	DIR="$MY_PATH/database/"
	createDBProperties $DIR $PM_SCHEMA $PM_PASS
 
	echo "Insert into PM_USER_DATA (USER_ID,FULL_NAME,PASSWORD,EMAIL,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$NEW_USER','$NEW_FULL','$NEW_PASS',null,null,null,null,'A');" > "$MY_PATH/database/scripts/database_job.sql"
	echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"

	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/create_user.log 2> $MY_PATH/logs/create_user.err.log
	rm $MY_PATH/database/scripts/database_job.sql

	
	# --------- Register the user in I2B2PM: ---------

	if [ "$USE_LDAP" = "yes" ]; then

		progressBar 50 "Registering User for LDAP authentication ..."
		
		cd "$MY_PATH/database/"
		
		DIR="$MY_PATH/database/"
		createDBProperties $DIR $PM_SCHEMA $PM_PASS
	 
		echo "INSERT INTO pm_user_params (datatype_cd,user_id,param_name_cd,value,change_date,entry_date,changeby_char,status_cd) VALUES ('T','$NEW_USER','authentication_method','$LDAP_AUTH',SYSDATE,SYSDATE,'i2b2 Wizard','A');" > "$MY_PATH/database/scripts/database_job.sql"

		echo "INSERT INTO pm_user_params (datatype_cd,user_id,param_name_cd,value,change_date,entry_date,changeby_char,status_cd) VALUES ('T','$NEW_USER','domain','$LDAP_DOMAIN',SYSDATE,SYSDATE,'i2b2 Wizard','A');" >>"$MY_PATH/database/scripts/database_job.sql"

		echo "INSERT INTO pm_user_params (datatype_cd,user_id,param_name_cd,value,change_date,entry_date,changeby_char,status_cd) VALUES ('T','$NEW_USER','domain_controller','$LDAP_CONTR',SYSDATE,SYSDATE,'i2b2 Wizard','A');" >> "$MY_PATH/database/scripts/database_job.sql"
		
		echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"

		checkJavaInstallation
		$ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/create_user.log 2> $MY_PATH/logs/create_user.err.log
		rm $MY_PATH/database/scripts/database_job.sql

	fi

	
	
	cd $MY_PATH
	
	# Append the user name to the list-file:
	
	touch $MY_PATH/config/userlist.dat
	echo "$NEW_USER#$NEW_FULL#$NEW_PASS#" >> $MY_PATH/config/userlist.dat

	progressBar 100 "Done!"
	sleep 2

    errorHandler $LINENO "Create User" $MY_PATH/logs/create_user.log $MY_PATH/logs/create_user.err.log
	
}


# ==================================================================================================
# assignUser() - assigns an user to a specific i2b2 project
# ==================================================================================================

assignUser() {

	updateBackTitle
	
	if [ "$SILENT" = "1" ]; then  

		ASSIGN_1="test"
		ASSIGN_2="My Project"
		ASSIGN_2=`echo $ASSIGN_2 | sed -e "s/ //g"`
		ASSIGN_3="yes"
		ASSIGN_4="yes"
		ASSIGN_5="yes"
		ASSIGN_6="yes"
		ASSIGN_7="yes"
		ASSIGN_8="yes"
		ASSIGN_9="yes"
		ASSIGN_10="yes"
		ASSIGN_11="yes"
	
	else

		dialog --colors --backtitle "$BACKTITLE"  --title " Assign User to Project "\
			--form "Use [up] [down] to select input field, [tab] to select buttons " 21 68 15 \
			"User ID:" 2 4 "$LAST_USER" 2 23 33 0\
			"Project ID:" 3 4 "$LAST_PROJECT" 3 23 33 0\
			"Role ADMIN:" 5 4 "no" 5 23 5 0\
			"Role MANAGER:" 6 4 "no" 6 23 5 0\
			"Role USER:" 7 4 "yes" 7 23 5 0\
			"Can see identified data (DATA_PROT):" 9 4 "yes" 9 45 5 0\
			"DeID text. Can see blobs (DATA_DEID):" 10 4 "yes" 10 45 5 0\
			"Can see 'Limited Data Sets' (DATA_LDS):" 11 4 "yes" 11 45 5 0\
			"Can see aggregate data (DATA_AGG):" 12 4 "yes" 12 45 5 0\
			"Can see obfuscated data (DATA_OBFSC):" 13 4 "yes" 13 45 5 0\
			"Can edit custom metadata (EDITOR):" 14 4 "yes" 14 45 5 0\
			2>$TEMPVAR

		if [ ${?} -ne 0 ]; then return; fi   

		ASSIGN_1=`sed -n 1p $TEMPVAR`
		ASSIGN_2=`sed -n 2p $TEMPVAR`

		LAST_USER=$ASSIGN_1
		LAST_PROJECT=$ASSIGN_2
		saveValues

		ASSIGN_2=`echo $ASSIGN_2 | sed -e "s/ //g"`
		ASSIGN_3=`sed -n 3p $TEMPVAR`
		ASSIGN_4=`sed -n 4p $TEMPVAR`
		ASSIGN_5=`sed -n 5p $TEMPVAR`
		ASSIGN_6=`sed -n 6p $TEMPVAR`
		ASSIGN_7=`sed -n 7p $TEMPVAR`
		ASSIGN_8=`sed -n 8p $TEMPVAR`
		ASSIGN_9=`sed -n 9p $TEMPVAR`
		ASSIGN_10=`sed -n 10p $TEMPVAR`
		ASSIGN_11=`sed -n 11p $TEMPVAR`

	fi

	loadHive
	
	testDBConnectivity $DB_SYSUSER $DB_SYSPASS
	testDBConnectivity $HIVE_SCHEMA $HIVE_PASS
	testDBConnectivity $PM_SCHEMA $PM_PASS
	
	
	# --------- Write the settings to I2B2PM: ---------

	progressBar 0 "Assigning User to project ..."
	
	cd $MY_PATH/database/
	
	DIR="$MY_PATH/database/"
	
	createDBProperties $DIR $PM_SCHEMA $PM_PASS
 
	echo "DELETE FROM PM_PROJECT_USER_ROLES WHERE USER_ID = '$ASSIGN_1' AND PROJECT_ID = '$ASSIGN_2';" > "$MY_PATH/database/scripts/database_job.sql"
 
	if [ $ASSIGN_3 = "yes" ]; then
		echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$ASSIGN_2','$ASSIGN_1','ADMIN',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	fi
	if [ $ASSIGN_4 = "yes" ]; then
		echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$ASSIGN_2','$ASSIGN_1','MANAGER',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	fi
	if [ $ASSIGN_5 = "yes" ]; then
		echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$ASSIGN_2','$ASSIGN_1','USER',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	fi
	if [ $ASSIGN_6 = "yes" ]; then
		echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$ASSIGN_2','$ASSIGN_1','DATA_PROT',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	fi
	if [ $ASSIGN_7 = "yes" ]; then
		echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$ASSIGN_2','$ASSIGN_1','DATA_DEID',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	fi
	if [ $ASSIGN_8 = "yes" ]; then
		echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$ASSIGN_2','$ASSIGN_1','DATA_LDS',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	fi
	if [ $ASSIGN_9 = "yes" ]; then
		echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$ASSIGN_2','$ASSIGN_1','DATA_AGG',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	fi
	if [ $ASSIGN_10 = "yes" ]; then
		echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$ASSIGN_2','$ASSIGN_1','DATA_OBFSC',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	fi
	if [ $ASSIGN_11 = "yes" ]; then
		echo "Insert into PM_PROJECT_USER_ROLES (PROJECT_ID,USER_ID,USER_ROLE_CD,CHANGE_DATE,ENTRY_DATE,CHANGEBY_CHAR,STATUS_CD) values ('$ASSIGN_2','$ASSIGN_1','EDITOR',null,null,null,'A');" >> "$MY_PATH/database/scripts/database_job.sql"
	fi
	
	echo "COMMIT;" >> "$MY_PATH/database/scripts/database_job.sql"
	
	checkJavaInstallation
    $ANT_HOME/bin/ant -f data_build.xml database_job > $MY_PATH/logs/assign_user.log 2> $MY_PATH/logs/assign_user.err.log
	rm $MY_PATH/database/scripts/database_job.sql
	cd $MY_PATH
	
	progressBar 100 "Done!"
	sleep 2

    errorHandler $LINENO "Assign User to Project" $MY_PATH/logs/assign_user.log $MY_PATH/logs/assign_user.err.log

}


# ==================================================================================================
# repairInstallation() - Automatically repair i2b2 installation
# ==================================================================================================

repairInstallation() {

	updateBackTitle
	
	#TODO: Pruefen, ob HIVE und PM schon geladen sind.

    dialog --colors --backtitle "$BACKTITLE" --title " Repair i2b2 software "\
           --yesno "This will remove and reinstall the i2b2 software. It will not touch the database. Please note that modifications to the configuration and source code, which have been made outside i2b2 Wizard, will be lost. Do you really want to proceed?" 8 70 
    
	SURE=${?}
    if [ $SURE = 1 ]; then  
        return;
    fi

	stopJBoss

    progressBar 0 "Deleting /i2b2src ..."
	sleep 1
	rm -r /i2b2src
	
    progressBar 25 "Deleting $JBOSS_HOME ..."
	sleep 1
	rm -r $JBOSS_HOME

	getWebserverDirectory
	progressBar 50 "Deleting $WEBSERVERDIRECTORY/admin ..."
	sleep 1

	getWebserverDirectory
	rm -r $WEBSERVERDIRECTORY/admin

    progressBar 75 "Deleting $WEBSERVERDIRECTORY/webclient ..."
	sleep 1
	rm -r $WEBSERVERDIRECTORY/webclient
		
    progressBar 100 "Done!"
	sleep 1
	
	SYSTEM_SANE=no
	
    autoInstallApps
    loadHive
	registerCells
    registerHive

    CONFIG_DIRTY=yes
	saveValues
	
}



# ==================================================================================================
# createStartStopScripts() - Creates the files start-i2b2.sh and stop-i2b2.sh
# ==================================================================================================

createStartStopScripts() {
   
    cd $MY_PATH
   	
	checkJavaInstallation 1
	
    echo "#!/bin/bash" > start-i2b2.sh
	echo "echo" >> start-i2b2.sh
	echo "echo 'NOTE: This script starts JBoss and i2b2. It will not work until you have installed i2b2 with i2b2 Wizard. To start i2b2 Wizard, run ./wizard.sh'" >> start-i2b2.sh
	echo "echo" >> start-i2b2.sh
	echo "JAVA_HOME=$JAVA_HOME" >> start-i2b2.sh
    echo "ANT_HOME=$ANT_HOME" >> start-i2b2.sh
    echo "JBOSS_HOME=$JBOSS_HOME" >> start-i2b2.sh
    echo "PATH=\$PATH:\$ANT_HOME/bin:\$JAVA_HOME/bin" >> start-i2b2.sh
    echo "export JBOSS_HOME" >> start-i2b2.sh
    echo "export ANT_HOME" >> start-i2b2.sh
    echo "export JAVA_HOME" >> start-i2b2.sh
    echo "rm $JBOSS_LOG" >> start-i2b2.sh
    echo "$JBOSS_HOME/bin/standalone.sh" >> start-i2b2.sh
    
    echo "#!/bin/bash" > stop-i2b2.sh
    echo "JAVA_HOME=$JAVA_HOME" >> stop-i2b2.sh
    echo "ANT_HOME=$ANT_HOME" >> stop-i2b2.sh
    echo "JBOSS_HOME=$JBOSS_HOME" >> stop-i2b2.sh
    echo "PATH=\$PATH:\$ANT_HOME/bin:\$JAVA_HOME/bin" >> stop-i2b2.sh
    echo "export JBOSS_HOME" >> stop-i2b2.sh
    echo "export ANT_HOME" >> stop-i2b2.sh
    echo "export JAVA_HOME" >> stop-i2b2.sh
    echo "$JBOSS_HOME/bin/jboss-cli.sh  --connect command=:shutdown " >> stop-i2b2.sh
    
	echo "if [ -f $JBOSS_LOG ]; 
	then rm $JBOSS_LOG 
	fi" >> stop-i2b2.sh
    
	echo "if [ -f $JBOSS_LOG_2 ]; 
	then rm $JBOSS_LOG_2 
	fi" >> stop-i2b2.sh
   
	chmod +x start-i2b2.sh
	chmod +x stop-i2b2.sh

    if [ "$USE_JBOSS_USER" = "yes" ]; then  
        cp start-i2b2.sh /home/$JBOSS_USER/
        cp stop-i2b2.sh /home/$JBOSS_USER/
        chown $JBOSS_USER:$JBOSS_USER /home/$JBOSS_USER/start-i2b2.sh
        chown $JBOSS_USER:$JBOSS_USER /home/$JBOSS_USER/stop-i2b2.sh
    fi

}


