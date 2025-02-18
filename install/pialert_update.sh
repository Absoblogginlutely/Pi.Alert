#!/bin/bash
# ------------------------------------------------------------------------------
#  Pi.Alert
#  Open Source Network Guard / WIFI & LAN intrusion detector 
#
#  pialert_update.sh - Update script
# ------------------------------------------------------------------------------
#  Puche 2021        pi.alert.application@gmail.com        GNU GPLv3
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
INSTALL_DIR=~
PIALERT_HOME="$INSTALL_DIR/pialert"
LOG="pialert_update_`date +"%Y-%m-%d_%H-%M"`.log"
PYTHON_BIN=python3


# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
  update_warning
  print_superheader "Pi.Alert Update"
  log "`date`"
  log "Logfile: $LOG"
  log ""

  set -e

  check_pialert_home
  check_python_version

  reset_permissions
  create_backup
  move_files
  clean_files

  check_packages
  download_pialert
  update_config
  update_db
  update_permissions

  test_pialert
  
  print_header "Update process finished"
  print_msg ""

  move_logfile
}

update_warning() {
  clear
  print_msg "############################################################################"
  print_msg "# You are planning to update Pi.Alert. Please make sure that no scan takes #"
  print_msg "# place during the update to avoid possible database errors afterwards!!!  #"
  print_msg "#                                                                          #"
  print_msg "# This can be done by pausing the Arp scan via the settings page. However, #"
  print_msg "# scans that are already running will not be terminated.                   #"
  print_msg "############################################################################"
  print_msg ""
  print_msg ""
  printf "%s " "Press enter to continue"
  read ans
}

# ------------------------------------------------------------------------------
# Reset Permissions
# ------------------------------------------------------------------------------
reset_permissions() {
  print_msg "- Reset permissions..."
  sudo chgrp -R www-data $PIALERT_HOME/db                             2>&1 >> "$LOG"
  sudo chmod -R 775 $PIALERT_HOME/db                                  2>&1 >> "$LOG"
  sudo chgrp -R www-data $PIALERT_HOME/config                         2>&1 >> "$LOG"
  sudo chmod -R 775 $PIALERT_HOME/config                              2>&1 >> "$LOG"
}

# ------------------------------------------------------------------------------
# Create backup
# ------------------------------------------------------------------------------
create_backup() {
  # Previous backups are not deleted
  # print_msg "- Deleting previous Pi.Alert backups..."
  # rm "$INSTALL_DIR/"pialert_update_backup_*.tar  2>/dev/null || :
  
  print_msg "- Creating new Pi.Alert backup..."
  cd "$INSTALL_DIR"
  tar cvf "$INSTALL_DIR"/pialert_update_backup_`date +"%Y-%m-%d_%H-%M"`.tar pialert --checkpoint=100 --checkpoint-action="ttyout=."     2>&1 >> "$LOG"
  echo ""
}

# ------------------------------------------------------------------------------
# Move files to the new directory
# ------------------------------------------------------------------------------
move_files() {
  if [ -e "$PIALERT_HOME/back/pialert.conf" ] ; then
    print_msg "- Moving pialert.conf to the new directory..."
    mkdir -p "$PIALERT_HOME/config"
    mv "$PIALERT_HOME/back/pialert.conf" "$PIALERT_HOME/config"
  fi
}

# ------------------------------------------------------------------------------
# Remove old files
# ------------------------------------------------------------------------------
clean_files() {
  print_msg "- Cleaning previous version..."
  rm -rf "$PIALERT_HOME/back"    2>/dev/null || :
  rm -rf "$PIALERT_HOME/doc"     2>/dev/null || :
  rm -rf "$PIALERT_HOME/docs"    2>/dev/null || :
  rm -rf "$PIALERT_HOME/front"   2>/dev/null || :
  rm -rf "$PIALERT_HOME/install" 2>/dev/null || :
  rm -rf "$PIALERT_HOME/"*.txt   2>/dev/null || :
  rm -rf "$PIALERT_HOME/"*.md    2>/dev/null || :
}

