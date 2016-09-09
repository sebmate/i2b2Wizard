
# ==================================================================================================
# showInfo() - shows copyright and version info
# ==================================================================================================

showInfo() {

	updateBackTitle
    dialog --colors --backtitle "$BACKTITLE"\
        --msgbox "                      i 2 b 2   W i z a r d  \n                       Version: $VER\n\nCopyright (C) 2010-2016, Chair of Medical Informatics, Friedrich-Alexander-University of Erlangen-Nuremberg, Germany.\n\nPortions Copyright (C) 2012-2016, IDRT Projects and TMF e.V.\n\nThis program comes with ABSOLUTELY NO WARRANTY. This is free software, and you are welcome to redistribute it under certain conditions; see 'LICENSE.txt' for details.\n\nContact: Sebastian.Mate@fau.de" 19 67
		
}

# ==================================================================================================
# showProjects() - shows all i2b2 projects
# ==================================================================================================

showProjects() {

	updateBackTitle
	
    touch $MY_PATH/config/projectlist.dat
    touch $MY_PATH/config/project.tmp
    rm $MY_PATH/config/project.tmp

    exec<$MY_PATH/config/projectlist.dat
    while read line
    do
        echo "$line" | cut -d '#' -f 1-1 >> $MY_PATH/config/project.tmp
    done
   
    if [ ! -f "$MY_PATH/config/project.tmp" ]; then  
        dialog --colors --backtitle "$BACKTITLE" --msgbox "No projects found!" 6 40
        return
    fi
    
    dialog --colors --backtitle "$BACKTITLE" --title " Current Projects: "\
           --textbox $MY_PATH/config/project.tmp 14 40
}
    

# ==================================================================================================
# showUsers() - shows all i2b2 users
# ==================================================================================================

showUsers() {

	updateBackTitle
	
    touch $MY_PATH/config/userlist.dat

    touch $MY_PATH/config/user.tmp
    rm $MY_PATH/config/user.tmp

    exec<$MY_PATH/config/userlist.dat
    while read line
    do
        echo "$line" | cut -d '#' -f 1-2 | sed -e 's/#/ = /g'>> $MY_PATH/config/user.tmp
    done

    if [ ! -f "$MY_PATH/config/user.tmp" ]; then  
        dialog --colors --backtitle "$BACKTITLE" --msgbox "No users found!" 6 40
        return
    fi

    dialog --colors --backtitle "$BACKTITLE" --title " Current Users: "\
           --textbox $MY_PATH/config/user.tmp 14 40
}

# ==================================================================================================
# systemMenu() - opens the menu: Main Menu >> System Setup
# ==================================================================================================

systemMenu() {

    while true; do
	
		updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --title " Main Menu >> System Setup "\
            --cancel-label "Back" \
            --menu "Move using [UP] [DOWN], [Enter] to select" 15 100 11\
            "Set Defaults" "Define default parameters"\
            "Download Reqired Packages" "Automatically download required server software packages"\
            "Install Required Packages" "Automatically install required server software packages"\
            "Additional Features" "Automatically install additional i2b2 features (plugins, ...)"\
            "Repair Installation" "Automatically repair i2b2 installation"\
            "Create JBoss User" "Create a separate Linux User for JBoss"\
            "Enable Oracle Remote" "Enable Oracle DB remote HTTP access"\
            "Hive Tasks" "Modify i2b2 Hive options"\
            2>$TEMPVAR

        opt=${?}
        if [ $opt != 0 ]; then return; fi

        menuitem=`cat $TEMPVAR`

        case $menuitem in
            "Set Defaults") setValues;;
            "Download Reqired Packages") SYSTEM_SANE=no; autoDownloadPackages;;
            "Install Required Packages") SYSTEM_SANE=no; autoInstallApps;;
            "Additional Features") additionalFeaturesMenu;;
			"Repair Installation") repairInstallation;;
            "Create JBoss User") createJBossUser;;
            "Enable Oracle Remote") enableRemoteOracle;;
            "Hive Tasks") hiveMenu;;
        esac
    done
}


# ==================================================================================================
# additionalFeaturesMenu() - Opens a checklist-window in which the user can select additional
#                            features to be installed.
# ==================================================================================================

additionalFeaturesMenu() {

    CHOICES=`exec<$MY_PATH/features/featurelist.dat
            while read line
            do
				echo -n "$line" | cut -d '#' -f 1-1  
            done`
	
	updateBackTitle
	
	#echo ${CHOICES}
	#sleep 5
	
    eval dialog --colors --title "\" Install Additional Features \"" --backtitle \"$BACKTITLE\" --radiolist "\"Please select the i2b2 feature that shall be installed:\"" 15 70 8 ${CHOICES} 2>$TEMPVAR
    
    result=`cat $TEMPVAR | sed 's/ //g;s/\"/ /g'`
    
    for i in $result; do
        installFeature $i
    done
	
	#sleep 5
	
}


