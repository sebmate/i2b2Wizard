# "Read" configuration parameters from config-files:

export NCURSES_NO_UTF8_ACS=1

touch $MY_PATH/config/shrine.conf
chmod +x $MY_PATH/config/shrine.conf
. $MY_PATH/config/shrine.conf

export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server
export ORACLE_SID=$ORA_SSID

case "$PATH" in
   *$ANT_HOME*) ;;
   *) PATH=$PATH:$ANT_HOME/bin ;;
esac

export PATH

# The LINENO feature doesn't seem to work, so set the variable to "Unknown":
LINENO="Unknown"

export SILENT
export LINENO