# ------------------------------------------------------------------------------
# Check packages
# ------------------------------------------------------------------------------
check_packages() {
  print_msg "- Checking package apt-utils..."
  sudo apt-get install apt-utils -y                               2>&1 >> "$LOG"

  print_msg "- Checking package sqlite3..."
  sudo apt-get install sqlite3 -y                                 2>&1 >> "$LOG"

  print_msg "- Checking packages dnsutils & net-tools..."
  sudo apt-get install dnsutils net-tools wakeonlan -y            2>&1 >> "$LOG"

  print_msg "- Checking package php-curl..."
  sudo apt-get install php-curl -y                                2>&1 >> "$LOG"

  print_msg "- Checking packages perl and python3-requests..."
  sudo apt-get install python3-requests libwww-perl -y            2>&1 >> "$LOG"

  print_msg "- Checking packages mmdblookup"
  sudo apt-get install mmdb-bin -y                                2>&1 >> "$LOG"
}


# ------------------------------------------------------------------------------
# Download and uncompress Pi.Alert
# ------------------------------------------------------------------------------
download_pialert() {
  if [ -f "$INSTALL_DIR/pialert_latest.tar" ] ; then
    print_msg "- Deleting previous downloaded tar file"
    rm -r "$INSTALL_DIR/pialert_latest.tar"
  fi
  
  print_msg "- Downloading update file..."
  curl -Lo "$INSTALL_DIR/pialert_latest.tar" https://github.com/leiweibau/Pi.Alert/raw/main/tar/pialert_latest.tar
  echo ""

  print_msg "- Uncompressing tar file"
  tar xf "$INSTALL_DIR/pialert_latest.tar" -C "$INSTALL_DIR" \
    --exclude='pialert/config/pialert.conf' \
    --exclude='pialert/db/pialert.db' \
    --exclude='pialert/log/*'  \
    --checkpoint=100 --checkpoint-action="ttyout=."               2>&1 >> "$LOG"
  echo ""

  print_msg "- Deleting downloaded tar file..."
  rm -r "$INSTALL_DIR/pialert_latest.tar"
}

# ------------------------------------------------------------------------------
#  Update conf file
# ------------------------------------------------------------------------------
update_config() {
  print_msg "- Config backup..."
  # to force write permission, will be reverted later
  sudo chmod 777 "$PIALERT_HOME/config/pialert.conf"
  cp "$PIALERT_HOME/config/pialert.conf" "$PIALERT_HOME/config/pialert.conf.back"  2>&1 >> "$LOG"

  print_msg "- Updating config file..."
#  sed -i '/VERSION/d' "$PIALERT_HOME/config/pialert.conf"                          2>&1 >> "$LOG"
#  sed -i 's/PA_FRONT_URL/REPORT_DEVICE_URL/g' "$PIALERT_HOME/config/pialert.conf"  2>&1 >> "$LOG"

if ! grep -Fq "# Shoutrrr" "$PIALERT_HOME/config/pialert.conf" ; then
  cat << EOF >> "$PIALERT_HOME/config/pialert.conf"

# Shoutrrr
# ----------------------
SHOUTRRR_BINARY    = 'armhf'

# Telegram via Shoutrrr
# ----------------------
REPORT_TELEGRAM         = False
TELEGRAM_BOT_TOKEN_URL  = '<Your generated servive URL for telegram - use ~/pialert/back/shoutrrr/<your Systemtyp>/shoutrrr generate telegram>'
EOF
fi

if ! grep -Fq PUSHSAFER_DEVICE "$PIALERT_HOME/config/pialert.conf" ; then
  cat << EOF >> "$PIALERT_HOME/config/pialert.conf"
PUSHSAFER_DEVICE = 'a'
EOF
fi

if ! grep -Fq "# Arp-scan Options & Samples" "$PIALERT_HOME/config/pialert.conf" ; then
  cat << EOF >> "$PIALERT_HOME/config/pialert.conf"

# Arp-scan Options & Samples
# ----------------------
# Scan local network (default)
SCAN_SUBNETS    = '--localnet'
#
# Scan two subnets
# SCAN_SUBNETS    = '192.168.11.0/24 192.168.144.0/24'
#
# Scan using interface eth0
# SCAN_SUBNETS    = '--localnet --interface=eth0'
#
# Scan multiple interfaces (eth1 and eth0):
# SCAN_SUBNETS    = [ '192.168.1.0/24 --interface=eth1', '192.168.1.0/24 --interface=eth0' ]
EOF
fi


if ! grep -Fq "# WebGUI Reporting" "$PIALERT_HOME/config/pialert.conf" ; then
  cat << EOF >> "$PIALERT_HOME/config/pialert.conf"

# WebGUI Reporting
# ----------------------
REPORT_WEBGUI = True
EOF
fi

if ! grep -Fq "SCAN_WEBSERVICES" "$PIALERT_HOME/config/pialert.conf" ; then
  cat << EOF >> "$PIALERT_HOME/config/pialert.conf"

SCAN_WEBSERVICES = False
EOF
fi

if ! grep -Fq "REPORT_MAIL_WEBMON" "$PIALERT_HOME/config/pialert.conf" ; then
  cat << EOF >> "$PIALERT_HOME/config/pialert.conf"

REPORT_MAIL_WEBMON       = False
REPORT_WEBGUI_WEBMON     = True
REPORT_TELEGRAM_WEBMON   = False
REPORT_NTFY_WEBMON       = False
REPORT_PUSHSAFER_WEBMON  = False
EOF
fi

if ! grep -Fq "# Special Protocol Scanning" "$PIALERT_HOME/config/pialert.conf" ; then
  cat << EOF >> "$PIALERT_HOME/config/pialert.conf"

# Special Protocol Scanning
# ----------------------
SCAN_ROGUE_DHCP        = False
DHCP_SERVER_ADDRESS    = '0.0.0.0'
EOF
fi

if ! grep -Fq "# Pushover" "$PIALERT_HOME/config/pialert.conf" ; then
  cat << EOF >> "$PIALERT_HOME/config/pialert.conf"

# Pushover
# ----------------------
REPORT_PUSHOVER         = False
REPORT_PUSHOVER_WEBMON  = False
PUSHOVER_TOKEN          = '<Token>'
PUSHOVER_USER           = '<APP-API>'
EOF
fi


if ! grep -Fq "# Fritzbox Configuration" "$PIALERT_HOME/config/pialert.conf" ; then
  cat << EOF >> "$PIALERT_HOME/config/pialert.conf"

# Fritzbox Configuration
# ----------------------
FRITZBOX_ACTIVE   = False
FRITZBOX_IP       = '192.168.17.1'
FRITZBOX_USER     = 'user'
FRITZBOX_PASS     = 'password'
EOF
fi

}