# ==================================================================================================
# hiveMenu() - opens the menu: Main Menu >> System Setup >> Misc. Tasks
# ==================================================================================================

hiveMenu() {

    while true; do
		updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --title " Main Menu >> System Setup >> Misc. Tasks "\
            --cancel-label "Back" \
            --menu "Move using [UP] [DOWN], [Enter] to select" 11 84 9\
            "Update Hive-IP" "Update Hive-IP for i2b2 cell registration"\
            "Update Hive-ID" "Update the Hive-ID to '$HIVE_ID'"\
            "Drop $PM_SCHEMA and $HIVE_SCHEMA " "Remove the basic administrative i2b2 Hive data (!)"\
            "Load $PM_SCHEMA and $HIVE_SCHEMA " "Load the basic administrative i2b2 Hive data (!)"\
           2>$TEMPVAR

        opt=${?}
        if [ $opt != 0 ]; then return; fi

        menuitem=`cat $TEMPVAR`

        case $menuitem in
            "Update Hive-IP") registerCells;;
            "Update Hive-ID") registerHive;;
            "Load $PM_SCHEMA and $HIVE_SCHEMA ") loadHive;;
            "Drop $PM_SCHEMA and $HIVE_SCHEMA ") dropHive;;
        esac
    done
}

# ==================================================================================================
# projectMenu() - opens the menu: Main Menu >> Project Management
# ==================================================================================================

projectMenu() {


    while true; do
		
		updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --title " Main Menu >> Project & Users "\
           --cancel-label "Back" \
            --menu "Move using [UP] [DOWN], [Enter] to select" 16 77 14\
            "Show i2b2 Projects" "Shows a list with all projects"\
            "Create i2b2 Project" "Create a new i2b2 project and load basic data"\
			"Remove i2b2 Project" "Remove i2b2 project and associated data"\
            "        " "        " \
			"Show i2b2 Users" "Shows a list with all i2b2 users"\
            "Create i2b2 User" "Create a new i2b2 user"\
            "Remove i2b2 User" "Remove i2b2 user"\
			"        " "        " \
			"Assign User" "Assign a user to an i2b2 project" 2>$TEMPVAR

        opt=${?}
        if [ $opt != 0 ]; then return; fi

        menuitem=`cat $TEMPVAR`

        case $menuitem in
            "Create i2b2 Project") createProject;;  
            "Remove i2b2 Project") removeProject;;  
            "Assign User") assignUser;;  
            "Show i2b2 Projects") showProjects;;  
            "Show i2b2 Users") showUsers;;
            "Create i2b2 User") createUser;;
            "Remove i2b2 User") removeUser;;  
        esac
    done
}



# ==================================================================================================
# bostonMenu() - opens the menu: Main Menu >> Boston Demodata
# ==================================================================================================

bostonMenu() {

    while true; do

		updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --title " Main Menu >> Boston Demodata  "\
           --cancel-label "Back" \
            --menu "Move using [UP] [DOWN], [Enter] to select" 9 87 7\
            "Load Boston Demodata" "Create project 'Demo' and users 'i2b2' and 'demo'"\
            "Drop Boston Demodata" "Remove project 'Demo' and users 'i2b2' and 'demo'" 2>$TEMPVAR

        opt=${?}
        if [ $opt != 0 ]; then return; fi

        menuitem=`cat $TEMPVAR`

        case $menuitem in
            "Load Boston Demodata") loadBoston;;
            "Drop Boston Demodata") dropBoston;;
            "Load Boston Related") loadBostonRelated;;
            "Drop Boston Related") removeBostonRelated;;
        esac
    done
}


# ==================================================================================================
# jbossMenu() - opens the menu: Main Menu >> JBoss Control
# ==================================================================================================

