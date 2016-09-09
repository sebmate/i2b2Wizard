
# If the script does not detect the Java path, it can be set here manually:
# JAVA_HOME=/usr/lib/jvm/java-openjdk

# Application paths - where the applications get expanded to:
BASE_APPDIR=/opt

# i2b2 <= 1.6
#JBOSS_HOME=$BASE_APPDIR/jboss-4.2.2.GA
#ANT_HOME=$BASE_APPDIR/apache-ant-1.6.5
#JBOSS_LOG=$JBOSS_HOME/standalone/log/boot.log
#JBOSS_LOG_2=$JBOSS_HOME/standalone/log/server.log

# i2b2 >= 1.7
JBOSS_HOME=$BASE_APPDIR/jboss-as-7.1.1.Final
ANT_HOME=$BASE_APPDIR/apache-ant-1.8.2
JBOSS_LOG=$JBOSS_HOME/standalone/log/boot.log
JBOSS_LOG_2=$JBOSS_HOME/standalone/log/server.log


# ==================================================================================================
# getWebserverDirectory() 
# ==================================================================================================

getWebserverDirectory() {
	WEBSERVERDIRECTORY=/var/www/html
	export WEBSERVERDIRECTORY=$WEBSERVERDIRECTORY
}   


# ==================================================================================================
# prepareWebserverDirectory() 
# ==================================================================================================

prepareWebserverDirectory() {
    
	getWebserverDirectory
	
	if [ ! -d $WEBSERVERDIRECTORY ]; then  
        mkdir $WEBSERVERDIRECTORY
    fi

    if [ ! -d "$WEBSERVERDIRECTORY/webclient" ]; then  
        cd $I2B2_SRC
        mv webclient $WEBSERVERDIRECTORY
        mv admin $WEBSERVERDIRECTORY
    fi

}   



# ==================================================================================================
# setFilePermissions() - Sets the file permissions for i2b2src and the jboss directory
# ==================================================================================================

setFilePermissions() {

    if ([ "$USE_JBOSS_USER" = "yes" ] && [ -d "$I2B2_SRC" ] && [ -d "$JBOSS_HOME" ]); then  

        chown -R $JBOSS_USER:$JBOSS_USER $JBOSS_HOME
        chown -R $JBOSS_USER:$JBOSS_USER $I2B2_SRC

        chmod -R ug+r+w $JBOSS_HOME
        chmod -R ug+r+w $I2B2_SRC

        # To allow access to the source code over a SSHFS (Fuse) file system:
        chmod -R ugo+r+w $JBOSS_HOME
        chmod -R ugo+r+w $I2B2_SRC
        
    fi
}



# ==================================================================================================
# installAnt() - Installs Ant 1.6.5 from a ZIP file
# ==================================================================================================

installAnt() {

	cd $MY_PATH/packages

	httpDownloadWizard $MY_PATH/packages/apache-ant-1.6.5-bin.zip https://archive.apache.org/dist/ant/binaries/apache-ant-1.6.5-bin.zip 50b60129b54fc8f96a84ee60d7599188
	
	# Apache ant 1.6.5 installation: 

    if [ ! -d $ANT_HOME ]; then
		updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --infobox "Installing 'Ant' (from ZIP file) ..." 5 60
        unzip -o $MY_PATH/packages/apache-ant-1.6.5-bin.zip -d $BASE_APPDIR > $MY_PATH/logs/unzip_ant.log 2> $MY_PATH/logs/unzip_ant.err.log

    fi
	
	# Do not run the errorHandler, because this will show a false error report ...
	# errorHandler $LINENO "Install Apache ant 1.6.5" $MY_PATH/logs/unzip_ant.log $MY_PATH/logs/unzip_ant.err.log

    cd $MY_PATH 
}   
# ==================================================================================================
# installAnt182() - Installs Ant 1.8.2 from a ZIP file
# ==================================================================================================

installAnt182() {
    
	cd $MY_PATH/packages
	
	httpDownloadWizard apache-ant-1.8.2-bin.zip https://archive.apache.org/dist/ant/binaries/apache-ant-1.8.2-bin.zip e875a77c21714d36a6e445fe15d65fb2
	
	# Apache ant 1.8.2 installation: 

    if [ ! -d $ANT_HOME ]; then
		updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --infobox "Installing 'Ant' (from ZIP file) ..." 5 60
        unzip -o $MY_PATH/packages/apache-ant-1.8.2-bin.zip -d $BASE_APPDIR > $MY_PATH/logs/unzip_ant.log

    fi

	# Do not run the errorHandler, because this will show a false error report ...
	# errorHandler $LINENO "Install Apache ant 1.8.2" $MY_PATH/logs/unzip_ant.log $MY_PATH/logs/unzip_ant.err.log

    cd $MY_PATH 
}  

# ==================================================================================================
# installJBoss422GA() - Installs JBoss 4.2.2.GA from a ZIP file
# ==================================================================================================

