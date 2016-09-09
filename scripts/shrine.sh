
# ==================================================================================================
# setShrineValues() - opens a form in which the user can set the Shrine parameters
# ==================================================================================================

setShrineValues() {

	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --title " Configure SHRINE Parameters "\
	    --form "Use [up] [down] to select input field, [tab] to select buttons " 0 0 0 \
	    "MySQL password for 'root':" 1 4 "$MYSQL_ROOT_PASS" 1 37 35 0\
	    "MySQL password for 'shrine':" 2 4 "$MYSQL_SHRINE_PASS" 2 37 35 0\
		"SPIN keystore password:" 4 4 "$KEYSTORE_PASSWORD" 4 37 35 0\
		"SPIN keystore institute:" 5 4 "$KEYSTORE_HUMAN" 5 37 35 0\
		"SPIN keystore city:" 6 4 "$KEYSTORE_CITY" 6 37 35 0\
		"SPIN keystore state:" 7 4 "$KEYSTORE_STATE" 7 37 35 0\
		"SPIN keystore country:" 8 4 "$KEYSTORE_COUNTRY" 8 37 35 0\
		"SHRINE node name:" 10 4 "$SHRINE_NODENAME" 10 37 35 0\
	    2>$TEMPVAR
	    
	if [ ${?} -ne 0 ]; then return; fi   

	
	MYSQL_ROOT_PASS=`sed -n 1p $TEMPVAR`
    MYSQL_SHRINE_PASS=`sed -n 2p $TEMPVAR`
    KEYSTORE_PASSWORD=`sed -n 3p $TEMPVAR`
    KEYSTORE_HUMAN=`sed -n 4p $TEMPVAR`
    KEYSTORE_CITY=`sed -n 5p $TEMPVAR`
    KEYSTORE_STATE=`sed -n 6p $TEMPVAR`
    KEYSTORE_COUNTRY=`sed -n 7p $TEMPVAR`
    SHRINE_NODENAME=`sed -n 8p $TEMPVAR`
   
    SYSTEM_SANE=no

}


# ==================================================================================================
# installShrine() - installs SHRINE
# ==================================================================================================

# Parameters: force (forces the download of files if force=1)