jbossMenu() {

    RUNAS="(with Linux user 'root')"
    if [ "$USE_JBOSS_USER" = "yes" ]; then  
        RUNAS="(with Linux user '$JBOSS_USER')"
    fi

    while true; do

		updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --title " Main Menu >> JBoss Control "\
            --cancel-label "Back" \
            --menu "Move using [UP] [DOWN], [Enter] to select" 11 64 8\
                   "Start JBoss" "Start JBoss $RUNAS"\
                   "Stop JBoss" "Stop JBoss"\
                   "Restart JBoss" "Start JBoss $RUNAS"\
				   "Log" "Show JBoss log" 2>$TEMPVAR
        opt=${?}
        if [ $opt != 0 ]; then return; fi

        menuitem=`cat $TEMPVAR`

        case $menuitem in
            "Stop JBoss") stopJBoss;;
            "Start JBoss") startJBoss;;
            "Restart JBoss") stopJBoss; startJBoss;;
			"Log") showJBossLog;;
			
        esac
    done
}

	
# ==================================================================================================
# shrineMenu() - opens the menu: Main Menu >> SHRINE
# ==================================================================================================

shrineMenu() {

    RUNAS="(with Linux user 'root')"
    if [ "$USE_JBOSS_USER" = "yes" ]; then  
        RUNAS="(with Linux user '$JBOSS_USER')"
    fi

    while true; do

		updateBackTitle
		
        dialog --colors --backtitle "$BACKTITLE" --title " Main Menu >> SHRINE "\
            --cancel-label "Back" \
            --menu "Move using [UP] [DOWN], [Enter] to select" 13 64 8\
                   "Configure" "Configure SHRINE node"\
				   "Install" "Install SHRINE"\
                   "Force" "Install SHRINE (force re-download)"\
                   "Start" "Start SHRINE in Tomcat"\
                   "Stop" "Stop SHRINE"\
                   "Log" "Show Tomcat log" 2>$TEMPVAR
        opt=${?}
        if [ $opt != 0 ]; then return; fi

        menuitem=`cat $TEMPVAR`

        case $menuitem in
			"Configure") setShrineValues;;
            "Install") installShrine;;
            "Force") installShrine 1;;
            "Remove") removeShrine;;
            "Start") startShrine;;
			"Stop") stopTomcat;;
            "Log") showTomcatLog;;
        esac
    done
}


# ==================================================================================================
# mainMenu() - opens the menu: Main Menu
# ==================================================================================================

mainMenu() {

    createStartStopScripts
    setFilePermissions

	if [ "$JBOSSSTATUS" = "1" ]; then  
        JBOSSSTARTEDATSTART=1
    fi    
	
    updateBackTitle
    
    dialog --colors --backtitle "$BACKTITLE" --title " Main Menu "\
        --cancel-label "Quit" \
        --menu "Move using [UP] [DOWN], [Enter] to select" 15 70 10\
        "System Setup"  "Install required software, prepare system"\
        "Projects & Users" "Manage i2b2 projects and users"\
        "Boston Demodata" "Load and remove the Boston Demodata"\
        "Build i2b2" "Compile and deploy i2b2 webservices"\
        "JBoss Control" "Start, stop and restart JBoss"\
        "SHRINE" "SHRINE installation and configuration"\
		"Info" "Show program and version info"\
        "Quit" "Exit this program" 2>$TEMPVAR
        
    opt=${?}
    if [ $opt != 0 ]; then rm $TEMPVAR; exitHandler; exit; fi
    
    menuitem=`cat $TEMPVAR`
    case $menuitem in
        "System Setup") systemMenu;;
        "Projects & Users") projectMenu;;
        "JBoss Control") jbossMenu;;
        "Boston Demodata") bostonMenu;;
        "Info") showInfo;;
        "Build i2b2") buildSource;;
        "SHRINE") shrineMenu;;
        "Quit") rm $TEMPVAR; exitHandler; exit;;
    esac
}


# ==================================================================================================
# selectETL() - Opens a checklist-window in which the user can select the ETL-tasks for the
#               i2b2 projects.
# ==================================================================================================

selectETL() {

    CHOICES=`exec<$MY_PATH/config/projectlist.dat
            while read line
            do
                echo -n "$line" | cut -d '#' -f 1-1 | ( read A; echo \"$A\" " " \"\"" on " )     
            done | sed ':a;N;$!ba;s/\n//g'`
    
	updateBackTitle
	
    eval dialog --colors --title "\" Run i2b2-Wizard ETL \"" --backtitle \"$BACKTITLE\" --checklist "\"Please select the i2b2 projects for which you want to run the ETL SQL-scripts (located in $MY_PATH/ETL/scripts/):\"" 15 65 8 ${CHOICES} 2>$TEMPVAR
    
    result=`cat $TEMPVAR | sed 's/ //g;s/\"/ /g'`
    
    for i in $result; do
        runETL $i
    done

}


# ==================================================================================================
# installFeature() - Installs an additional feature
# ==================================================================================================

# Parameter: filename