installJBoss422GA() {
	
	cd $MY_PATH/packages
	
	httpDownloadWizard jboss-4.2.2.GA.zip http://garr.dl.sourceforge.net/sourceforge/jboss/jboss-4.2.2.GA.zip e6542028d538baec180a96a5d1e6ec3a
	
	httpDownloadWizard $MY_PATH/packages/axis2.war http://archive.apache.org/dist/ws/axis2/1_1/axis2.war 91139b94e28d5a385f822775531e370b
	
    # JBoss installation:
   
    if [ ! -d $JBOSS_HOME ]; then
    	updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --infobox "Installing 'JBoss' (from ZIP file) ..." 5 60
       
        unzip -o $MY_PATH/packages/jboss-4.2.2.GA.zip -d $BASE_APPDIR > $MY_PATH/logs/unzip_jboss.log
    
        # Memory settings:
        
        FILE="$JBOSS_HOME/bin/run.conf"
        echo n | cp -i $FILE $FILE.orig
        sed -e '43,43s/-Xms128m -Xmx512m/-Xms512m -Xmx1024m/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "JBoss installation: Apply JBoss memory settings"
        
        # Change JBoss server ports:
        
        FILE="$JBOSS_HOME/server/default/deploy/jboss-web.deployer/server.xml"
        echo n | cp -i $FILE $FILE.orig
        sed -e '22,22s/8080/9090/g;39,39s/8009/9009/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "JBoss installation: Change JBoss server port"
    
        # Apache Axis2 installation:
    	updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --infobox "Installing 'Axis2' (from ZIP file) ..." 5 60
    
        mkdir $JBOSS_HOME/server/default/deploy/i2b2.war
        unzip -o $MY_PATH/packages/axis2.war -d $JBOSS_HOME/server/default/deploy/i2b2.war/ > $MY_PATH/logs/unzip_axis2.log
        
        # To check if Axis2 is working, go to: http://localhost:9090/i2b2/services/listServices
    
    fi   
   
}   


# ==================================================================================================
# installJBoss711() - Installs JBoss 7.1.1 from a ZIP file
# ==================================================================================================

installJBoss711() {

	cd $MY_PATH/packages
	
	httpDownloadWizard $MY_PATH/packages/jboss-as-7.1.1.Final.zip http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip 175c92545454f4e7270821f4b8326c4e

	httpDownloadWizard $MY_PATH/packages/axis2-1.6.2-war.zip http://archive.apache.org/dist/axis/axis2/java/core/1.6.2/axis2-1.6.2-war.zip 7c1ef0245c4e13ac04cee47583bc5406
	
    # JBoss installation:
   
    if [ ! -d $JBOSS_HOME ]; then
    	updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --infobox "Installing 'JBoss' (from ZIP file) ..." 5 60
       
        unzip -o $MY_PATH/packages/jboss-as-7.1.1.Final.zip -d $BASE_APPDIR > $MY_PATH/logs/unzip_jboss.log
    
        # Memory settings:
        
        FILE="$JBOSS_HOME/bin/appclient.conf"
        echo n | cp -i $FILE $FILE.orig
        sed -e '45,45s/-Xms64m -Xmx512m/-Xms512m -Xmx1024m/g' <$FILE.orig >$FILE 
		checkFileChanged $FILE.orig $FILE "JBoss installation: Apply JBoss memory settings"

        # Change JBoss server ports:
        FILE="$JBOSS_HOME/standalone/configuration/standalone.xml"
        echo n | cp -i $FILE $FILE.orig
        sed -e '296,296s/8080/9090/g;295,295s/8009/9009/g' <$FILE.orig >$FILE.tmp 
		checkFileChanged $FILE.orig $FILE.tmp "JBoss installation: Change JBoss server port"

		# Binding JBoss AS 7 to all interfaces (https://stackoverflow.com/questions/6853409/binding-jboss-as-7-to-all-interfaces): 
        sed -e '280,280s/<inet-address value=\"\${jboss.bind.address:127.0.0.1}\"\/>/\<any-address\/\>/g' <$FILE.tmp >$FILE 
		checkFileChanged $FILE.tmp $FILE "JBoss installation: Allow JBoss 7 to bind to all network interfaces"
		
        # Apache Axis2 installation:
    	updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --infobox "Installing 'Axis2' (from ZIP file) ..." 5 60
    
        mkdir $JBOSS_HOME/standalone/deployments/i2b2.war
		touch $JBOSS_HOME/standalone/deployments/i2b2.war.dodeploy
				
		cd $MY_PATH
		
		mkdir temp
		unzip -o $MY_PATH/packages/axis2-1.6.2-war.zip -d $MY_PATH/temp/ > $MY_PATH/logs/unzip_axis2.log
    	unzip -o $MY_PATH/temp/axis2.war -d $JBOSS_HOME/standalone/deployments/i2b2.war > $MY_PATH/logs/unzip_axis2.log
		
		rm -r temp
				
        # To check if Axis2 is working, go to: http://localhost:9090/i2b2/services/listServices
    
		cd $MY_PATH
    fi   
}   


