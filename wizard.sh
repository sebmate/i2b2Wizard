#!/bin/bash

# Check if we want to run an automatic (silent) installation:

SILENT="0"
if [ "$1" = "--silent" ]; then
	SILENT="1"
fi


# Check if we want to run an automatic Docker installation:

DOCKER="0"
if [ "$1" = "--docker" ]; then
	SILENT="1"
    DOCKER="1"	
    DOCKER_DB_SERVER="$2"
    if [ "$2" = "" ]; then
    	echo ""
		echo "Error: Docker container with postgres database has not been specified. Please run i2b2-Wizard like this:"
		echo ""
		echo "     ./wizard.sh --docker docker-oracle-xe-11g"
		echo ""
		exit 1
    fi
fi


# Versioning information:

VER='2016-09-09'
export VER

# Home directory of i2b2 Wizard:

MY_PATH=$(pwd)
export MY_PATH

TEMPVAR="/tmp/answer.tmp"
export TEMPVAR

# Check if we are root:

if [[ ! "$OS" =~ Windows ]]; then
	if [ $(whoami) != "root" ]; then
		echo ""
		echo "You need to be root to run this program!"
		echo ""
		exit 1
	fi
fi

# Default versions to install:

DEFAULT_PRODUCT=i2b2
DEFAULT_I2B2_VERSION=1.7.07c
DEFAULT_TRANSMART_VERSION=0
DEFAULT_OS_SCRIPT="/Ubuntu_14.04"

DEFAULT_DB_TYPE=ORACLE

echo " +--------------------------------------------------------------------+  "
echo " |                                                                    |  "
echo " |  Modular  i 2 b 2   W i z a r d                                    | |"
echo " |                                                                    | |"
echo " |  Copyright (C) 2010-2016 Chair of Medical Informatics,             | |"
echo " |  Friedrich-Alexander-University of Erlangen-Nuremberg, Germany     | |"
echo " |  Contact: Sebastian.Mate@fau.de                                    | |"
echo " |                                                                    | |"
echo " |  Portions by 'Integrated Data Repository Toolkit' project (IDRT)   | |"
echo " |  Copyright (C) 2012 Technologie- und Methodenplattform fuer die    | |"
echo " |  vernetzte medizinische Forschung e.V. (TMF)                       | |"
echo " |                                                                    | |"
echo " |  Portions by 'Integrated Data Repository Toolkit 2' project (IDRT2)| |"
echo " |  Copyright (C) 2014 Technologie- und Methodenplattform fuer die    | |"
echo " |  vernetzte medizinische Forschung e.V. (TMF)                       | |"
echo " |                                                                    | |"
echo " |  Docker compatibility funded by Technologie- und Methodenplattform | |"
echo " |  fuer die vernetzte medizinische Forschung e.V. (TMF) in 2016      | |"
echo " |                                                                    | |"
echo " |  This program is free software; you can redistribute it and/or     | |"
echo " |  modify it under the terms of the GNU General Public License       | |"
echo " |  as published by the Free Software Foundation; either version 2    | |"
echo " |  of the License, or (at your option) any later version.            | |"
echo " |                                                                    | |"
echo " |  This program is distributed in the hope that it will be useful,   | |"
echo " |  but WITHOUT ANY WARRANTY; without even the implied warranty of    | |"
echo " |  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the      | |"
echo " |  GNU General Public License for more details.                      | |"
echo " |                                                                    | |"
echo " |  You should have received a copy of the GNU General Public License | |"
echo " |  along with this program; if not, write to the Free Software       | |"
echo " |  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,        | |"
echo " |  MA 02110-1301, USA.                                               | |"
echo " |                                                                    | |"
echo " +--------------------------------------------------------------------+ |"
echo "    --------------------------------------------------------------------+"
echo ""
echo "Initializing, please wait ..."

touch $MY_PATH/config/wizard.conf
chmod +x $MY_PATH/config/wizard.conf
. $MY_PATH/config/wizard.conf

# ==================================================================================================
# rkh_dat_get_os_info() - Detect Operating System 
# ==================================================================================================

# Taken from the Rootkit Hunter project, see http://sourceforge.net/projects/rkhunter/

