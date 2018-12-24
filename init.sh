#!/usr/bin/env sh

# Set stop on error / enable debug
set -euo pipefail
DEVBOOK_VERBOSE="${DEVBOOK_VERBOSE:-}"
if [[ "$DEVBOOK_VERBOSE" == "1" ]]; then
  set -o verbose
fi

############################################################################
# INSTALL DEVBOOK
############################################################################

##{{{#######################################################################
############################################################################
# FUNCTIONS
############################################################################

# Clean Upon Exit
cleanup() {
  ERROR_CODE=$?
  if [ "$ERROR_CODE" != "0" ]; then
    echo ""
    # Don't print error message from curlsh run
    if [[ "$SCRIPTS_DIRECTORY" != "/dev/fd" ]]; then
      CWD="$(pwd)"
      quit "${C_ERR}Installation failed. Review the ${C_WAR}PLAY RECAP${C_RES}${C_ERR} (or other errors) for failed tasks and correct the config if necessary.
      Then run ${C_WAR}cd $CWD && ./$INIT${C_ERR} to resume installation.${C_RES}" "$ERROR_CODE"
    fi
  fi
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

# Retrieve optional --tags param
devbook_do_tags() {
  if [[ -f "$DEVBOOK_LIST_FILE" ]]; then
    TAGS=$(paste -sd "," - < "$DEVBOOK_LIST_FILE")
    echo "--tags $TAGS"
  else
    echo ""
  fi
}

# Retrieve the list of skipped and/or finished tags.
devbook_skip_tags() {
  if [[ -f "$DEVBOOK_TAG_FILE" && ! -f "$DEVBOOK_SKIP_FILE" ]]; then
    sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/,/g' "$DEVBOOK_TAG_FILE"
  elif [[ ! -f "$DEVBOOK_TAG_FILE" && -f "$DEVBOOK_SKIP_FILE" ]]; then
    sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/,/g' "$DEVBOOK_SKIP_FILE"
  elif [[ -f "$DEVBOOK_TAG_FILE" && -f "$DEVBOOK_SKIP_FILE" ]]; then
    MERGE=$(mktemp)
    cat "$DEVBOOK_TAG_FILE" "$DEVBOOK_SKIP_FILE" > "$MERGE"
    sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/,/g' "$MERGE"
    rm "$MERGE"
  fi
}

# Get verbosity
devbook_verbosity() {
  if [[ "$DEVBOOK_VERBOSE" == "1" ]]; then
    echo "-vvv"
  else
    echo ""
  fi
}

##}}}#######################################################################

#/ Usage: $SCRIPT [CONFIG_URL]
#/
#/   <CONFIG_URL>: An HTTP URL containing a config.yml to use.
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
while getopts 'fhk' FLAG; do
  case "${FLAG}" in
    h) usage; exit 1 ;;
    f)
      ANSIBLE_SUDO=""
      DEVBOOK_EXT_OPTS="-f"
      KEY_CONFIRM=0
      shift $((OPTIND -1))
      ;;
    k) KEY_FILE_FLAG=1; shift $((OPTIND -1)); ;;
    *) : ;;
  esac
done

############################################################################
# VARS
############################################################################
# Output colors.
C_HIL="\033[36m"
C_WAR="\033[33m"
C_SUC="\033[32m"
C_ERR="\033[31m"
C_RES="\033[0m"

# SUPRESS ANSIBLE_DEPRECATION
export ANSIBLE_DEPRECATION_WARNINGS=0
ANSIBLE_SUDO=${ANSIBLE_SUDO:--K}
CONFIG=${1:-config.yml}
DEVBOOK_BRANCH=${DEVBOOK_BRANCH:=mk2}
DEVBOOK_EXT_OPTS=""
DEVBOOK_VERSION=${DEVBOOK_VERSION:=2.0.0}
DEVBOOK_NOTES="NOTES.md"
DEVBOOK_LIST_FILE=".devbook.list"
DEVBOOK_TAG_FILE=".devbook.tags"
DEVBOOK_SKIP_FILE=".devbook.skip"
INIT="init.sh"
KEY_CONFIRM="1"
KEY_FILE="$HOME/.ssh/id_rsa"
KEY_FILE_COMMENT="$USER@devbook-$DEVBOOK_VERSION-$CONFIG"
KEY_FILE_FLAG=0
REPO="https://github.com/Luciditi/devbook.git"
SCRIPTS_DIRECTORY="$(dirname $0)"


# Retrieve repo if not found
if [[ ! -f "$INIT" ]]; then
  echo "${C_WAR}Retrieving DevBook Repo...${C_RES}"
  echo ""
  git clone "$REPO"
  cd devbook
  git checkout -b "$DEVBOOK_BRANCH" "$DEVBOOK_VERSION"
  KEY_FLAG=$(echo ${KEY_FILE_FLAG} | sed -e 's/1/-k/g' | sed -e 's/0//g')
  "./$INIT" $KEY_FLAG "$@"
  exit 0
fi