# ==================================================================================================
# InstallPostgreSQL91: Installings 'PostgreSQL 9.1' with package manager 
# ==================================================================================================

# OBSOLETE - DO NOT USE

installPostgreSQL91() {

	autoPackageInstall verbose 'postgresql-9.1'
	
	updateBackTitle
	dialog --colors --backtitle "$BACKTITLE" --infobox "Configuring 'PostgreSQL' ..." 5 60

	sudo -u postgres psql -c "alter user $DB_SYSUSER with password '$DB_SYSPASS';"  > $MY_PATH/logs/config_postgres1.log 2> $MY_PATH/logs/config_postgres1.err.log
	errorHandler $LINENO "Configure PostgreSQL system user password" $MY_PATH/logs/config_postgres1.log $MY_PATH/logs/config_postgres1.err.log

	sudo -u postgres createdb i2b2 > $MY_PATH/logs/config_postgres2.log 2> $MY_PATH/logs/config_postgres2.err.log
	errorHandler $LINENO "Create PostgreSQL 'i2b2' database" $MY_PATH/logs/config_postgres2.log $MY_PATH/logs/config_postgres2.err.log

} 


# ==================================================================================================
# InstallPostgreSQL: Installings latest 'PostgreSQL' with package manager 
# ==================================================================================================

installPostgreSQL() {

    if [ ! "$DOCKER" = "1" ]; then

    	autoPackageInstall verbose 'postgresql'

        updateBackTitle
        dialog --colors --backtitle "$BACKTITLE" --infobox "Configuring 'PostgreSQL' ..." 5 60
        sudo -u postgres psql -c "alter user $DB_SYSUSER with password '$DB_SYSPASS';"  > $MY_PATH/logs/config_postgres1.log 2> $MY_PATH/logs/config_postgres1.err.log
        errorHandler $LINENO "Configure PostgreSQL system user password" $MY_PATH/logs/config_postgres1.log $MY_PATH/logs/config_postgres1.err.log
        sudo -u postgres createdb i2b2 > $MY_PATH/logs/config_postgres2.log 2> $MY_PATH/logs/config_postgres2.err.log
        errorHandler $LINENO "Create PostgreSQL 'i2b2' database" $MY_PATH/logs/config_postgres2.log $MY_PATH/logs/config_postgres2.err.log
    fi


    if [ "$DOCKER" = "1" ]; then
        updateBackTitle
        dialog --colors --backtitle "$BACKTITLE" --infobox "Configuring 'PostgreSQL' ..." 5 60
        
        export PGPASSWORD="$DB_SYSPASS"
        psql -h $DB_SERVER -p 5432 -U $DB_SYSUSER -c "create database i2b2;"  > $MY_PATH/logs/config_postgres2.log 2> $MY_PATH/logs/config_postgres2.err.log
        
        errorHandler $LINENO "Create PostgreSQL 'i2b2' database" $MY_PATH/logs/config_postgres2.log $MY_PATH/logs/config_postgres2.err.log
    fi


} 


# ==================================================================================================
# installOracleXE10() - Installs Oracle XE 10
# ==================================================================================================

