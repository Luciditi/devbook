#!/usr/bin/env sh

# Set stop on error / enable debug
set -euo pipefail
#set -vx

############################################################################
# ADD DEVBOOK CONFIG
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
  if [[ -z $1 ]]; then MESSAGE="An error has occurred"; else MESSAGE=$1; fi
  if [[ -z $2 ]]; then ERROR_CODE=1; else ERROR_CODE=$2; fi
  echo "$MESSAGE" 1>&2; exit "$ERROR_CODE";
}

# Retrieve an Ansible var in playbook.
ansible_var() {
  if [[ ! -z "$1" ]]; then
    VAR="$1"
    echo $(ansible-playbook main.yml -i inventory --tags "get-var" --extra-vars "var_name=$VAR" | grep "$VAR" | sed -e 's/[[:space:]]*"\([^"]*\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/g' | sed -e "s/\"$VAR\": null//g" | sed -e "s/VARIABLE IS NOT DEFINED!//g" )
  fi
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

REPO="https://github.com/Luciditi/devbook-config.git"

##}}}#######################################################################

#/ Usage: $SCRIPT [CONFIG_DIR]
#/
#/   <CONFIG_URL>: Create a new config in $CONFIG_DIR under the .devbook dir.
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

# Check for .devbook config dir.
PWD=$(pwd)
if [[ ! -d "$PWD/.devbook" ]]; then
  mkdir "$PWD/.devbook"
  echo ""
  echo "${C_HIL}Created ${C_WAR}.devbook${C_RES}${C_HIL}...${C_RES}"
fi


# Create new devbook config
CONFIG_NAME=${1:-devbook-config}
if [[ ! -d "$PWD/.devbook/$CONFIG_NAME" ]]; then
  git clone "$REPO" ".devbook/$CONFIG_NAME"
  rm -rf "$PWD/.devbook/$CONFIG_NAME/.git"
  echo ""
  echo "${C_HIL}Created new devbook config ${C_WAR}.devbook/$CONFIG_NAME${C_RES}${C_HIL}...${C_RES}"
fi

exit 0