# We will ride eternal, shiny and chrome!
cat << "EOF"
=======================================================================================================
|                                                                                                     |
|  #################     +++++                             +++                              ,,,       |
|  @###############@     ++++++++                          +++                              +++       |
|  @               @     +++++++++                         +++                              +++       |
|  @               @     +++   ++++      ++                +++  +         ++         +      +++       |
|  @      `@@      @     +++     +++    ++++    ++     +++ +++ ++++     +++++      +++++    +++  +++  |
|  @   @@+.#@ : `  @     +++     +++  ++++++++  +++    ++  +++++++++   +++++++    +++++++   +++ +++   |
|  @  ,@ @ .`. ,'  @     +++     +++  +++   ++   ++   +++  ++++   ++  +++   +++  +++   +++  ++++++    |
|  @  `@@@    ,    @     +++     +++  ++++++++   +++  ++   +++    +++ +++    +++ +++    +++ +++++     |
|  @    :          @     +++     +++  ++++++++    ++ +++   +++    +++ +++    +++ +++    +++ ++++++    |
|  @               @     +++    +++   ++          +++++    +++    +++ +++    +++ +++    +++ +++ ++    |
|  @@@@@@@@@@@@@@@@@     +++++++++    +++   +      ++++    ++++  +++   +++  +++   +++  +++  +++ +++   |
| /@@@@@@@@@@@@@@@@@\    ++++++++      +++++++     +++     +++++++++    ++++++    +++++++   +++  +++  |
|@@@@@@@@@@@@@@@@@@@@@   ++++++         ++++        ++      ++ +++       ++++       ++++    +++   +++ |
|                                                                                                     |
=======================================================================================================
EOF
VERBOSE_OPT=$(devbook_verbosity)


# Use specified config
if [[ "$CONFIG" != "config.yml" ]]; then
  echo ""
  echo "${C_HIL}Using ${C_WAR}$CONFIG${C_RES}${C_HIL} for ${C_WAR}config.yml${C_RES}${C_HIL}...${C_RES}"
  curl -sL "$CONFIG" > config.yml
fi


# Create a ssh key
if [[ "$KEY_FILE_FLAG" == "1" && ! -f "$KEY_FILE" ]]; then
  echo ""
  echo "${C_HIL}Creating ${C_WAR}$KEY_FILE${C_RES}${C_HIL}...${C_RES}"
  ssh-keygen -f "$KEY_FILE" -t rsa -N '' -C "$KEY_FILE_COMMENT"
  cat "$KEY_FILE.pub" >> "$HOME/.ssh/authorized_keys"
fi


# Add Ansible requirements...
echo ""
echo "${C_HIL}Installing Requirements...${C_RES}"
ansible-galaxy install $VERBOSE_OPT -r requirements.yml


# Note on private repo access
REPO=$(ansible_var prv_repo)
if [[ "$KEY_CONFIRM" == "1" && "$REPO" != "" ]]; then
  echo ""
  echo "${C_SUC}Ensure ${C_WAR}$KEY_FILE.pub${C_RES}${C_SUC} is an allowed key for ${C_WAR}$REPO${C_SUC} then press ${C_WAR}ENTER${C_SUC}.${C_RES}"
  cat "$KEY_FILE.pub"
  read INPUT
fi


# Start Ansible playbook
echo ""
echo "${C_HIL}Installing DevBook...${C_RES}"
SKIP_TAGS=$(devbook_skip_tags)
LIST_TAGS=$(devbook_do_tags)
ansible-playbook main.yml $VERBOSE_OPT -i inventory $ANSIBLE_SUDO --skip-tags "$SKIP_TAGS" $LIST_TAGS

# Execute any other .devbook configs found
if [[ -d "$HOME/.devbook" ]]; then
  CWD="$(pwd)"
  for DEVBOOK in $(find "$HOME/.devbook/" -maxdepth 1 -type d -not -path "$HOME/.devbook/" -exec basename {} \;)
  do
    if [[ -f "$HOME/.devbook/$DEVBOOK/init.sh" ]]; then
      echo "${C_HIL}Executing the devbook config ${C_WAR}$HOME/.devbook/$DEVBOOK/init.sh${C_RES}${C_HIL}...${C_RES}"
      echo ""
      cd "$HOME/.devbook/$DEVBOOK/"
      chmod +x ./init.sh && ./init.sh "$DEVBOOK_EXT_OPTS"
    fi
  done
  cd "$CWD"
fi


# Cleanup
echo ""
if [[ -f "$DEVBOOK_TAG_FILE" ]]; then
  echo "${C_HIL}Cleanup...${C_RES}"
  rm "$DEVBOOK_TAG_FILE"
fi


# Notes
if [[ -f "$DEVBOOK_NOTES" ]]; then
  if [[ -x $(command -v "$HOME/.bin/vcat") ]]; then
    "$HOME/.bin/vcat" "$DEVBOOK_NOTES"
  else
    cat "$DEVBOOK_NOTES"
  fi
fi

echo "${C_SUC}Devbook installation complete!${C_RES}"
exit 0