installOracleXE10() {

	cd $MY_PATH

	if [[ "$OS" =~ Windows ]]; then
		return
	fi
	
	autoPackageInstall verbose 'libc6'
	autoPackageInstall verbose 'libaio1'

	# Oracle installation:

	if [ -f /etc/redhat-release ] ; then
		INS=`rpm -qi oracle-xe-univ | grep Name`
	elif [ -f /etc/debian_version ] ; then
		INS=`aptitude search '~i ^oracle-xe-universal$'`
	fi
	
	if ([ "$INS" = ""  ] && [ "$DB_SERVER" = "localhost" ]); then  
        updateBackTitle


        # Install the required packages, the following routine can deal with RedHat and Debian flavours:
        
		if [ -f /etc/redhat-release ] ; then

			cd $MY_PATH/packages
			
			httpDownloadWizard $MY_PATH/packages/oracle-xe-univ-10.2.0.1-1.0.i386.rpm http://ftp.cs.stanford.edu/pub/fedora/6/i386/oracle-xe-univ-10.2.0.1-1.0.i386.rpm 627c23c942c62ea9ec7894b6816aec94

			dialog --colors --backtitle "$BACKTITLE" --infobox "Installing 'Oracle XE' from previously downloaded package ..." 5 60
 
			if [ ! -f $MY_PATH/packages/oracle-xe-univ-10.2.0.1-1.0.i386.rpm ]; then  
				updateBackTitle
				
				dialog --colors --backtitle "$BACKTITLE" --msgbox "The file packages/oracle-xe-univ-10.2.0.1-1.0.i386.rpm was not found. Please download the Oracle manually, put it into the packages folder and restart the installation." 10 70
			else
				rpm -ivh $MY_PATH/packages/oracle-xe-univ-10.2.0.1-1.0.i386.rpm > $MY_PATH/logs/rpm_oracle.log 2> $MY_PATH/logs/rpm_oracle.err.log
			fi
			
		elif [ -f /etc/debian_version ] ; then
		
			cd $MY_PATH/packages
			
			httpDownloadWizard $MY_PATH/packages/oracle-xe-universal_10.2.0.1-1.1_i386.deb https://oss.oracle.com/debian/dists/unstable/non-free/binary-i386/oracle-xe-universal_10.2.0.1-1.1_i386.deb 3140db681260242c6e5951edfd5c17b5

			dialog --colors --backtitle "$BACKTITLE" --infobox "Installing 'Oracle XE' from previously downloaded package ..." 5 60
 		
			if [ ! -f $MY_PATH/packages/oracle-xe-universal_10.2.0.1-1.1_i386.deb ]; then  
				updateBackTitle
				
				dialog --colors --backtitle "$BACKTITLE" --msgbox "The file packages/oracle-xe-universal_10.2.0.1-1.1_i386.deb was not found. Please download the Oracle manually, put it into the packages folder and restart the installation." 10 70
			else
				
				dpkg -i --force-architecture --force-depends $MY_PATH/packages/libaio_0.3.104-1_i386.deb > $MY_PATH/logs/dpkg_libaio.log 2> $MY_PATH/logs/dpkg_libaio.err.log
				
				dpkg -i --force-architecture --force-depends $MY_PATH/packages/oracle-xe-universal_10.2.0.1-1.1_i386.deb > $MY_PATH/logs/dpkg_oracle.log 2> $MY_PATH/logs/dpkg_oracle.err.log
			fi
		fi
		
		# It might be necessary to fix unmet dependencies:
		apt-get -y -f install > $MY_PATH/logs/fix_apt.log 2> $MY_PATH/logs/fix_apt.err.log  
				
		# Check if the installation worked:
		
		if [ -f /etc/redhat-release ] ; then
			INS=`rpm -qi oracle-xe-univ | grep Name`
		elif [ -f /etc/debian_version ] ; then
			INS=`aptitude search '~i ^oracle-xe-universal$'`
		fi
		
        if [ "$INS" = "" ]; then
            clear
            echo "Error: Oracle XE installation failed. Do you have at least 1GB of swap space?"
            echo ""
			echo "   On most Linux system you can add swap by running the following commands:"
			echo ""
			echo "   dd if=/dev/zero of=/var/swapfile bs=1M count=1100"
			echo "   mkswap /var/swapfile"
			echo "   swapon /var/swapfile"
			echo ""
	        exit 1
        fi
		
		#if [ "$SILENT" = "1" ]; then

			updateBackTitle
			dialog --colors --backtitle "$BACKTITLE" --infobox "Configuring 'Oracle XE' (this will take a while) ..." 5 60
			
			# This is known to fail in some cases:
			# Run the oracle configration script and use the default values, system-password "i2b2":
			#echo "8080\n$DB_PORT\n$DB_SYSPASS\n$DB_SYSPASS\ny\n" | /etc/init.d/oracle-xe configure > $MY_PATH/logs/oracle_configure.log 2> $MY_PATH/logs/oracle_configure.err.log  
				
			echo "8080" > $MY_PATH/config/oracle.cfg 
			echo "$DB_PORT" >> $MY_PATH/config/oracle.cfg 
			echo "$DB_SYSPASS" >> $MY_PATH/config/oracle.cfg 
			echo "$DB_SYSPASS" >> $MY_PATH/config/oracle.cfg 
			echo "y" >> $MY_PATH/config/oracle.cfg 
			echo "" >> $MY_PATH/config/oracle.cfg
			echo "" >> $MY_PATH/config/oracle.cfg
					
			/etc/init.d/oracle-xe configure < $MY_PATH/config/oracle.cfg > $MY_PATH/logs/oracle_configure.log 2> $MY_PATH/logs/oracle_configure.err.log  
			
			rm $MY_PATH/config/oracle.cfg 
			
            #else
            #	clear
            #	echo ""
            #	echo "   +--------------------------------------------------------------------+  "
            #	echo "   | Oracle XE Configuration                                            |  "
            #	echo "   | =======================                                            | | "
            #	echo "   |                                                                    | | "
            #	echo "   | i2b2 Wizard has successfully installed Oracle XE, however, the     | | "
            #	echo "   | configuration of Oracle XE has to be perfomed manually. This is    | | "
            #	echo "   | easy. All you need to do is to enter the following values into     | | "
            #	echo "   | the configuration script below:                                    | | "
            #	echo "   |                                                                    | | "
            #	echo "   |     HTTP port: 8080                                                | | "
            #	echo "   |     Database listener port: $DB_PORT                                   | |"
            #	echo "   |     Database password: $DB_SYSPASS                                        | |"
            #	echo "   |                                                                    | |"
            #	echo "   | Also answer with 'yes' (enter 'y') when it asks you if you want    | |"
            #	echo "   | to start the database on system startup.                           | |"
            #	echo "   |                                                                    | |"
            #	echo "   +--------------------------------------------------------------------+ |"
            #	echo "      --------------------------------------------------------------------+"
            #	echo ""
            #	/etc/init.d/oracle-xe configure
            #fi

		fi
    cd $MY_PATH
}


