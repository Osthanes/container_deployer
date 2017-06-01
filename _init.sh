#!/bin/bash

#********************************************************************************
# Copyright 2014 IBM
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#********************************************************************************

#############
# Colors    #
#############
export green='\e[0;32m'
export red='\e[0;31m'
export label_color='\e[0;33m'
export no_color='\e[0m' # No Color

########################################
# default values to build server names #
########################################
# beta servers
BETA_API_PREFIX="api-ice"
BETA_REG_PREFIX="registry-ice"
# default servers
DEF_API_PREFIX="containers-api"
DEF_REG_PREFIX="registry"
export MODULE_NAME="container-deployer"

##################################################
# Simple function to only run command if DEBUG=1 # 
### ###############################################
debugme() {
  [[ $DEBUG = 1 ]] && "$@" || :
}

installwithpython27() {
    echo "Installing Python 2.7"
    sudo apt-get update &> /dev/null
    sudo apt-get -y install python2.7 &> /dev/null
    python --version 
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py &> /dev/null
    python get-pip.py --user &> /dev/null
    export PATH=$PATH:~/.local/bin
    if [ -f icecli-3.0.zip ]; then 
        debugme echo "there was an existing icecli.zip"
        debugme ls -la 
        rm -f icecli-3.0.zip
    fi 
    wget https://static-ice.ng.bluemix.net/icecli-3.0.zip &> /dev/null
    pip install --user icecli-3.0.zip > cli_install.log 2>&1 
    debugme cat cli_install.log 
}

installwithpython34() {
    curl -kL http://xrl.us/pythonbrewinstall | bash
    source $HOME/.pythonbrew/etc/bashrc
    sudo apt-get install zlib1g-dev libexpat1-dev libdb4.8-dev libncurses5-dev libreadline6-dev
    sudo apt-get update &> /dev/null
    debugme pythonbrew list -k
    echo "Installing Python 3.4.1"
    pythonbrew install 3.4.1 &> /dev/null
    debugme cat /home/jenkins/.pythonbrew/log/build.log 
    pythonbrew switch 3.4.1
    python --version 
    echo "Installing pip"
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py &> /dev/null
    python get-pip.py --user
    export PATH=$PATH:~/.local/bin
    which pip 
    echo "Installing ice cli"
    wget https://static-ice.ng.bluemix.net/icecli-3.0.zip &> /dev/null
    wget https://static-ice.ng.bluemix.net/icecli-3.0.zip
    pip install --user icecli-3.0.zip > cli_install.log 2>&1 
    debugme cat cli_install.log 
}

installwithpython277() {
    pushd $EXT_DIR >/dev/null
    echo "Installing Python 2.7.7"
    curl -kL http://xrl.us/pythonbrewinstall | bash
    source $HOME/.pythonbrew/etc/bashrc

    sudo apt-get update &> /dev/null
    sudo apt-get build-dep python2.7
    sudo apt-get install zlib1g-dev
    debugme pythonbrew list -k
    echo "Installing Python 2.7.7"
    pythonbrew install 2.7.7 --no-setuptools &> /dev/null
    debugme cat /home/jenkins/.pythonbrew/log/build.log 
    pythonbrew switch 2.7.7
    python --version 
    echo "Installing pip"
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py &> /dev/null
    python get-pip.py --user &> /dev/null
    debugme pwd 
    debugme ls 
    popd >/dev/null
    pip remove requests
    pip install --user -U requests 
    pip install --user -U pip
    export PATH=$PATH:~/.local/bin
    which pip 
    echo "Installing ice cli"
    wget https://static-ice.ng.bluemix.net/icecli-3.0.zip &> /dev/null
    pip install --user icecli-3.0.zip > cli_install.log 2>&1 
    debugme cat cli_install.log 
}
installwithpython3() {

    sudo apt-get update &> /dev/null
    sudo apt-get upgrade &> /dev/null 
    sudo apt-get -y install python3 &> /dev/null
    python3 --version 
    echo "installing pip"
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py 
    python3 get-pip.py --user &> /dev/null
    export PATH=$PATH:~/.local/bin
    which pip 
    echo "installing ice cli"

    wget https://static-ice.ng.bluemix.net/icecli-3.0.zip
    pip install --user icecli-3.0.zip > cli_install.log 2>&1 
    debugme cat cli_install.log 
}
if [[ $DEBUG = 1 ]]; then 
    export ICE_ARGS="--verbose"
else
    export ICE_ARGS=""
fi 

set +e
set +x 

###############################
# Configure extension PATH    #
###############################
if [ -n $EXT_DIR ]; then 
    export PATH=$EXT_DIR:$PATH
else
    export EXT_DIR=`pwd`
fi 

