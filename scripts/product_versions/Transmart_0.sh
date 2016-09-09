
# ==================================================================================================
# autoInstallApps() - installs the necessary applications for this Transmart version
# ==================================================================================================

autoInstallApps() {

	apt-key adv --keyserver keyserver.ubuntu.com --recv 3375DA21 && echo deb http://apt.thehyve.net/internal/ trusty main | tee /etc/apt/sources.list.d/hyve_internal.list && apt-get update

	apt-get update
	
    autoPackageInstall verbose 'UnnecessaryPackage' # Used to check if the OS script can ignore unnecessary packages.
	#autoPackageInstall verbose 'SomethingStupid' # Used to check if the OS script can detect bad package names.
	
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
	
	# These are for Transmart (by Christian):
	autoPackageInstall verbose 'make'
	autoPackageInstall verbose 'curl'
	autoPackageInstall verbose 'git'
	autoPackageInstall verbose 'openjdk-7-jdk'
	autoPackageInstall verbose 'groovy'
	autoPackageInstall verbose 'php5-cli'
	autoPackageInstall verbose 'php5-json'
	autoPackageInstall verbose 'postgresql-9.3'
	autoPackageInstall verbose 'apache2'
	autoPackageInstall verbose 'tomcat7'
	autoPackageInstall verbose 'libtcnative-1'
	autoPackageInstall verbose 'transmart-r'

    # These should already be installed, but to be sure, let's invoke the install function:
    autoPackageInstall verbose 'perl'
    autoPackageInstall verbose 'sed'
    autoPackageInstall verbose 'bc'

    SYSTEM_SANE=yes
	saveValues

}


# ==================================================================================================
# buildSource() - builds the i2b2 sourcecode
# ==================================================================================================

buildSource() {

	service tomcat7 stop
	echo 'JAVA_OPTS="-Xmx4096M -XX:MaxPermSize=1024M"' | sudo tee /usr/share/tomcat7/bin/setenv.sh

	
	# TODO: Change directory to $MY_PATH/, create temporary directory for Transmart

	git clone https://github.com/transmart/tranSMART-ETL.git
	git clone https://github.com/transmart/transmart-data.git

}


# ==================================================================================================
# loadBoston() - loads the Boston Demodata
# ==================================================================================================

# Parameter: silent (if silent = 1, do not show that Boston Demodata is already loaded)

loadBoston() {

	notImplementedYet()
}

# ==================================================================================================
# dropBoston() - removes the Boston Demodata
# ==================================================================================================

dropBoston() {

	notImplementedYet()

}


# ==================================================================================================
# registerCells() - updates the IP of the Cells in $HIVE_SCHEMA 
# ==================================================================================================

registerCells() {
	
	notImplementedYet()
}

# ==================================================================================================
# registerHive() - updates the HIVE_ID in $PM_SCHEMA and $HIVE_SCHEMA 
# ==================================================================================================

registerHive() {
	
 	notImplementedYet()

}


# ==================================================================================================
# removeBostonRelated() - Removes entries in $HIVE_SCHEMA and $PM_SCHEMA related to Boston Demodata
# ==================================================================================================

removeBostonRelated() {

	notImplementedYet()
	
}



# ==================================================================================================
# loadBostonRelated() - Inserts entries in $HIVE_SCHEMA and $PM_SCHEMA related to Boston Demodata
# ==================================================================================================

loadBostonRelated() {

	notImplementedYet()

}


# ==================================================================================================
# loadHive() - loads the schemata $PM_SCHEMA and $HIVE_SCHEMA
# ==================================================================================================

loadHive() {

   	notImplementedYet()

}


# ==================================================================================================
# dropHive() - removes the schemata $PM_SCHEMA and $HIVE_SCHEMA 
# ==================================================================================================

dropHive() {

	notImplementedYet()

}   


# ==================================================================================================
# createProject() - creates a new i2b2 project
# ==================================================================================================

createProject() {
   		
	notImplementedYet()

}




# ==================================================================================================
# removeProject() - removes an i2b2 project
# ==================================================================================================

removeProject() {

	notImplementedYet()

}


# ==================================================================================================
# removeUser() - removes an i2b2 user
# ==================================================================================================

removeUser() {
	notImplementedYet()

}



# ==================================================================================================
# createUser() - creates a new i2b2 user
# ==================================================================================================

createUser() {

	notImplementedYet()

}


# ==================================================================================================
# assignUser() - assigns an user to a specific i2b2 project
# ==================================================================================================

assignUser() {

	notImplementedYet()

}


# ==================================================================================================
# repairInstallation() - Automatically repair i2b2 installation
# ==================================================================================================

repairInstallation() {

	notImplementedYet()

}



# ==================================================================================================
# createStartStopScripts() - Creates the files start-i2b2.sh and stop-i2b2.sh
# ==================================================================================================

createStartStopScripts() {

   	notImplementedYet()

}