# ==================================================================================================
# restartApache() 
# ==================================================================================================

restartApache() {
    
	# Restart Apache:
	updateBackTitle
    dialog --colors --backtitle "$BACKTITLE" --infobox "Restarting Apache ..." 5 60
    /etc/init.d/apache2 restart > $MY_PATH/logs/apache_restart.log 2> $MY_PATH/logs/apache_restart.log

}   

   
# ==================================================================================================
# createJBossUser() - Creates a separate Linux user for the JBoss process
# ==================================================================================================

createJBossUser() {
   
	updateBackTitle
	
 	dialog --colors --backtitle "$BACKTITLE"  --title " Create JBoss Linux User "\
	    --form "Use [up] [down] to select input field, [tab] to select buttons " 11 70 4 \
	    "User Name (jboss):" 2 4 "$JBOSS_USER" 2 33 25 0\
	    "Password (jboss):" 3 4 "jboss" 3 33 25 0\
	    2>$TEMPVAR


	if [ ${?} -ne 0 ]; then return; fi   

    USER=`sed -n 1p $TEMPVAR`
    PASS=`sed -n 2p $TEMPVAR`

	egrep "^$USER" /etc/passwd >/dev/null
	
	if [ $? -eq 0 ]; then
		updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --msgbox "This user already exists!" 5 50
        return
        
    else
    
        stopJBoss
    	
		PASS=$(perl -e 'print crypt($ARGV[0], "password")' $PASS)
		useradd -m -s /bin/bash -p $PASS $USER
		updateBackTitle
		
        [ $? -eq 0 ] && dialog --colors --backtitle "$BACKTITLE" --msgbox "User added to system!" 5 50 || dialog --colors --backtitle "$BACKTITLE" --msgbox "Failed to add the user!" 5 50

        USE_JBOSS_USER=yes
        JBOSS_USER=$USER

        chown -R $JBOSS_USER:$JBOSS_USER $JBOSS_HOME
        setFilePermissions
	fi
}


# ==================================================================================================
# getJBossStatus() - returns the JBoss-status in $JBOSSSTATUS: 0=stopped, 1=running
# ==================================================================================================

getJBossStatus() {
   
    JBOSSSTATUS=0
    
    if [ ! -f "$JBOSS_LOG" ]; then  
        # JBoss is not running ...
	JBOSSSTATUS=$JBOSSSTATUS    	  
	return
    fi
    
    # JBoss might be running ...
    JBOSSSTATUS=1

    if [ -f "$JBOSS_LOG" ]; then  
        TMP_GETJBOSSSTATUS=`cat $JBOSS_LOG | grep 'JBoss AS 7.1.1.Final \"Brontes\" stopped'`
        if [ ! "$TMP_GETJBOSSSTATUS" = "" ]; then  
            # ... no, it is not running, but an old log-file exists
            JBOSSSTATUS=0
            rm $JBOSS_LOG
            sleep 3
        fi
    fi
	  
   JBOSSSTATUS=$JBOSSSTATUS 
}

# ==================================================================================================
# getTomcatStatus() - returns the Tomcat-status in $TOMCATSTATUS: 0=stopped, 1=running
# ==================================================================================================

getTomcatStatus() {
    
    TOMCATSTATUS=0
    
    if [ ! -f "$MY_PATH/shrine/tomcat/logs/shrine.log" ]; then  
        # Tomcat is not running ...
        TOMCATSTATUS=$TOMCATSTATUS
        return
    fi
	    
    TOMCATSTATUS=1

	TOMCATSTATUS=$TOMCATSTATUS  
}


# ==================================================================================================
# autoPackageInstall() - automatically installs a package with apt-get or yum
# ==================================================================================================

# Parameters: verbose package_name_list
# Warning: This has changed in Version > 1.9. It will try to install the full list of packages in $2.