#########################################
# Configure log file to store errors  #
#########################################
if [ -z "$ERROR_LOG_FILE" ]; then
    ERROR_LOG_FILE="${EXT_DIR}/errors.log"
    export ERROR_LOG_FILE
fi

#################################
# Source git_util sh file       #
#################################
source ${EXT_DIR}/git_util.sh

################################
# get the extensions utilities #
################################
pushd . >/dev/null
cd $EXT_DIR 
if [ -n "${OVERRIDE_UTILITIES_BRANCH}" ]; then
    echo "Pulling utilities from branch ${OVERRIDE_UTILITIES_BRANCH}"
    git_retry clone https://github.com/Osthanes/utilities.git -b "${OVERRIDE_UTILITIES_BRANCH}" utilities
else
    git_retry clone https://github.com/Osthanes/utilities.git utilities
fi
popd >/dev/null

################################
# Source utilities sh files    #
################################
source ${EXT_DIR}/utilities/ice_utils.sh
source ${EXT_DIR}/utilities/logging_utils.sh

########################
# setup deploy property file #
########################
# create deploy property file.
if [ -z ${DEPLOY_PROPERTY_FILE} ]; then
    export DEPLOY_PROPERTY_FILE="${EXT_DIR}/deploy-property.sh"
fi
if [ -f "${DEPLOY_PROPERTY_FILE}" ]; then
    /bin/rm -f ${DEPLOY_PROPERTY_FILE}
fi
/bin/touch ${DEPLOY_PROPERTY_FILE}
chmod +x $DEPLOY_PROPERTY_FILE
echo '#!/bin/bash' >> "${DEPLOY_PROPERTY_FILE}"

#############################
# Install Cloud Foundry CLI #
#############################
CF_VER=$(cf -v)
log_and_echo "$INFO" "Existing Cloud Foundry CLI ${CF_VER}"
log_and_echo "$INFO" "Installing Cloud Foundry CLI"
pushd $EXT_DIR >/dev/null
gunzip cf-linux-amd64.tgz &> /dev/null
tar -xvf cf-linux-amd64.tar  &> /dev/null
cf help &> /dev/null
RESULT=$?
if [ $RESULT -ne 0 ]; then
    log_and_echo "$ERROR" "Could not install the Cloud Foundry CLI"
    ${EXT_DIR}/print_help.sh
    ${EXT_DIR}/utilities/sendMessage.sh -l bad -m "Failed to install Cloud Foundry CLI. $(get_error_info)"
    exit $RESULT
fi
CF_VER=$(cf -v)
popd >/dev/null
log_and_echo "$LABEL" "Successfully installed Cloud Foundry CLI ${CF_VER}"

#####################################
# Install IBM Container Service CLI #
#####################################
# Install ICE CLI
log_and_echo "$INFO" "Installing IBM Container Service CLI"
ice help &> /dev/null
RESULT=$?
if [ $RESULT -ne 0 ]; then
#    installwithpython3
    installwithpython27
#    installwithpython277
#    installwithpython34
    ice help &> /dev/null
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        log_and_echo "$ERROR" "Failed to install IBM Container Service CLI"
        debugme python --version
        if [ "$USE_ICE_CLI" = "1" ]; then
            ${EXT_DIR}/print_help.sh
            ${EXT_DIR}/utilities/sendMessage.sh -l bad -m "Failed to install IBM Container Service CLI. $(get_error_info)"
            exit $RESULT
        fi
    else
        log_and_echo "$LABEL" "Successfully installed IBM Container Service CLI"
    fi
fi 

#############################################
# Install the IBM Containers plug-in (cf ic) #
#############################################
if [ "$USE_ICE_CLI" != "1" ]; then
    export IC_COMMAND="${EXT_DIR}/cf ic"
    install_cf_ic
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        exit $RESULT
    fi
else
    export IC_COMMAND="ice"
fi

##########################################
# setup bluemix env
##########################################
# attempt to  target env automatically
if [ -n "$BLUEMIX_TARGET" ]; then
    # cf not setup yet, try manual setup
    if [ "$BLUEMIX_TARGET" == "staging" ]; then 
        echo -e "Targetting staging Bluemix"
        export BLUEMIX_API_HOST="api.stage1.ng.bluemix.net"
    elif [ "$BLUEMIX_TARGET" == "prod" ]; then 
        echo -e "Targetting production Bluemix"
        export BLUEMIX_API_HOST="api.ng.bluemix.net"
    else 
        echo -e "${red}Unknown Bluemix environment specified: ${BLUEMIX_TARGET}${no_color}" | tee -a "$ERROR_LOG_FILE"
        echo -e "Targetting production Bluemix"
        export BLUEMIX_TARGET="prod"
        export BLUEMIX_API_HOST="api.ng.bluemix.net"
    fi 