installFeature() {

     #echo $1
	
	rm -rf $MY_PATH/features/temp/$1/
	mkdir -p $MY_PATH/features/temp/$1/
	unzip -qq $MY_PATH/features/$1.zip -d $MY_PATH/features/temp/$1/

	if grep -q "install$1" "$MY_PATH/features/temp/$1/install.sh"; then
	
		# new install method by Sebastian with function call
		
		getWebserverDirectory
		
		. $MY_PATH/features/temp/$1/install.sh
		
		install$1
		
	else
	
		# old install method by Axel
	
		chmod +x $MY_PATH/features/temp/$1/install.sh
		getWebserverDirectory
		bash $MY_PATH/features/temp/$1/install.sh $MY_PATH/features/temp/$1/ $WEBSERVERDIRECTORY 
	
	fi
	
	rm -rf $MY_PATH/features/temp

}


#=========================================================================
# Main  *********************************************************
#=========================================================================

#checkJavaInstallation
getJBossStatus
getTomcatStatus
autoUpdate

# Disable the following command if you have installed dialog 1.1 from source.
# ftp://ftp.us.debian.org/debian/pool/main/d/dialog/dialog_1.1-20100428.orig.tar.gz
# http://hightek.org/dialog/

autoPackageInstall silent dialog

# If the program was started with parameter "--silent", attempt to run in silent mode:

if [ "$SILENT" = "1" ]; then  
	touch $MY_PATH/silent_install.log
	echo `date` " --- Silent install started --- " > $MY_PATH/silent_install.log
	echo `date` getIP >> $MY_PATH/silent_install.log	
    getIP
	
	HIVE_SCHEMA=I2B2HIVE
	PM_SCHEMA=I2B2PM
	HIVE_PASS=i2b2hive
	PM_PASS=i2b2pm

    if [ ! "$POSTGRES_PORT_5432_TCP_ADDR" = "" ]; then
        DB_SERVER="$POSTGRES_PORT_5432_TCP_ADDR"
    fi
    
    if [ ! "$POSTGRES_PORT_5432_TCP_PORT" = "" ]; then
        DB_PORT="$POSTGRES_PORT_5432_TCP_PORT"
    fi
       
    if [ !  "$POSTGRES_ENV_POSTGRES_PASSWORD" = "" ]; then
        DB_SYSUSER="postgres"
        DB_SYSPASS="$POSTGRES_ENV_POSTGRES_PASSWORD"
    fi
    
    saveValues
        
	echo `date` updateBackTitle >> $MY_PATH/silent_install.log	
    updateBackTitle
	echo `date` createProject >> $MY_PATH/silent_install.log
	createProject
	echo `date` createUser >> $MY_PATH/silent_install.log
	createUser
	echo `date` assignUser >> $MY_PATH/silent_install.log
	assignUser
	echo `date` removeProject >> $MY_PATH/silent_install.log
	removeProject
	echo `date` removeUser >> $MY_PATH/silent_install.log
	removeUser
	
	#echo `date` createProject >> $MY_PATH/silent_install.log
	#createProject	
	#echo `date` createUser >> $MY_PATH/silent_install.log
	#createUser
	#echo `date` assignUser >> $MY_PATH/silent_install.log
	#assignUser
	#echo `date` startJBoss >> $MY_PATH/silent_install.log
	#startJBoss
	
	echo `date` loadBoston >> $MY_PATH/silent_install.log
	loadBoston 1
	echo `date` startJBoss >> $MY_PATH/silent_install.log
	startJBoss
	echo `date` exitHandler >> $MY_PATH/silent_install.log
	exitHandler
	exit 0

	# You should now be able to log in with user "test", password "demouser" into project "My Project" and
	# user "demo", password "demouser" into project "Demo".

fi   

# Display disclaimer:

updateBackTitle

dialog --colors --backtitle "$BACKTITLE" --title " DISCLAIMER " --msgbox "This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n\nTHERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM 'AS IS' WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.\n\nIN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. \n\nNote: This also includes the security of patient data, which might be stored and/or processed in this system. Although this program offers certain security features (e.g. pre-configuration of a firewall) there are no mechanisms to automatically maintain a fully secure system." 25 100 

if [ "$FIRSTSTART" = "yes" ]; then
	dialog --colors --backtitle "$BACKTITLE" --title " Welcome & Verify Settings " --msgbox "Welcome to i2b2 Wizard!\n\nBefore you can use i2b2 Wizard, please make sure that the settings (especially those for the database) are correct.\n\nPress ENTER to open the configuration menu ..." 10 100 
	setValues
fi

# configureFirewall

saveValues

# Launch menu system:

while true; do
  mainMenu
done

exit 1