autoPackageInstall() {

	# Install feature is not supported on Windows:
	if [[ "$OS" =~ Windows ]]; then
		return
	fi

	isSilent=$1

	shift # remove first parameter

	for i in "$@"  # iterate over the list of packages
		
		do

		# Use this case statement to replace Ubuntu-packages names with those specific to this Linux distribution.
		# If a requested package is not required for this Linux distribution, set i='' as shown in the example.
		
		case $1 in
			'original-package-name' )
				i='changed-package-name' ;;
			'original-package-name' )
				i='changed-package-name' ;;
			'UnnecessaryPackage' )
				i='' ;;
			'UnnecessaryPackage' )
				i='' ;;
			'UnnecessaryPackage' )
				i='' ;;
			'UnnecessaryPackage' )
				i='' ;;
		esac
		
		if [ ! "$i" = "" ]; then   # Do not install if it's empty.
		
			# The code below finally installs the package. It is currently designed for Debian and Redhat Linuxes and
			# it might be necessary for you to change it.
		
			if [ "$isSilent" = "verbose" ]; then
				updateBackTitle			
				dialog --colors --backtitle "$BACKTITLE" --infobox "Checking if '$i' is installed ..." 5 60
			else
				echo "Checking if '$i' is installed ..."
			fi	
			
			if [ -f /etc/redhat-release ] ; then
				INS=`yum list installed $i 2> /dev/null | grep "Installed Packages"`
				if [ "$INS" = "" ]; then
					if [ "$isSilent" = "verbose" ]; then
						updateBackTitle			
						dialog --colors --backtitle "$BACKTITLE" --infobox "Installing '$i' ..." 5 60
					else
						echo "Installing '$i' ..."
					fi	
					yum -y install $i > $MY_PATH/logs/autoPackageInstall_$i.log 2> $MY_PATH/logs/autoPackageInstall_$i.err.log
					INS=`yum list installed $i 2> /dev/null | grep "Installed Packages"`
				fi
			elif [ -f /etc/debian_version ] ; then
				A="aptitude search '~i ^$i\$'"
				INS=`eval $A 2> $MY_PATH/logs/aptitude_search_$i.err.log`
				if [ "$INS" = "" ]; then
					if [ "$isSilent" = "verbose" ]; then
						updateBackTitle			
						dialog --colors --backtitle "$BACKTITLE" --infobox "Installing '$i' ..." 5 60
					else
						echo "Installing '$i' ..."
					fi	
					apt-get -q -y install aptitude $i > $MY_PATH/logs/autoPackageInstall_$i.log 2> $MY_PATH/logs/autoPackageInstall_$i.err.log
					A="aptitude search '~i ^$i\$'"
					INS=`eval $A 2> $MY_PATH/logs/aptitude_search_$i.err.log`
				fi
			fi
			
			if [ "$INS" = "" ]; then
				if [ "$isSilent" = "verbose" ]; then
					A=$@
					updateBackTitle
					dialog --colors --backtitle "$BACKTITLE" --msgbox "Failed to install '$i' with the Linux package manager. Refresh your packages list and try again." 7 70
					clear
					exitHandler
				else
					clear
					echo "Failed to install '$i' with the Linux package manager. Refresh your packages list and try again."
					exit 1
				fi	
			fi
		fi
	done
		
	SYSTEM_SANE=no
}


# ==================================================================================================
# checkJavaInstallation()
# ==================================================================================================

# Parameters: silent

checkJavaInstallation() {
	
	# NOTE: This routine automatically tries to find JAVA_HOME. It should not be specified manually!
	
	# If JAVA_HOME is not correct, try another setting (for CentOS):
	if [ ! -f "$JAVA_HOME/bin/java" ]; then
		JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.55/jre
	fi
	
	# If JAVA_HOME is not correct, try another setting (for CentOS 6.5):
	if [ ! -f "$JAVA_HOME/bin/java" ]; then
		JAVA_HOME=/usr/lib/jvm/java-openjdk
	fi
		
	# If JAVA_HOME is not correct, try another setting (for Ubuntu 12):
	if [ ! -f "$JAVA_HOME/bin/java" ]; then
		
		JAVA_HOME=/usr/lib/jvm/java-6-openjdk-i386
	fi
	
	# If JAVA_HOME is not correct, try another setting (for Ubuntu 12):
	if [ ! -f "$JAVA_HOME/bin/java" ]; then
		
		JAVA_HOME=/usr/lib/jvm/java-7-openjdk-i386
	fi

	# If JAVA_HOME is not correct, try another setting (for Ubuntu 14 amd64):
	if [ ! -f "$JAVA_HOME/bin/java" ]; then
		
		JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
	fi
		
	# If JAVA_HOME is not correct, try another setting (for Ubuntu 10):
	if [ ! -f "$JAVA_HOME/bin/java" ]; then
		JAVA_HOME=/usr/lib/jvm/java-6-openjdk
	fi

	# If JAVA_HOME is not correct, try another setting (for Windows):
	if [ ! -f "$JAVA_HOME/bin/java" ]; then	

		# Modify if necessary:
		if [ -e "/cygdrive/c/Program Files/Java/jdk1.6.0_29/bin/java.exe" ]; then	
			JAVA_HOME='C:\Program Files\Java\jdk1.6.0_29'
			export JAVA_HOME
			return
		fi
	fi
	
	
	JAVA=$JAVA_HOME/bin
	case "$PATH" in
    	*$JAVA*) ;;
	*) PATH=$PATH:$JAVA ;;
    	esac

	JAVA_HOME=$JAVA_HOME		
	PATH=$PATH
	
	# If it's still not correct, display error message and exit:

	if [ ! "$1" = "1" ]; then
		if [ ! -f "$JAVA_HOME/bin/java" ]; then
			updateBackTitle
		
			dialog --colors --backtitle "$BACKTITLE" --title " JAVA_HOME problem " --msgbox "Could not locate Java installation in $JAVA_HOME. Please specify the correct JAVA_HOME at the top of the file  scripts/product_versions/$OS_SCRIPT_IDENTIFIER.sh." 10 80 
			clear
			#exit 1
		fi
	fi
}