# ------------------------------------------------------------------------------
#  DB DDL
# ------------------------------------------------------------------------------
update_db() {
  print_msg "- Updating DB permissions..."
  sudo chgrp -R www-data $PIALERT_HOME/db                         2>&1 >> "$LOG"
  sudo chmod -R 775 $PIALERT_HOME/db                              2>&1 >> "$LOG"

  print_msg "- Installing sqlite3..."
  sudo apt-get install sqlite3 -y                                 2>&1 >> "$LOG"

}


# ------------------------------------------------------------------------------
#  
# ------------------------------------------------------------------------------
update_permissions() {
  print_msg "- Set Permissions..."
  sudo chgrp -R www-data "$PIALERT_HOME/db"                         2>&1 >> "$LOG"
  sudo chmod -R 775 "$PIALERT_HOME/db/temp"                         2>&1 >> "$LOG"
  chmod +x "$PIALERT_HOME/back/shoutrrr/arm64/shoutrrr"             2>&1 >> "$LOG"
  chmod +x "$PIALERT_HOME/back/shoutrrr/armhf/shoutrrr"             2>&1 >> "$LOG"
  chmod +x "$PIALERT_HOME/back/shoutrrr/x86/shoutrrr"               2>&1 >> "$LOG"
  chmod +x "$PIALERT_HOME/back/speedtest-cli"                       2>&1 >> "$LOG"
  chmod +x "$PIALERT_HOME/back/pialert-cli"                         2>&1 >> "$LOG"
  chmod +x "$PIALERT_HOME/back/pialert.py"                          2>&1 >> "$LOG"
  chmod +x "$PIALERT_HOME/back/update_vendors.sh"                   2>&1 >> "$LOG"
  sudo chmod -R 775 "$PIALERT_HOME/config/"                         2>&1 >> "$LOG"
  sudo chgrp -R www-data "$PIALERT_HOME/config/pialert.conf"
  sudo chmod -R 775 "$PIALERT_HOME/front/reports"
  sudo chgrp -R www-data "$PIALERT_HOME/front/reports"
  print_msg "- Create Logfile Symlinks..."
  touch "$PIALERT_HOME/log/pialert.vendors.log"
  touch "$PIALERT_HOME/log/pialert.1.log"
  touch "$PIALERT_HOME/log/pialert.cleanup.log"
  touch "$PIALERT_HOME/log/pialert.webservices.log"
  ln -s "$PIALERT_HOME/log/pialert.vendors.log" "$PIALERT_HOME/front/php/server/pialert.vendors.log"
  ln -s "$PIALERT_HOME/log/pialert.IP.log" "$PIALERT_HOME/front/php/server/pialert.IP.log"
  ln -s "$PIALERT_HOME/log/pialert.1.log" "$PIALERT_HOME/front/php/server/pialert.1.log"
  ln -s "$PIALERT_HOME/log/pialert.cleanup.log" "$PIALERT_HOME/front/php/server/pialert.cleanup.log"
  ln -s "$PIALERT_HOME/log/pialert.webservices.log" "$PIALERT_HOME/front/php/server/pialert.webservices.log"

}

