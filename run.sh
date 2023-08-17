#!/bin/bash

################################################################################
# Help
################################################################################
Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "Syntax: [-b|r][-c|d|l][-e][-f][-p profile][-v][-h]"
   echo "options:"
   echo "b     Backup"
   echo "r     Restore"
   echo "c     Create containers and volumes"
   echo "d     Destroy the running containers and volumes"
   echo "l     List Profiles"
   echo "e     Specify an environment (.env) file; default=${ENV_FILE}"
   echo "f     Specify that destroy should not only remove volumes but container images as well"
   echo "p     Add profile for create|destroy operation; e.g. '-p nats'"
   echo "v     Print version."
   echo "h     Print this Help."
  #  echo "v     Verbose mode."
  #  echo "V     Print software version and exit."
   echo
}

################################################################################
# ListProfiles
################################################################################
ListProfiles()
{
  echo "Available Profile(s):"
  count=1
  for i in "${PROFILES[@]}"
  do
    description=${i//|/ - }
    echo -e "${count}. ${description}"
    ((count++))
  done
}

################################################################################
# Backup
################################################################################
Backup()
{
  # TODO: Add backup steps
  echo "No backup setup";
}

################################################################################
# Restore
################################################################################
Restore()
{
  # TODO: Add restore steps
  echo "No restore setup";
}

################################################################################
# Version
################################################################################
Version()
{
  if [ ! -f .version ]; then
    echo "No Version Found";
  else
    while read -r line; do echo "Version = $line" ; done < .version
  fi
}

################################################################################
# IsContainerRunning
################################################################################
IsContainerRunning()
{
  [[ -z "${1}" ]] && echo "No container name provided; exiting execution" && \
    exit 5;

  echo "Checking if the container named '${1}' is running";
  isRunning=$(docker ps -q --filter="name=${1}" --filter="status=running")
  [[ -z "${isRunning}" ]] && \
    echo "'${1}' container is not running; exiting execution" && \
    exit 5;
}

################################################################################
# Create
################################################################################
Create()
{
  docker compose --env-file=${ENV_FILE} ${CMD_OPTIONS} up -d
}

################################################################################
# Destroy
################################################################################
Destroy()
{
  docker compose --env-file=${ENV_FILE} ${CMD_OPTIONS} down ${DESTROY_OPTIONS}
}

################################################################################
# Init
################################################################################
Init()
{
  # check to see if the environment file exists
  [[ ! -f "${ENV_FILE}" ]] && \
      echo "Docker environment file does not exist; exiting execution" && \
      exit 5;
}

################################################################################
################################################################################
# Main program
################################################################################
################################################################################
PROFILES=(
"all|Runs all services and applications, including the simple simulator"
"nats|Runs the NATS message broker"
"simulator|Runs the simple simulator"
"feeder1|Runs the OpenFMB adapters for feeder 1"
"feeder2|Runs the OpenFMB adapters for feeder 2"
  );
CMD_OPTIONS="";
DESTROY_OPTIONS="-v";
CREATE=0;
DESTROY=0;
ENV_FILE=../config/docker/.env

################################################################################
# Process the input options. Add options as needed.
################################################################################
# Get the options
while getopts "e:p:bcdfhlrv" option; do

    # setup certs if dir missing
    if [[ ! -d certs ]]; then
      cd ..
      mkdir certs
      pushd certs
      CAROOT=. mkcert -install
      CAROOT=. mkcert -cert-file server-cert.pem -key-file server-key.pem localhost 127.0.0.1 $IP ::1
      popd
      cd -
    fi

   case $option in
      b) # backup
        Backup
        ;;
      c) # create
        [[ ${DESTROY} -eq 1 ]] && echo "Invalid option; both create and destroy flags set; exiting execution" && exit 22;
        CREATE=1
        ;;
      d) # destroy
        [[ ${CREATE} -eq 1 ]] && echo "Invalid option; both create and destroy flags set; exiting execution" && exit 22;
        DESTROY=1
        ;;
      e) # override environment file path
        ENV_FILE=${OPTARG}
        ;;
      f) # remove images
        DESTROY_OPTIONS="--rmi all -v --remove-orphans"
        ;;
      l) # list available profiles
        ListProfiles
        exit
        ;;
      p) # add profile
        echo "profile=${OPTARG}"
        CMD_OPTIONS+=" --profile=${OPTARG}"
        ;;
      r) # restore
        Restore
        ;;
      v) # version
        Version
        exit
        ;;
      h) # display Help
         Help
         exit
        ;;
      \?) # capture invalid input
        echo "Invalid input found; to see help re-run using -h"
        exit 1
        ;;
   esac
done

Init

echo "Environment file: ${ENV_FILE}";
[[ ${CREATE} -eq 1 ]] && Create
[[ ${DESTROY} -eq 1 ]] && Destroy

echo "Done."