# ==================================================================================================
# configureFirewall() 
# ==================================================================================================

configureFirewall() {

	updateBackTitle
	
	echo "${SSH_CLIENT%% *}"

	if [ "$SILENT" = "1" ]; then

		IP_ADDR="127.0.0.1"
		
	else

		DIAPARAM=`ifconfig | grep -B1 'inet Adresse:' | sed 's/inet Adresse://g' | awk '{ printf "%s xx", $1}' | sed 's/xx--/off/g' | sed 's/xx//g' | sed 's/off/on/1'; echo off other manual off`
		updateBackTitle
		
		dialog --colors --backtitle "$BACKTITLE" --radiolist 'Please select the network interface that is used between the Hive and Workbench (press [space] to select item):' 14 65 11 $DIAPARAM 2>$TEMPVAR
		
		RESULT=`cat $TEMPVAR`
		IP_ADDR=`echo $DIAPARAM | sed 's/^.*'"$RESULT"'//' | awk '{ printf "%s", $1}'`

		if [ "$IP_ADDR" = "manual" ]; then
			updateBackTitle
			
			dialog --colors --backtitle "$BACKTITLE" \
				   --inputbox "Please enter the IP address" 8 52 "localhost" 2>$TEMPVAR
			IP_ADDR=`cat $TEMPVAR`
		fi

	fi	
	
	IP_ADDR=$IP_ADDR

}


# ==================================================================================================
# getIP() - get the IP address
# ==================================================================================================

getIP() {

	if [ "$SILENT" = "1" ]; then
		IP_ADDR="127.0.0.1"
	
	else
	
		if [[ "$OS" =~ Windows ]]; then
			ID_ADDR=manual
		else
			
			# Test if the English returns something:
			TESTLANGUAGE=`ifconfig | grep -B1 'inet addr:' | sed 's/inet addr://g' | awk '{ printf "%s xx", $1}' | sed 's/xx--/off/g' | sed 's/xx//g' | sed 's/off/on/1'`
			
			if [[ ! "$TESTLANGUAGE" = "" ]]; then
						
				# Assume English Linux:
				DIAPARAM=`ifconfig | grep -B1 'inet addr:' | sed 's/inet addr://g' | awk '{ printf "%s xx", $1}' | sed 's/xx--/off/g' | sed 's/xx//g' | sed 's/off/on/1'; echo off other manual off`
			
			else
			
				# Assume German Linux:
				DIAPARAM=`ifconfig | grep -B1 'inet Adresse:' | sed 's/inet Adresse://g' | awk '{ printf "%s xx", $1}' | sed 's/xx--/off/g' | sed 's/xx//g' | sed 's/off/on/1'; echo off other manual off`
			
			fi
			
			updateBackTitle
			dialog --colors --backtitle "$BACKTITLE" --radiolist 'Please select the network interface that is used between the Hive and Workbench (press [space] to select item):' 14 65 11 $DIAPARAM 2>$TEMPVAR
			RESULT=`cat $TEMPVAR`

			IP_ADDR=`echo $DIAPARAM | sed 's/^.*'"$RESULT"'//' | awk '{ printf "%s", $1}'`
		fi

		if [ "$IP_ADDR" = "manual" ]; then
			updateBackTitle
			dialog --colors --backtitle "$BACKTITLE" \
				   --inputbox "Please enter the IP address that is used for the communication between the Hive and Workbench " 10 52 "localhost" 2>$TEMPVAR
			IP_ADDR=`cat $TEMPVAR`
		fi
	fi	

	saveValues

}



# ==================================================================================================
# stopJBoss() - stopps the JBoss server process
# ==================================================================================================