rkh_dat_get_os_info() {

	ARCH=""
	OSNAME=""
	RELEASE=""

	if [ -n "${OS_VERSION_FILE}" ]; then
		REL_FILES="${OS_VERSION_FILE}"
	else
		REL_FILES="/etc/system-release /etc/lsb-release /etc/debian_version /etc/slackware-version /var/ipcop/general-functions.pl /etc/lunar.release /etc/ROCK-VERSION /etc/GoboLinuxVersion /etc/kanotix-version /etc/sidux-version /etc/knoppix-version /etc/zenwalk-version /etc/release /etc/*-release"
	fi

	RKH_LSB_SEEN=0

	for FNAME in ${REL_FILES}; do
		test ! -f "${FNAME}" && continue

		if [ "${FNAME}" = "/etc/system-release" ]; then
			RKH_IN_LSB=0
			RELEASE=$FNAME
			OSNAME=`cat ${FNAME}`
			break
		elif [ ! -h "${FNAME}" ]; then
			RELEASE=$FNAME

			RKH_IN_LSB=0

			case "${RELEASE}" in
			/etc/lsb-release)
				RKH_IN_LSB=1
				RKH_LSB_SEEN=1
				OSNAME=`grep '^DISTRIB_DESCRIPTION=' ${RELEASE} | sed -e 's/DISTRIB_DESCRIPTION=//' | tr -d '"'`
				;;
			/etc/gentoo-release)
				if [ -h "/etc/make.profile" ]; then
					OSNAME="Gentoo `ls -l /etc/make.profile 2>/dev/null | sed -e 's;^.*/\([^/]*/[^/]*\)$;\1;' | tr '/' ' '`"
				else
					OSNAME="Gentoo"
				fi
				;;
			/var/ipcop/general-functions.pl)
				OSNAME=`grep 'version *=' ${RELEASE} | head ${HEAD_OPT}1`
				;;
			/etc/debian_version)
				OSNAME="Debian `cat ${RELEASE}`"
				;;
			/etc/GoboLinuxVersion)
				OSNAME="GoboLinux `cat ${RELEASE}`"
				;;
			/etc/knoppix-version)
				OSNAME="Knoppix `cat ${RELEASE}`"
				;;
			/etc/zenwalk-version)
				OSNAME="Zenwalk `cat ${RELEASE}`"
				;;
			*)
				OSNAME=`awk '/^[ 	]*[^ 	]/ { print $0 }' ${RELEASE} | head ${HEAD_OPT}1`
				;;
			esac

			test -n "${OSNAME}" && OSNAME=`echo ${OSNAME}`

			if [ $RKH_IN_LSB -eq 0 -a -z "${OSNAME}" ]; then
				OSNAME=`awk '/^[ 	]*[^ 	]/ { print $0 }' ${RELEASE} | head ${HEAD_OPT}1`
				OSNAME=`echo ${OSNAME}`
			fi

			test -n "${OSNAME}" && break
		fi
	done
	if [ -z "${OSNAME}" ]; then
		RELEASE=""

		if [ -d "/var/smoothwall" ]; then
			OSNAME="Smoothwall Linux"
			RELEASE="/var/smoothwall"
		elif [ -n "`which sorcery 2>/dev/null | grep -v ' '`" -a -n "`which gaze 2>/dev/null | grep -v ' '`" ]; then
			OSNAME="Source Mage Linux"
		fi
	fi
	case "${OPERATING_SYSTEM}" in
	SunOS)
		ARCH=`uname -p 2>/dev/null`
		;;
	FreeBSD|DragonFly)
		ARCH=`sysctl -n hw.machine_arch 2>/dev/null`
		OSNAME=`uname -v 2>/dev/null | cut -d' ' -f1,2`
		;;
	OpenBSD)
		OSNAME="OpenBSD `uname -r 2>/dev/null`"
		;;
	Darwin)
		OSNAME=`sw_vers 2>/dev/null | grep '^ProductName:' | sed -e 's/ProductName:[ 	]*//'`
		OSNAME="${OSNAME} `sw_vers 2>/dev/null | grep '^ProductVersion:' | sed -e 's/ProductVersion:[ 	]*//'`"
		#OSNAME="${OSNAME} `sysctl kern.version 2>/dev/null | sed -e 's/^kern.version = //' | cut -d: -f1`"

		if [ -n "`sysctl -a 2>/dev/null | egrep '^(hw\.optional\.x86_64|hw\.optional\.64bitops|hw\.cpu64bit_capable).*1$'`" ]; then
			OSNAME="${OSNAME} (64-bit capable)"
		fi
		;;
	AIX)
		ARCH=`uname -p 2>/dev/null`
		OSNAME="IBM AIX `oslevel 2>/dev/null`"
		;;
	IRIX*)
		OSNAME="${OPERATING_SYSTEM} `uname -r 2>/dev/null`"
		;;
	esac

	if [ -z "${OSNAME}" ]; then
		if [ -f "/etc/issue" ]; then
			OSNAME=`awk '/^[ 	]*[^ 	]/ { print $0 }' /etc/issue | head ${HEAD_OPT}1`
			OSNAME=`echo ${OSNAME}`
			test -n "${OSNAME}" && RELEASE="/etc/issue"
		fi
		if [ $RKH_LSB_SEEN -eq 1 -a -z "${OSNAME}" ]; then
			OSNAME=`awk '/^[ 	]*[^ 	]/ { print $0 }' /etc/lsb-release | head ${HEAD_OPT}1`
			OSNAME=`echo ${OSNAME}`
			test -n "${OSNAME}" && RELEASE="/etc/lsb-release"
		fi
	elif [ -n "`echo \"${OSNAME}\" | grep '^[0-9.][0-9.]*$'`" ]; then
		if [ -f "/etc/issue" ]; then
			RKHTMPVAR=`awk '/^[ 	]*[^ 	]/ { print $1 }' /etc/issue | head ${HEAD_OPT}1`

			test -n "${RKHTMPVAR}" && OSNAME="${RKHTMPVAR} ${OSNAME}"
			test -n "${RKHTMPVAR}" && OSNAME="${RKHTMPVAR} ${OSNAME}"
		fi
	fi

	test -z "${ARCH}" && ARCH=`uname -m 2>/dev/null`
	test -z "${OSNAME}" && OSNAME="`uname` `uname -r 2>/dev/null`"

	return
}