else
    CF_API=$(${EXT_DIR}/cf api)
    RESULT=$?
    debugme echo "CF_API: ${CF_API}"
    if [ $RESULT -eq 0 ]; then
        # find the bluemix api host
        export BLUEMIX_API_HOST=`echo $CF_API  | awk '{print $3}' | sed '0,/.*\/\//s///'`
        echo $BLUEMIX_API_HOST | grep 'stage1'
        if [ $? -eq 0 ]; then
            # on staging, make sure bm target is set for staging
            export BLUEMIX_TARGET="staging"
        else
            # on prod, make sure bm target is set for prod
            export BLUEMIX_TARGET="prod"
        fi
    else 
        echo -e "Targetting production Bluemix"
        export BLUEMIX_TARGET="prod"
        export BLUEMIX_API_HOST="api.ng.bluemix.net"
    fi
fi
echo -e "Bluemix host is '${BLUEMIX_API_HOST}'"
echo -e "Bluemix target is '${BLUEMIX_TARGET}'"
# strip off the hostname to get full domain
CF_TARGET=`echo $BLUEMIX_API_HOST | sed 's/[^\.]*//'`
if [ -z "$API_PREFIX" ]; then
    API_PREFIX=$DEF_API_PREFIX
fi
if [ -z "$REG_PREFIX" ]; then
    REG_PREFIX=$DEF_REG_PREFIX
fi
# build api server hostname
export CCS_API_HOST="${API_PREFIX}${CF_TARGET}"
# build registry server hostname
export CCS_REGISTRY_HOST="${REG_PREFIX}${CF_TARGET}"
# set up the ice cfg
sed -i "s/ccs_host =.*/ccs_host = $CCS_API_HOST/g" $EXT_DIR/ice-cfg.ini
sed -i "s/reg_host =.*/reg_host = $CCS_REGISTRY_HOST/g" $EXT_DIR/ice-cfg.ini
sed -i "s/cf_api_url =.*/cf_api_url = $BLUEMIX_API_HOST/g" $EXT_DIR/ice-cfg.ini
export ICE_CFG="ice-cfg.ini"

################################
# Login to Container Service   #
################################
login_to_container_service
RESULT=$?
if [ $RESULT -ne 0 ] && [ "$USE_ICE_CLI" = "1" ]; then
    exit $RESULT
fi

############################
# enable logging to logmet #
############################
setup_met_logging "${BLUEMIX_USER}" "${BLUEMIX_PASSWORD}"
RESULT=$?
if [ $RESULT -ne 0 ]; then
    log_and_echo "$WARN" "LOGMET setup failed with return code ${RESULT}"
fi

################################
# Get the namespace            #
################################
get_name_space
RESULT=$?
if [ $RESULT -ne 0 ]; then
    exit $RESULT
fi 

##############################
# Identify the Image to use  #
##############################
# If the IMAGE_NAME is set in the environment then use that.  
# Else assume the input is coming from the build.properties created and archived by the Docker builder job
if [ -z $IMAGE_NAME ]; then
    debugme echo "finding build.properties"
    debugme pwd 
    debugme ls

    if [ -f build.properties ]; then
        . build.properties 
        export IMAGE_NAME
        debugme cat build.properties
        echo "IMAGE_NAME: $IMAGE_NAME"
    fi  
    if [ -z $IMAGE_NAME ]; then
        log_and_echo "$ERROR" "IMAGE_NAME not set. Set the IMAGE_NAME in the environment or provide a Docker build job as input to this deploy job."
        log_and_echo "$ERROR" "If there was a recent change to the pipeline, such as deleting or moving a job or stage, check that the input to this and other later stages is still set to the correct build stage and job."
        ${EXT_DIR}/print_help.sh
        ${EXT_DIR}/utilities/sendMessage.sh -l bad -m "Failed to get image name. $(get_error_info)"
        exit 1
    fi 
else 
    log_and_echo "$LABEL" "Image being overridden by the environment. Using ${IMAGE_NAME}"
fi 

########################
# Current Limitations  #
########################
if [ -z $IP_LIMIT ]; then 
    export IP_LIMIT=8
fi 
if [ -z $CONTAINER_LIMIT ]; then 
    export CONTAINER_LIMIT=8
fi 

########################
# Adjust Build Number  #
########################
if [ -n "$BUILD_OFFSET" ]; then 
    log_and_echo "$INFO" "Using BUILD_OFFSET of $BUILD_OFFSET"
    export APPLICATION_VERSION=$((APPLICATION_VERSION + BUILD_OFFSET))
    export BUILD_NUMBER=$((BUILD_NUMBER + BUILD_OFFSET))
fi 

log_and_echo "$LABEL" "Initialization complete"