stopJBoss() {
	
	stopTomcat

    if [ -f "$MY_PATH/logs/jbossstop.log" ]; then  
        rm $MY_PATH/logs/jbossstop.log
    fi

    getJBossStatus
    if [ "$JBOSSSTATUS" = "0" ]; then  
        return
    fi    

    if [ "$USE_JBOSS_USER" = "yes" ]; then  
        chown -R $JBOSS_USER:$JBOSS_USER $JBOSS_HOME
        su jboss -c "$JBOSS_HOME/bin/jboss-cli.sh --connect --command=:shutdown > /home/$JBOSS_USER/jbossstop.log &"
    else
        cd $JBOSS_HOME/bin
        ./jboss-cli.sh --connect --command=:shutdown > $MY_PATH/logs/jbossstop.log 2> $MY_PATH/logs/jbossstop.log &
    fi
 
    TMP_STOPJBOSS=""
    COUNTER=0
       
	while [ "$TMP_STOPJBOSS" = "" ]; do
		
		if [ -f $JBOSS_LOG ]; then 
			TMP_STOPJBOSS=`cat $JBOSS_LOG | grep 'JBoss AS 7.1.1.Final \"Brontes\" stopped'`
		fi

		if [ "$COUNTER" = 100 ]; then  
			COUNTER=0
		fi
		COUNTER=$(( $COUNTER + 1 ))		
		progressBar $COUNTER "Stopping JBoss ..."
		sleep 1
	done
	progressBar 100 "JBoss stopped!"
	
	sleep 1

	if [ -f $JBOSS_LOG ]; then 
		rm $JBOSS_LOG 
	fi
	if [ -f $JBOSS_LOG_2 ]; then 
		rm $JBOSS_LOG_2 
	fi

	sleep 2
  	
	getJBossStatus
    updateBackTitle
    setFilePermissions
}



# ==================================================================================================
# startJBoss() - starts the JBoss server process
# ==================================================================================================

startJBoss() {

    if [ -f "$MY_PATH/logs/jbossstart.log" ]; then  
        rm $MY_PATH/logs/jbossstart.log
    fi

    getJBossStatus

    if [ $CONFIG_DIRTY = "yes" ]; then  
        buildSource $JBOSSSTATUS
    fi  

    getJBossStatus

    if [ "$JBOSSSTATUS" = "1" ]; then  
        return
    fi    

    if [ "$USE_JBOSS_USER" = "yes" ]; then  
        chown -R $JBOSS_USER:$JBOSS_USER $JBOSS_HOME
        fixTNSProblem
		su jboss -c "$JBOSS_HOME/bin/standalone.sh > /home/$JBOSS_USER/jbossstart.log &"
    else
	fixTNSProblem
        $JBOSS_HOME/bin/standalone.sh > $MY_PATH/logs/jbossstart.log &
    fi

    TMP_STARTJBOSS=""
    COUNTER=0

	while [ ! -f $JBOSS_LOG_2 ]; do

		if [ "$COUNTER" = 100 ]; then  
			COUNTER=0
		fi

		COUNTER=$(( $COUNTER + 1 ))
		progressBar $COUNTER "Starting JBoss (waiting for logfile creation) ..."
		sleep 1
	done    

	while [ "$TMP_STARTJBOSS" = "" ]; do


		TMP_STARTJBOSS=`cat $JBOSS_LOG_2 | grep 'JBoss AS 7.1.1.Final \"Brontes\" started'`
		ERRORTEST=`cat $JBOSS_LOG_2 | grep 'ERROR' | grep -v 'TimerImpl'`
		
		if [ ! "$ERRORTEST" = "" ]; then 
			updateBackTitle
			
			dialog --colors --backtitle "$BACKTITLE" --msgbox "Detected an error message in the JBoss log:\n\n$ERRORTEST\n\nPress OK to show the log." 16 90
			showJBossLog
			getJBossStatus
			return
		fi
		
		if [ "$COUNTER" = 100 ]; then  
			COUNTER=0

		fi
		
		updateBackTitle

		COUNTER=$(( $COUNTER + 1 ))
		progressBar $COUNTER "Starting JBoss ..."
		sleep 1
	done

		progressBar 100 "JBoss started!"
		sleep 2
    		updateBackTitle
    		setFilePermissions
		getJBossStatus
}

# ==================================================================================================
# showJBossLog() 
# ==================================================================================================

showJBossLog() {
	updateBackTitle
	dialog --colors --backtitle "$BACKTITLE" --tailbox $JBOSS_LOG 0 0
}

# ==================================================================================================
# stopTomcat()
# ==================================================================================================

stopTomcat() {
		
	getTomcatStatus
    if [ "$TOMCATSTATUS" = "0" ]; then  
		return
    fi    
	updateBackTitle
	
	dialog --colors --backtitle "$BACKTITLE" --infobox "Stopping SHRINE ..." 5 60
	export HOME=$MY_PATH

	$MY_PATH/shrine/tomcat/bin/shutdown.sh & > $MY_PATH/logs/tomcat_shutdown.log 2> $MY_PATH/logs/tomcat_shutdown.err.log
	
    sleep 5

    rm $MY_PATH/shrine/tomcat/logs/shrine.log

    updateBackTitle
    setFilePermissions
	getTomcatStatus
	
}

