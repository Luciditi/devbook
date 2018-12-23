#!/usr/bin/env sh

# Set stop on error / enable debug
set -euo pipefail
#set -vx

############################################################################
# BOOTSTRAP DEVBOOK
############################################################################

##{{{#######################################################################
############################################################################
# FUNCTIONS
############################################################################

# Clean Upon Exit
cleanup() {
  :
}
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  trap cleanup EXIT
fi

# Print a string line wrapped in "===" headers
printline() {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =
  printf "%s\n" "$1"
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =
}

#  Logging functions
readonly LOG_FILE="/tmp/$(basename "$0").log"
info()    { echo "[INFO]    $*" | tee -a "$LOG_FILE" >&2 ; }
warning() { echo "[WARNING] $*" | tee -a "$LOG_FILE" >&2 ; }
error()   { echo "[ERROR]   $*" | tee -a "$LOG_FILE" >&2 ; }
fatal()   { echo "[FATAL]   $*" | tee -a "$LOG_FILE" >&2 ; exit 1 ; }

# Accept Message & Error Code
quit() {
  if [ -z $1 ]; then MESSAGE="An error has occurred"; else MESSAGE=$1; fi
  if [ -z $2 ]; then ERROR_CODE=1; else ERROR_CODE=$2; fi
  echo "$MESSAGE" 1>&2; exit "$ERROR_CODE";
}

############################################################################
# VARS
############################################################################
# Output colors.
C_HIL="\033[36m"
C_WAR="\033[33m"
C_SUC="\033[32m"
C_ERR="\033[31m"
C_RES="\033[0m"

ANSIBLE_VERSION="2.7.5"
BOOT_CODE="sh <(curl -sL jig.io/dev-init)"
INIT="init.sh"
if [ -f "$INIT" ]; then
  BOOT_CODE="./$INIT"
fi
SCRIPTS_DIRECTORY="$(dirname $0)"
CONFIG_URL=${1-}
PIP_BIN="/usr/local/bin/pip"

##}}}#######################################################################

#/ Usage: $SCRIPT
#/
#/ Examples:
#/ Options:
#/   --help: Display this help message
SCRIPT=$(basename "$0")
usage() { grep '^#/' "$0" | cut -c4- | sed -e 's/\$SCRIPT/'"$SCRIPT"'/g' ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

############################################################################
# MAIN
############################################################################

# Handle options
# Add options x: - required arg
while getopts 'h' FLAG; do
  case "${FLAG}" in
    h) usage; exit 1 ;;
    *) : ;;
  esac
done

echo "${C_HIL}Bootstrapping Ansible $ANSIBLE_VERSION... ${C_RES}"

# Run Xcode CLI Install
CLI_TEST=$(bash -c "xcode-select -p 2>/dev/null;echo ''")
if [ -z "$CLI_TEST" ]; then
  echo "${C_SUC}  - Launching XCode CLI DevTools installer press ${C_WAR}ENTER${C_RES}${C_SUC} when finished... ${C_RES}"
  xcode-select --install
  read -r
fi

# Run Ansible Install
echo "${C_SUC}  - Installing pip & Ansible $ANSIBLE_VERSION. Please enter ${C_WAR}$USER${C_RES}${C_SUC}'s password to install... ${C_RES}"
sudo easy_install pip
bash -c "sudo $PIP_BIN install ansible==$ANSIBLE_VERSION"


# Instructions
echo "${C_SUC}Ansible installed! Execute one of the following commmands: ${C_RES}"
echo ""

echo "${C_SUC}1. Full Install                    :   ${C_WAR}$BOOT_CODE${C_RES}"
echo "${C_SUC}2. Full Install (w/ key install)   :   ${C_WAR}$BOOT_CODE -k ${C_RES}"
echo "${C_SUC}3. Partial Install                 :   ${C_WAR}$BOOT_CODE jig.io/devbook-config-mini${C_RES}"
echo "${C_SUC}4. Partial Install (w/ key install):   ${C_WAR}$BOOT_CODE -k jig.io/devbook-config-mini${C_RES}"
if [[ ! -z "$CONFIG_URL" ]]; then
  echo "${C_SUC}5. Custom Install                  :   ${C_WAR}$BOOT_CODE $CONFIG_URL${C_RES}"
  echo "${C_SUC}6. Custom Install (w/ key install) :   ${C_WAR}$BOOT_CODE -k $CONFIG_URL${C_RES}"
fi
echo ""

read -t 10 -p "Select Option:" OPTION
echo ""

RUN_CODE=""
case $OPTION in
  1) RUN_CODE="$BOOT_CODE" ;;
  2) RUN_CODE="$BOOT_CODE -k" ;;
  3) RUN_CODE="$BOOT_CODE jig.io/devbook-config-mini" ;;
  4) RUN_CODE="$BOOT_CODE -k jig.io/devbook-config-mini" ;;
  5)
    if [[ ! -z "$CONFIG_URL" ]]; then
      RUN_CODE="$BOOT_CODE $CONFIG_URL"
    fi
    ;;
  6)
    if [[ ! -z "$CONFIG_URL" ]]; then
      RUN_CODE="$BOOT_CODE -k $CONFIG_URL"
    fi
    ;;
esac

if [[ ! -z "$RUN_CODE" ]]; then
  echo "Executing: ${C_WAR}$RUN_CODE${C_RES}"
  eval "$RUN_CODE"
fi

exit 0