installShrine() {

	stopJBoss
	stopTomcat
	updateBackTitle
	
	# Check if 'mysql-server' is installed:
	
	INS_MYSQL=`aptitude search '~i ^mysql-server$'`
	
	if [ "$INS_MYSQL" = "" ]; then
		updateBackTitle
		
		dialog --colors --backtitle "$BACKTITLE" --msgbox "The package 'mysql-server' is not installed. You have\nto do this manually by running 'apt-get install\nmysql-server'. Aborting ..." 7 60
		
		exitHandler
	fi


#	autoPackageInstall verbose 'subversion'
#	autoPackageInstall verbose 'maven'
#	autoPackageInstall verbose 'yum'
#	autoPackageInstall verbose 'wget'
#	autoPackageInstall verbose 'zip'
#	autoPackageInstall verbose 'unzip'

	# --------------------------------------------------------------------------------------------
	
	PATH=$PATH:/usr/lib/oracle/xe/app/oracle/product/10.2.0/server/bin:$JAVA_HOME/bin/
	export PATH
	
	ORACLE_HOME=$PATH:/usr/lib/oracle/xe/app/oracle/product/10.2.0/server/
	export ORACLE_HOME
		
	dialog --colors --backtitle "$BACKTITLE" --infobox "Fetching SHRINE from SVN ..." 5 60
	
	svn co https://open.med.harvard.edu/svn/shrine/releases/1.18.2/code/install/i2b2-1.7 quick_install

	cd quick_install

	if [ "$IP_ADDR" = "" ]; then
		getIP
	fi

	export SHRINE_IP=$IP_ADDR
	
	# --------------------------------------------------------------------------------------------
		
	# Replace all "source" commands with ".":
	
	find . -name '*.sh' -type f -exec sed -i 's/source /. /' {} \;
	find . -name '*.rc' -type f -exec sed -i 's/source /. /' {} \;
	
	# Do the same with javac:
	
	#find . -name '*.sh' -type f -exec sed -i 's/javac /$JAVA_HOME/bin/javac /' {} \;
	
	# --------------------------------------------------------------------------------------------
	
	FILE=$MY_PATH/quick_install/i2b2/install_prereqs.sh
	restoreOriginalFile $FILE
	changeInFile $FILE "yum" "#yum";
	
	# --------------------------------------------------------------------------------------------
	
	FILE=$MY_PATH/quick_install/shrine/install_prereqs.sh
	restoreOriginalFile $FILE
	changeInFile $FILE "yum" "#yum";
	changeInFile $FILE "service" "#service";

	# --------------------------------------------------------------------------------------------
	
	FILE=$MY_PATH/quick_install/common.rc
	restoreOriginalFile $FILE
	changeInFile $FILE "=\$ETH0_IP" "=\$IP_ADDR";
	changeInFile $FILE "ETH0_IP" "#ETH0_IP";

	# --------------------------------------------------------------------------------------------

	FILE=$MY_PATH/quick_install/i2b2/oracle/i2b2.rc
	restoreOriginalFile $FILE
	
	changeInFile $FILE "JBOSS_HOME=/opt/jboss" "JBOSS_HOME=$JBOSS_HOME";
	changeInFile $FILE "I2B2_ORACLE_SID=xe" "I2B2_ORACLE_SID=$ORA_SSID";
	changeInFile $FILE "I2B2_ORACLE_SYSTEM_PASSWORD=demouser" "I2B2_ORACLE_SYSTEM_PASSWORD=$DB_SYSPASS";
	
	changeInFile $FILE "I2B2_DB_PM_USER=i2b2pm" "I2B2_DB_PM_USER=$PM_SCHEMA";
	changeInFile $FILE "I2B2_DB_PM_PASSWORD=demouser" "I2B2_DB_PM_PASSWORD=$PM_PASS";
	
	changeInFile $FILE "I2B2_DB_HIVE_USER=i2b2hive" "I2B2_DB_HIVE_USER=$HIVE_SCHEMA";
	changeInFile $FILE "I2B2_DB_HIVE_PASSWORD=demouser" "I2B2_DB_HIVE_PASSWORD=$HIVE_PASS";
	changeInFile $FILE "I2B2_DB_HIVE_JDBC_URL=jdbc:oracle:thin:@localhost:1521:${I2B2_ORACLE_SID}" "I2B2_DB_HIVE_JDBC_URL=jdbc:oracle:thin:@$DB_SERVER:$DB_PORT:${I2B2_ORACLE_SID}";
	
	changeInFile $FILE "I2B2_DB_ONT_PASSWORD=demouser" "I2B2_DB_ONT_PASSWORD=i2b2metadata";
	changeInFile $FILE "I2B2_DB_ONT_JDBC_URL=jdbc:oracle:thin:@localhost:1521:${I2B2_ORACLE_SID}" "I2B2_DB_ONT_JDBC_URL=jdbc:oracle:thin:@$DB_SERVER:$DB_PORT:${I2B2_ORACLE_SID}";
	
	changeInFile $FILE "I2B2_DB_SHRINE_ONT_JDBC_URL=jdbc:oracle:thin:@localhost:1521:${I2B2_ORACLE_SID}" "I2B2_DB_SHRINE_ONT_JDBC_URL=jdbc:oracle:thin:@$DB_SERVER:$DB_PORT:${I2B2_ORACLE_SID}";

	# --------------------------------------------------------------------------------------------

	FILE=$MY_PATH/quick_install/shrine/shrine.rc
	restoreOriginalFile $FILE
	changeInFile $FILE "=\$SHRINE_IP" "=$IP_ADDR";
	
	# --------------------------------------------------------------------------------------------
	
	chmod -R +x *.sh
	
	/bin/sh ./vm-install.sh
		
	exit 1








# ========================================================================================================================

	stopJBoss
	stopTomcat
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Preparing SHRINE installation ..." 5 60
	
	if [ "$IP_ADDR" = "" ]; then
		getIP
	fi
	
	export SHRINE_IP=$IP_ADDR
	export I2B2_HIVE_IP=$IP_ADDR:9090
	
#	loadBoston 1	# Load Boston Demodata if it's not loaded, yet.
	
	# Check if 'mysql-server' is installed:
	
	INS_MYSQL=`aptitude search '~i ^mysql-server$'`
	
	if [ "$INS_MYSQL" = "" ]; then
		updateBackTitle
		
		dialog --colors --backtitle "$BACKTITLE" --msgbox "The package 'mysql-server' is not installed. You have\nto do this manually by running 'apt-get install\nmysql-server'. Aborting ..." 7 60
		
		exitHandler
	fi
	
	# Install different packages:
	
#	autoPackageInstall verbose 'subversion'
#	autoPackageInstall verbose 'maven'
#	autoPackageInstall verbose 'yum'


	# Fetch SHRINE von svn:
	
    if ([ "$1" = "1" ] || [ ! -d "$MY_PATH/shrine_install" ]); then  
		updateBackTitle
		
		dialog --colors --backtitle "$BACKTITLE" --infobox "Fetching SHRINE from SVN ..." 5 60
		
#		svn co https://open.med.harvard.edu/svn/shrine/releases/1.14 $MY_PATH/shrine_install/ > $MY_PATH/logs/shrine_svn.log 2> $MY_PATH/logs/shrine_svn.err.log

		# Will not work, shows false-positives:
		#errorHandler $LINENO "Fetch SHRINE from SVN" $MY_PATH/logs/shrine_svn.log $MY_PATH/logs/shrine_svn.err.log

	fi
	
	#dialog --colors --backtitle "$BACKTITLE" --infobox "Building SHRINE with Maven (be patient) ..." 5 60

	
#	mvn install > $MY_PATH/logs/shrine_maven.log 2> $MY_PATH/logs/shrine_maven.err.log

	# Will not work, shows false-positives:
	#errorHandler $LINENO "Build SHRINE with Maven" $MY_PATH/logs/shrine_maven.log $MY_PATH/logs/shrine_maven.err.log

	FILE=$MY_PATH/shrine_install/code/install/i2b2/i2b2.rc
	
	restoreOriginalFile $FILE
	changeInFile $FILE "JBOSS_HOME=/opt/jboss" "JBOSS_HOME=$JBOSS_HOME";
	changeInFile $FILE "I2B2_ORACLE_SID=xe" "I2B2_ORACLE_SID=$ORA_SSID";
	changeInFile $FILE "I2B2_ORACLE_SYSTEM_PASSWORD=demouser" "I2B2_ORACLE_SYSTEM_PASSWORD=$DB_SYSPASS";
	
	changeInFile $FILE "I2B2_ORACLE_PM_USER=i2b2pm" "I2B2_ORACLE_PM_USER=$PM_SCHEMA";
	changeInFile $FILE "I2B2_ORACLE_PM_PASSWORD=demouser" "I2B2_ORACLE_PM_PASSWORD=$PM_PASS";
	
	changeInFile $FILE "I2B2_ORACLE_HIVE_USER=i2b2hive" "I2B2_ORACLE_HIVE_USER=$HIVE_SCHEMA";
	changeInFile $FILE "I2B2_ORACLE_HIVE_PASSWORD=demouser" "I2B2_ORACLE_HIVE_PASSWORD=$HIVE_PASS";
	changeInFile $FILE "I2B2_ORACLE_HIVE_JDBC_URL=jdbc:oracle:thin:@localhost:1521:${I2B2_ORACLE_SID}" "I2B2_ORACLE_HIVE_JDBC_URL=jdbc:oracle:thin:@$DB_SERVER:$DB_PORT:${I2B2_ORACLE_SID}";
	
	changeInFile $FILE "I2B2_ORACLE_ONT_PASSWORD=demouser" "I2B2_ORACLE_ONT_PASSWORD=i2b2metadata";
	changeInFile $FILE "I2B2_ORACLE_ONT_JDBC_URL=jdbc:oracle:thin:@localhost:1521:${I2B2_ORACLE_SID}" "I2B2_ORACLE_ONT_JDBC_URL=jdbc:oracle:thin:@$DB_SERVER:$DB_PORT:${I2B2_ORACLE_SID}";
	
	changeInFile $FILE "I2B2_ORACLE_SHRINE_ONT_JDBC_URL=jdbc:oracle:thin:@localhost:1521:${I2B2_ORACLE_SID}" "I2B2_ORACLE_SHRINE_ONT_JDBC_URL=jdbc:oracle:thin:@$DB_SERVER:$DB_PORT:${I2B2_ORACLE_SID}";
		

	cd $MY_PATH/shrine_install/code/install/
	
	chmod +x vm-install.sh
	./vm-install.sh		
		
	exit 1
	
	
	#Create database entries in $HIVE_SCHEMA tables:
	
	cd $MY_PATH/shrine_install/code/install/i2b2/
	updateBackTitle
		
	dialog --colors --backtitle "$BACKTITLE" --infobox "Cleaning $HIVE_SCHEMA ..." 5 60
	
	
	$ORACLE_HOME/bin/sqlplus $HIVE_SCHEMA/$HIVE_PASS@$ORA_SSID < clean_hive.sql > $MY_PATH/logs/clean_hive.log 2> $MY_PATH/logs/clean_hive.err.log
	
	errorHandler $LINENO "Clean $HIVE_SCHEMA " $MY_PATH/logs/clean_hive.log $MY_PATH/logs/clean_hive.err.log
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Creating database entries in $HIVE_SCHEMA tables ..." 5 60

	#This one will fail on recent SHRINE version:
	
	FILE=$MY_PATH/shrine_install/code/install/i2b2/skel/configure_hive_db_lookups.sql
	
	changeInFile $FILE "I2B2_DOMAIN_ID" "$HIVE_ID";
	changeInFile $FILE "I2B2_ORACLE_SHRINE_ONT_USER" "shrine_ont";
	changeInFile $FILE "I2B2_ORACLE_SHRINE_ONT_DATASOURCE_NAME" "i2b2metadata";
	changeInFile $FILE "I2B2_ORACLE_CRC_USER" "i2b2demodata";
	changeInFile $FILE "I2B2_ORACLE_CRC_DATASOURCE_NAME" "$HIVE_ID";
	
	$ORACLE_HOME/bin/sqlplus $HIVE_SCHEMA/$HIVE_PASS@$ORA_SSID < configure_hive_db_lookups.sql > $MY_PATH/logs/shrine_lookup.log 2> $MY_PATH/logs/shrine_lookup.err.log
	
	errorHandler $LINENO "Create database entries in $HIVE_SCHEMA tables" $MY_PATH/logs/shrine_lookup.log $MY_PATH/logs/shrine_lookup.err.log

	updateBackTitle

	#Register JBoss datasource for the ONT cell:

	PROJ_NAME="Shrine"
	PROJ_NAME_NOSPACES=`echo $PROJ_NAME | sed -e "s/ //g"`
	DB_PASS="demouser"
	#DB_CONNECTIONSTRING="$DB_SERVER:$DB_PORT:$ORA_SSID"
	DB_USER="shrine_ont"
	
	SHRINEONTISREGISTERED=`cat $MY_PATH/config/ds-config/$PRODUCT_VERSION/$DBTYPE/ont-ds.xml | grep '<!--'"$PROJ_NAME"'START-->'`
	
	if [ "$SHRINEONTISREGISTERED" = "" ]; then # Only if it's not registered yet!
	
		cat $MY_PATH/config/ds-config/inserts/$PRODUCT_VERSION/$DBTYPE/generic-ont-ds.ins | sed -e 's/PROJECTNAME/'"$PROJ_NAME"'/g;s/NOSPACES/'"$PROJ_NAME_NOSPACES"'/g;s/DBUSER/'"$DB_USER"'/g;s/DBPASS/'"$DB_PASS"'/g;s/DBCONNECTION/'"$DB_CONNECTIONSTRING"'/g' > $MY_PATH/config/ds-config/inserts/'"$PRODUCT_VERSION"'/'"$DBTYPE"'/generic-ont-ds.tmp
		mv $MY_PATH/config/ds-config/$PRODUCT_VERSION/$DBTYPE/ont-ds.xml $MY_PATH/config/ont-ds.old
		cat $MY_PATH/config/ont-ds.old | sed -e '/<!--WIZARDINSERT-->/r '"$MY_PATH"'/config/ds-config/inserts/'"$PRODUCT_VERSION"'/'"$DBTYPE"'/generic-ont-ds.tmp' > $MY_PATH/config/ds-config/$PRODUCT_VERSION/$DBTYPE/ont-ds.xml    
		rm $MY_PATH/config/ont-ds.old
		rm $MY_PATH/config/ds-config/inserts/'"$PRODUCT_VERSION"'/'"$DBTYPE"'/generic-ont-ds.tmp
		
	fi
	
	#Create SHRINE user:
	
	cd $MY_PATH/shrine_install/i2b2
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Cleaning $PM_SCHEMA ..." 5 60
	$ORACLE_HOME/bin/sqlplus i2b2pm/$PM_PASS@$ORA_SSID < clean_pm.sql > $MY_PATH/logs/clean_pm.log 2> $MY_PATH/logs/clean_pm.err.log
	errorHandler $LINENO "Clean I2B2PM" $MY_PATH/logs/clean_pm.log $MY_PATH/logs/clean_pm.err.log

	cd $MY_PATH/shrine_install/i2b2/skel
		
	cat configure_pm.sql | sed -e 's/https:\/\/I2B2_HIVE_IP:6443/http:\/\/'"$IP_ADDR"':6060/g' > configure_pm2.sql
	updateBackTitle
		
	dialog --colors --backtitle "$BACKTITLE" --infobox "Creating SHRINE entries in $PM_SCHEMA ..." 5 60
	$ORACLE_HOME/bin/sqlplus i2b2pm/$PM_PASS@$ORA_SSID < configure_pm2.sql > $MY_PATH/logs/shrine_pm.log 2> $MY_PATH/logs/shrine_pm.err.log
	errorHandler $LINENO "Create PM entries" $MY_PATH/logs/shrine_pm.log $MY_PATH/logs/shrine_pm.err.log
	
	SHRINEUSERISREGISTERED=`cat $MY_PATH/config/userlist.dat | grep 'shrine#shrine#demouser#'`
	if [ "$SHRINEUSERISREGISTERED" = "" ]; then # Only if he/she is not registered yet!
		
		#Append the user name to the list-file:
		touch $MY_PATH/config/userlist.dat
		echo "shrine#shrine#demouser#" >> $MY_PATH/config/userlist.dat
		
	fi

	cd $MY_PATH/shrine_install/i2b2/
	
	#Download SHRINE ontology:
	
    if ([ "$1" = "1" ] || [ ! -f "$MY_PATH/shrine_install/i2b2/Shrine.sql" ]); then  
		cd $MY_PATH/shrine_install/i2b2/
		httpDownload2 https://open.med.harvard.edu/svn/shrine/trunk/ontology/core/Shrine.sql Shrine.sql
	fi
	
	#Create database user for SHRINE ontology
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Cleaning i2b2 Ontology ..." 5 60
	$ORACLE_HOME/bin/sqlplus $DB_SYSUSER/$DB_SYSPASS@$ORA_SSID < clean_ontology.sql > $MY_PATH/logs/clean_ontology.log 2> $MY_PATH/logs/clean_ontology.err.log
	
	#Throws an error if run on a fresh system:
	#errorHandler $LINENO "Clean i2b2 Ontology" $MY_PATH/logs/clean_ontology.log $MY_PATH/logs/clean_ontology.err.log
	updateBackTitle
	
	cd $MY_PATH/shrine_install/i2b2/skel
	dialog --colors --backtitle "$BACKTITLE" --infobox "Creating database user for SHRINE ontology ..." 5 60
	
	$ORACLE_HOME/bin/sqlplus $DB_SYSUSER/$DB_SYSPASS@$ORA_SSID < ontology_create_user.sql > $MY_PATH/logs/ontology_create_user.log 2> $MY_PATH/logs/ontology_create_user.err.log

	errorHandler $LINENO "Create database user for SHRINE ontology" $MY_PATH/logs/ontology_create_user.log $MY_PATH/logs/ontology_create_user.err.log

	#Create SHRINE ontology tables
	updateBackTitle
	
	cd $MY_PATH/shrine_install/i2b2/
	dialog --colors --backtitle "$BACKTITLE" --infobox "Creating SHRINE ontology tables ..." 5 60

	$ORACLE_HOME/bin/sqlplus shrine_ont/demouser@$ORA_SSID < ontology_create_tables.sql > $MY_PATH/logs/ontology_create_tables.log 2> $MY_PATH/logs/ontology_create_tables.err.log

	errorHandler $LINENO "Create SHRINE ontology tables" $MY_PATH/logs/ontology_create_tables.log $MY_PATH/logs/ontology_create_tables.err.log

	#Insert entries into TABLE_ACCESS
	updateBackTitle
	
	cd $MY_PATH/shrine_install/i2b2/
	dialog --colors --backtitle "$BACKTITLE" --infobox "Inserting entries into TABLE_ACCESS ..." 5 60

	$ORACLE_HOME/bin/sqlplus shrine_ont/demouser@$ORA_SSID < ontology_table_access.sql > $MY_PATH/logs/ontology_table_access.log 2> $MY_PATH/logs/ontology_table_access.err.log

	errorHandler $LINENO "Insert entries into TABLE_ACCESS" $MY_PATH/logs/ontology_table_access.log $MY_PATH/logs/ontology_table_access.err.log
	
	#Load SHRINE ontology
	updateBackTitle
	
	cd $MY_PATH/shrine_install/i2b2/
	dialog --colors --backtitle "$BACKTITLE" --infobox "Loading SHRINE ontology ..." 5 60

	$ORACLE_HOME/bin/sqlplus shrine_ont/demouser@$ORA_SSID < Shrine.sql > $MY_PATH/logs/shrine_ontology_load.log 2> $MY_PATH/logs/shrine_ontology_load.err.log

	errorHandler $LINENO "Load SHRINE ontology" $MY_PATH/logs/shrine_ontology_load.log $MY_PATH/logs/shrine_ontology_load.err.log

	#Create shrine_query_history (MySQL stuff):
	
	cd $MY_PATH/shrine_install/shrine/
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Creating shrine_query_history ..." 5 60

	sed -e "s/by 'shrine'/by '$MYSQL_SHRINE_PASS'/g" < mysql.sql > mysql2.sql
	
	mysql -u root -p"$MYSQL_ROOT_PASS" < mysql2.sql > $MY_PATH/logs/create_shrine_query_history.log 2> $MY_PATH/logs/create_shrine_query_history.err.log

	errorHandler $LINENO "Create shrine_query_history" $MY_PATH/logs/create_shrine_query_history.log $MY_PATH/logs/create_shrine_query_history.err.log

    if ([ "$1" = "1" ] || [ ! -f "$MY_PATH/shrine_install/shrine/request-response-data-create.sql" ]); then  
		httpDownload2 https://open.med.harvard.edu/svn/shrine/releases/1.10/code/adapter/src/main/resources/request-response-data-create.sql request-response-data-create.sql
	fi
	
	updateBackTitle
		
	dialog --colors --backtitle "$BACKTITLE" --infobox "Executing request-response-data-create.sql ..." 5 60

	mysql -u shrine -p"$MYSQL_SHRINE_PASS" -D shrine_query_history < request-response-data-create.sql > $MY_PATH/logs/request-response-data-create.log 2> $MY_PATH/logs/request-response-data-create.err.log

	errorHandler $LINENO "Execute request-response-data-create.sql" $MY_PATH/logs/request-response-data-create.log $MY_PATH/logs/request-response-data-create.err.log
	
	if ([ "$1" = "1" ] || [ ! -f "$MY_PATH/shrine_install/shrine/create_broadcaster_audit_table.sql" ]); then  
		httpDownload2 https://open.med.harvard.edu/svn/shrine/releases/1.10/code/broadcaster-aggregator/src/main/resources/create_broadcaster_audit_table.sql create_broadcaster_audit_table.sql
	fi
	
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Executing create_broadcaster_audit_table.sql ..." 5 60

	mysql -u shrine -p"$MYSQL_SHRINE_PASS" -D shrine_query_history < create_broadcaster_audit_table.sql > $MY_PATH/logs/create_broadcaster_audit_table.log 2> $MY_PATH/logs/create_broadcaster_audit_table.err.log

	errorHandler $LINENO "Execute create_broadcaster_audit_table.sql" $MY_PATH/logs/create_broadcaster_audit_table.log $MY_PATH/logs/create_broadcaster_audit_table.err.log
	
	SPIN setup:
	
	cd $MY_PATH/shrine_install/shrine/
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Installing SPIN (creating certificates) ..." 5 60

	rm -rf $MY_PATH/.spin
	mkdir $MY_PATH/.spin/
	mkdir $MY_PATH/.spin/conf

	export KEYSTORE_FILE="$MY_PATH/.spin/conf/shrine.keystore"
	export KEYSTORE_FILE2=`echo $KEYSTORE_FILE | sed -e 's,\/,\\\/,g'`
	export KEYSTORE_ALIAS="$IP_ADDR"
	export KEYSTORE_PASSWORD="$KEYSTORE_PASSWORD"
	export KEYSTORE_HUMAN="$KEYSTORE_HUMAN" 
	export KEYSTORE_CITY="$KEYSTORE_CITY"
	export KEYSTORE_STATE="$KEYSTORE_STATE"
	export KEYSTORE_COUNTRY="$KEYSTORE_COUNTRY"

	./ssl_keytool.sh -generate > $MY_PATH/logs/ssl_keytool.log 2> $MY_PATH/logs/ssl_keytool.err.log
	mv $KEYSTORE_ALIAS.cer $MY_PATH/.spin/conf/ 		
	
	sed -e 's/KEYSTORE_FILE/'"$KEYSTORE_FILE2"'/g' < skel/keystore.xml > keystore.xml.1
	sed -e 's/KEYSTORE_PASSWORD/'"$KEYSTORE_PASSWORD"'/g' < keystore.xml.1 > keystore.xml.2
	sed -e 's/KEYSTORE_ALIAS/'"$KEYSTORE_ALIAS"'/g' < keystore.xml.2 > keystore.xml.3 

	cp keystore.xml.3 $MY_PATH/.spin/conf/keystore.xml 
	rm keystore.xml.1 keystore.xml.2 keystore.xml.3

	export SHRINE_IP=$IP_ADDR
	export I2B2_HIVE_IP=$IP_ADDR:9090
	
	sed -e 's/SHRINE_IP/'"$IP_ADDR"'/g' < skel/routingtable.xml > $MY_PATH/.spin/conf/routingtable.xml
	
	cd $MY_PATH/shrine_install/shrine/

	export SHRINE_HOME=$MY_PATH/shrine
	export SHRINE_TOMCAT_HOME=$SHRINE_HOME/tomcat
	export SHRINE_TOMCAT_SERVER_CONF=$SHRINE_TOMCAT_HOME/conf/server.xml
	export SHRINE_TOMCAT_APP_CONF=$SHRINE_TOMCAT_HOME/conf/Catalina/localhost/shrine.xml
			
	if ([ "$1" = "1" ] || [ ! -f "$MY_PATH/shrine_install/shrine/apache-tomcat-6.0.32.zip" ]); then  
		httpDownload2 https://archive.apache.org/dist/tomcat/tomcat-6/v6.0.32/bin/apache-tomcat-6.0.32.zip apache-tomcat-6.0.32.zip
	fi

	rm -rf $SHRINE_TOMCAT_HOME
	unzip -q apache-tomcat-6.0.32.zip -d $SHRINE_HOME  > $MY_PATH/logs/unzip_tomcat.log
	mv $SHRINE_HOME/apache-tomcat-6.0.32 $SHRINE_TOMCAT_HOME

	if ([ "$1" = "1" ] || [ ! -f "$MY_PATH/shrine_install/shrine/shrine-war-1.10.war" ]); then  
		httpDownload2 http://repo.open.med.harvard.edu/nexus/content/groups/public/net/shrine/shrine-war/1.10/shrine-war-1.10.war shrine-war-1.10.war
	fi
		
	rm -rf replaceFileInZip
	mkdir  replaceFileInZip

	cp skel/applicationContext.* replaceFileInZip/.
	mkdir -p replaceFileInZip/WEB-INF/classes/net/shrine

	cp shrine-war-1.10.war replaceFileInZip/.
	mv replaceFileInZip/applicationContext.xml replaceFileInZip/WEB-INF/classes/net/shrine/applicationContext.xml

	cd replaceFileInZip

	zip -r shrine-war-1.10.war WEB-INF  > $MY_PATH/logs/zip_shrine_war.log
	cp shrine-war-1.10.war $SHRINE_TOMCAT_HOME/webapps/shrine.war
	cd ..
	
	###
	
	if ([ "$1" = "1" ] || [ ! -f "$MY_PATH/shrine_install/shrine/shrine-proxy-1.10.war" ]); then
		updateBackTitle
		  
		dialog --colors --backtitle "$BACKTITLE" --infobox "Downloading and configuring SHRINE proxy ..." 5 60
		httpDownload2 http://repo.open.med.harvard.edu/nexus/content/repositories/releases/net/shrine/shrine-proxy/1.10/shrine-proxy-1.10.war shrine-proxy-1.10.war
	fi

	cp shrine-proxy-1.10.war $SHRINE_TOMCAT_HOME/webapps/shrine-proxy.war

	###

	cd $MY_PATH/shrine_install/shrine/
	
	if ([ "$1" = "1" ] || [ ! -d "$MY_PATH/shrine_install/shrine/shrine-webclient" ]); then 
		updateBackTitle
		 
		dialog --colors --backtitle "$BACKTITLE" --infobox "Downloading SHRINE web client (from svn release) ..." 5 60
		rm -rf shrine-webclient
		
		svn export --quiet https://open.med.harvard.edu/svn/shrine/releases/1.10/code/shrine-webclient/ shrine-webclient > $MY_PATH/logs/shrine_svn.log 2> $MY_PATH/logs/shrine_svn.err.log
		
		errorHandler $LINENO "Download SHRINE webclient via SVN" $MY_PATH/logs/shrine_svn.log $MY_PATH/logs/shrine_svn.err.log
	fi
		
	###

	if ([ "$1" = "1" ] || [ ! -f "$MY_PATH/shrine_install/shrine/AdapterMappings.xml" ]); then
		updateBackTitle 
		
		dialog --colors --backtitle "$BACKTITLE" --infobox "Downloading AdapterMappings.xml for the Boston Demodata dataset ..." 5 60
		httpDownload2 https://open.med.harvard.edu/svn/shrine/releases/1.10/ontology/i2b2/AdapterMappings.xml AdapterMappings.xml
	fi
	
	cp AdapterMappings.xml $MY_PATH/.spin/conf/

	###
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Configuring Tomcat $SHRINE_TOMCAT_SERVER_CONF ..." 5 60
	
	cp $SHRINE_TOMCAT_SERVER_CONF $SHRINE_TOMCAT_SERVER_CONF.default
	
	sed -e 's/KEYSTORE_FILE/'"$KEYSTORE_FILE2"'/g' < skel/tomcat_server.xml > tomcat_server.xml.tmp
	sed -e 's/KEYSTORE_PASSWORD/'"$KEYSTORE_PASSWORD"'/g' < tomcat_server.xml.tmp > $SHRINE_TOMCAT_SERVER_CONF

	rm tomcat_server.xml.tmp

	###
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Configuring shrine.xml ..." 5 60
	
	mkdir -p $SHRINE_TOMCAT_HOME/conf/Catalina/localhost

	sed -e 's/I2B2_HIVE_IP/'"$I2B2_HIVE_IP"'/g' < skel/shrine.xml > shrine.xml.tmp
	sed -e 's/SHRINE_IP/'"$SHRINE_IP"'/g;s/MySHRINE/'"$SHRINE_NODENAME"'/g' < shrine.xml.tmp > $SHRINE_TOMCAT_APP_CONF
	
	rm shrine.xml.tmp

	###
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Configuring SHRINE web client ..." 5 60

	cd $MY_PATH/shrine_install/shrine/
	
	cp shrine-webclient/i2b2_config_data.js shrine-webclient/i2b2_config_data.js.default 
	cp shrine-webclient/js-i2b2/cells/SHRINE/cell_config_data.js   shrine-webclient/js-i2b2/cells/SHRINE/cell_config_data.js.default

	sed -e 's/I2B2_HIVE_IP/'"$I2B2_HIVE_IP"'/g' < skel/i2b2_config_data.js > shrine-webclient/i2b2_config_data.js
	sed -e 's/SHRINE_IP/'"$SHRINE_IP"'/g' < skel/cell_config_data.js > shrine-webclient/js-i2b2/cells/SHRINE/cell_config_data.js

	cp -a shrine-webclient $SHRINE_TOMCAT_HOME/webapps/

	###

	chmod +x $SHRINE_TOMCAT_HOME/bin/*.sh
	
	buildSource
}

# ==================================================================================================
# showTomcatLog() 
# ==================================================================================================

showTomcatLog() {
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --tailbox $MY_PATH/shrine/tomcat/logs/shrine.log 0 0
}


# ==================================================================================================
# startShrine()
# ==================================================================================================

startShrine() {

	###updateBackTitle
	startJBoss

	getTomcatStatus
    if [ "$TOMCATSTATUS" = "1" ]; then  
       stopTomcat
    fi    
		  
    setFilePermissions
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Starting SHRINE ..." 5 60

    if [ -f "$MY_PATH/shrine/tomcat/logs/shrine.log" ]; then  
        rm $MY_PATH/shrine/tomcat/logs/shrine.log
    fi

	
	export HOME=$MY_PATH

	$MY_PATH/shrine/tomcat/bin/startup.sh & > $MY_PATH/logs/tomcat_start.log 2> $MY_PATH/logs/tomcat_start.err.log
	
	TMP_STARTSHRINE=""
    COUNTER=0

	while [ ! -f $MY_PATH/shrine/tomcat/logs/shrine.log ]; do
		if [ "$COUNTER" = 100 ]; then  
			COUNTER=0
		fi
		COUNTER=$(( $COUNTER + 1 ))
		progressBar $COUNTER "Starting Tomcat (waiting for logfile creation) ..."
		sleep 1
	done    

	while [ "$TMP_STARTSHRINE" = "" ]; do
		TMP_STARTSHRINE=`cat $MY_PATH/shrine/tomcat/logs/shrine.log | grep 'Node is ONLINE'`
		if [ "$COUNTER" = 100 ]; then  
			COUNTER=0
		fi
		COUNTER=$(( $COUNTER + 1 ))
		progressBar $COUNTER "Starting Tomcat ..."
		sleep 1
	done

	progressBar 100 "Tomcat started!"
	sleep 2
  
    updateBackTitle
    setFilePermissions
}