rkh_dat_get_os_info
OS_SCRIPT_IDENTIFIER=`echo $OSNAME | sed 's/ /_/g;s/\//_/g'`

if [[ "$OS" =~ Windows ]]; then
	OS_SCRIPT_IDENTIFIER="WindowsCygwin"
fi

# Handling of unknown operating systems:

if [ ! -f $MY_PATH/scripts/os_versions/$OS_SCRIPT_IDENTIFIER.sh ]; then
	OS_SCRIPT_IDENTIFIER2=$OS_SCRIPT_IDENTIFIER
	while [ ! "$OS_SCRIPT_IDENTIFIER2" = "" -a ! -f $MY_PATH/scripts/os_versions/$OS_SCRIPT_IDENTIFIER2.sh ]; do
		OS_SCRIPT_IDENTIFIER2=${OS_SCRIPT_IDENTIFIER2::-1}
	done
	if [ "$OS_SCRIPT_IDENTIFIER2" = "" ]; then
		OS_SCRIPT_IDENTIFIER2=$DEFAULT_OS_SCRIPT
	fi
	echo ""
	echo "WARNING: Your operating system '$OSNAME' may not be supported by this version of i2b2 Wizard because there is no specific script $MY_PATH/scripts/os_versions/$OS_SCRIPT_IDENTIFIER.sh. i2b2 Wizard can create one based on $MY_PATH/scripts/os_versions/$OS_SCRIPT_IDENTIFIER2.sh. Do you want to continue?"
	echo ""
	
	if [ ! "$SILENT" = "1" ]; then  
	    read -p "Press RETURN to continue with the installation or press CTRL+C to abort!"
    	echo ""
	fi
	
	cp $MY_PATH/scripts/os_versions/$OS_SCRIPT_IDENTIFIER2.sh $MY_PATH/scripts/os_versions/$OS_SCRIPT_IDENTIFIER.sh
fi


# Select i2b2 or Transmart:

until  [[ "$PRODUCT" = "i2b2" || "$PRODUCT" = "Transmart" ]] ; do
	echo -n "Please specify whether you want to install i2b2 or Transmart (i2b2, Transmart) [$DEFAULT_PRODUCT]: "
    
    if [ ! "$SILENT" = "1" ] ; then  
        read PRODUCT
    fi
	
	if [ "$PRODUCT" = "" ]; then
		PRODUCT="i2b2"
		echo " => Selected the default: $PRODUCT"
		echo ""
		#sleep 1
	fi   
	
	if [ "$PRODUCT" = "i2b2" ]; then
		DEFAULT_PRODUCT_VERSION=$DEFAULT_I2B2_VERSION
	fi   

	if [ "$PRODUCT" = "Transmart" ]; then
		DEFAULT_PRODUCT_VERSION=$DEFAULT_TRANSMART_VERSION
		DBTYPE="POSTGRESQL"
	fi   
	
done

# Specify version:

until [ -f $MY_PATH/scripts/product_versions/"$PRODUCT"_"$PRODUCT_VERSION".sh ]; do
	echo -n "Please enter the $PRODUCT version that you intend to install [$DEFAULT_PRODUCT_VERSION]: "
    
    if [ ! "$SILENT" = "1" ]; then  
        read PRODUCT_VERSION
    fi
	
	if [ "$PRODUCT_VERSION" = "" ]; then
		PRODUCT_VERSION="$DEFAULT_PRODUCT_VERSION"
		echo " => Selected the default: $DEFAULT_PRODUCT_VERSION"
		echo ""
		#sleep 1
	fi   
	
	if [ ! -f $MY_PATH/scripts/product_versions/"$PRODUCT"_"$PRODUCT_VERSION".sh ]; then
		echo ""
		echo "This $PRODUCT version is not supported by this version i2b2 Wizard. You can try to duplicate one of the scripts in the scripts/product_version directory and work on it. Please contribute new scripts to the i2b2 Wizard developers. Thanks!"
		echo ""
	fi
done    

PRODUCT_SCRIPT_IDENTIFIER="$PRODUCT"_"$PRODUCT_VERSION"

while [ ! -f $MY_PATH/scripts/database_types/$DBTYPE.sh ]; do
	echo -n "Please enter the database type that you intend to install (POSTGRESQL, MSSQL or ORACLE) [$DEFAULT_DB_TYPE]: "

    if [ ! "$SILENT" = "1" ]; then  
        read DBTYPE
	fi
	
	FIRSTSTART=yes
	
	if [ "$DBTYPE" = "" ]; then
		DBTYPE=$DEFAULT_DB_TYPE
		echo " => Selected the default: $DEFAULT_DB_TYPE"
		echo ""
		#sleep 1
	fi   

	if [ $DBTYPE = "MSSQL" ]; then
		DB_SERVER="Change IP address!"
		DB_PORT=1433
		DB_SYSUSER=sa
		DB_SYSPASS="Please change!"
		DB_ALLOW=yes
		ORA_SSID=""
	fi

	if [ $DBTYPE = "POSTGRESQL" ]; then
		DB_SERVER=localhost
		DB_PORT=5432
		DB_SYSUSER=postgres
		DB_SYSPASS=i2b2
		DB_ALLOW=yes
		ORA_SSID=""
	fi

	if [ $DBTYPE = "ORACLE" ]; then
		DB_SERVER=localhost
		DB_PORT=1521
		DB_SYSUSER=system
		DB_SYSPASS=i2b2
		DB_ALLOW=yes
		ORA_SSID=xe
	fi
done


# Change these parameters to override the default setting from above
# with those of your Docker database container:

if [ "$DOCKER" = "1" ]; then
    
    DB_SYSPASS=oracle
    
    # This one is passed over from the command line:
    DB_SERVER="$DOCKER_DB_SERVER"
fi


# Now include all other subscripts. The order matters! menu_system.sh then opens the UI.

. $MY_PATH/scripts/init.sh
. $MY_PATH/scripts/wizard_features.sh
. $MY_PATH/scripts/database_types/$DBTYPE.sh
. $MY_PATH/scripts/os_versions/$OS_SCRIPT_IDENTIFIER.sh
. $MY_PATH/scripts/product_versions/$PRODUCT_SCRIPT_IDENTIFIER.sh
. $MY_PATH/scripts/shrine.sh
. $MY_PATH/scripts/menu_system.sh