# ------------------------------------------------------------------------------
# Test Pi.Alert
# ------------------------------------------------------------------------------
test_pialert() {
  print_msg "- Testing Pi.Alert HW vendors database update process..."
  print_msg "*** PLEASE WAIT A COUPLE OF MINUTES..."
  stdbuf -i0 -o0 -e0 $PYTHON_BIN $PIALERT_HOME/back/pialert.py update_vendors_silent  2>&1 | tee -ai "$LOG"

  echo ""
  print_msg "- Testing Pi.Alert Internet IP Lookup..."
  stdbuf -i0 -o0 -e0 $PYTHON_BIN $PIALERT_HOME/back/pialert.py internet_IP            2>&1 | tee -ai "$LOG"

  echo ""
  print_msg "- Testing Pi.Alert Network scan..."
  print_msg "*** PLEASE WAIT A COUPLE OF MINUTES..."
  stdbuf -i0 -o0 -e0 $PYTHON_BIN $PIALERT_HOME/back/pialert.py 1                      2>&1 | tee -ai "$LOG"
}

# ------------------------------------------------------------------------------
# Check Pi.Alert Installation Path
# ------------------------------------------------------------------------------
check_pialert_home() {
  if [ ! -e "$PIALERT_HOME" ] ; then
    process_error "Pi.Alert directory dosn't exists: $PIALERT_HOME"
  fi
}

# ------------------------------------------------------------------------------
# Check Python versions available
# ------------------------------------------------------------------------------
check_python_version() {
  print_msg "- Checking Python..."
  if [ -f /usr/bin/python ] ; then
    # PYTHON_BIN="python"
    print_msg "Python 2 no longer supported by Pi.Alert"
  fi

  if [ -f /usr/bin/python3 ] ; then
    PYTHON_BIN="python3"
    print_msg "Python 3 is installed on your system"
    sudo pip3 install mac-vendor-lookup
    sudo pip3 install fritzconnection
  else
    process_error "Python 3 NOT installed"
  fi
}


# ------------------------------------------------------------------------------
# Move Logfile
# ------------------------------------------------------------------------------
move_logfile() {
  NEWLOG="$PIALERT_HOME/log/$LOG"

  mkdir -p "$PIALERT_HOME/log"
  mv $LOG $NEWLOG

  LOG="$NEWLOG"
  NEWLOG=""
}

# ------------------------------------------------------------------------------
# Log
# ------------------------------------------------------------------------------
log() {
  echo "$1" | tee -a "$LOG"
}

log_no_screen () {
  echo "$1" >> "$LOG"
}

log_only_screen () {
  echo "$1"
}

print_msg() {
  log_no_screen ""
  log "$1"
}

print_superheader() {
  log ""
  log "############################################################"
  log " $1"
  log "############################################################"  
}

print_header() {
  log ""
  log "------------------------------------------------------------"
  log " $1"
  log "------------------------------------------------------------"
}

process_error() {
  log ""
  log "************************************************************"
  log "************************************************************"
  log "**             ERROR UPDATING PI.ALERT                    **"
  log "************************************************************"
  log "************************************************************"
  log ""
  log "$1"
  log ""
  log "Use 'cat $LOG' to view update log"
  log ""

  exit 1
}

# ------------------------------------------------------------------------------
  main
  exit 0
