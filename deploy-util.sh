#!/bin/bash

set -x

ACTIONS=(\
    show_help \
    generate_app_version_tsuru \
    get_tsuru_node \
    run_tsuru_app \
    run_on_tsuru_deploy \
    update_tzdata_if_needed \
    set_env_vars_for_process \
    snitch_deploy \
)

EMAIL='ti@eduk.com.br'
PASSWORD=$TSURU_DEPLOY_USER_PASSWORD

function is_action_defined() {
    action=$1
    case ${ACTIONS[@]} in *$action*) true;; *) false;; esac
}

function print_error_and_exit() {
    >&2 echo "Error: $1"
    exit 1
}

function show_help() {
    echo "Usage: $0 <action> [options]"
    echo "Avaiable actions: "
    for action in ${ACTIONS[@]}; do
        echo "  $action"
    done
}

function snitch_deploy() {
    set -e
    curl -sSL https://github.com/lucasgomide/snitch/releases/download/0.4.0/snitch_0.4.0_linux_amd64.tar.gz | tar xz
    source ./APP_EXTRA_ENV
    cat > snitch.yml << EOF
hangouts_chat:
  webhook_url: \$GOOGLE_CHAT_HOOK_URL
newrelic:
  host: https://api.newrelic.com
  application_id: \$NEW_RELIC_APP_ID
  api_key: \$NEW_RELIC_API_KEY
  revision: "$APP_CURRENT_VERSION"
EOF
    ./snitch_linux/snitch -c snitch.yml -app-name-contains prd
}

function generate_app_version_tsuru() {
    set -e

    TOKEN=`curl -s --data "email=$EMAIL&password=$PASSWORD" "$TSURU_HOST/auth/login" | sed 's/{"token":"//' | sed 's/"}//'`
    CURRENT_VERSION=`curl -s -H "Authorization: $TOKEN" "$TSURU_HOST/apps/$TSURU_APPNAME" | sed 's/^.*"deploys"://' | sed 's/[^0-9].*$//'`

    if [ -z "$CURRENT_VERSION" ]; then
        CURRENT_VERSION=-2;
    fi

    echo APP_CURRENT_VERSION=$(($CURRENT_VERSION+1)) >> APP_EXTRA_ENV
}

function set_env_vars_for_process() {
    set -e

    TOKEN=`curl -s --data "email=$EMAIL&password=$PASSWORD" "$TSURU_HOST/auth/login" | sed 's/{"token":"//' | sed 's/"}//'`
    PROCESS_NAME=$(curl -s -H "Authorization: $TOKEN" "$TSURU_HOST/apps/$TSURU_APPNAME" | jq '.units[] | {(.ID): (.ProcessName)}' | grep -B1 -A1 `hostname` | jq ".[]" | sed 's/"//g')

    if [ -z "$PROCESS_NAME" ]; then
      echo "Cannot set env-vars because PROCESS_NAME is not available for `hostname`"
      return
    fi

    ENVS_TO_SET=`env | grep -i ^${PROCESS_NAME}__ | cut -d= -f1`
    for varname in $ENVS_TO_SET; do
      FINAL_ENV=`echo $varname | sed 's/^[A-Z]*__//'`
      echo "Setting env-vars to ${PROCESS_NAME} process: ${FINAL_ENV}='${!varname}'"
      export ${FINAL_ENV}="${!varname}"
    done
}

function get_tsuru_node() {
    set -e

    TOKEN=`curl -s --request POST --data "email=$EMAIL&password=$PASSWORD" "$TSURU_HOST/auth/login" | sed 's/{"token":"//' | sed 's/"}//'`
    HOST=$(curl -s -H "Authorization: $TOKEN" "$TSURU_HOST/apps/$TSURU_APPNAME" | jq '.units[] | {(.ID): (.IP)}' | grep -B1 -A1 `hostname` | jq ".[]")

    if [ -z "$HOST" ]; then
        HOST=xxxx;
    fi

    echo $HOST;
}

function update_tzdata_if_needed() {
    set -e

    TZDATA_MIN_VER="2018g"
    CURRENT_TZDATA_VERSION=$(dpkg-query -W -f='${Version}' tzdata || echo 0)

    if [ ! -f /etc/localtime ]; then
        sudo ln -fs /usr/share/zoneinfo/Universal /etc/localtime
    fi

    if [[ $CURRENT_TZDATA_VERSION < $TZDATA_MIN_VER ]]; then
        echo
        echo "tzdata is outdated. Trying to upgrade from apt..."
        echo

        sudo apt --yes --assume-yes --force-yes update
        sudo DEBIAN_FRONTEND=noninteractive apt --yes --assume-yes --force-yes install tzdata
        sudo rm -rf /var/lib/apt/lists/*
    fi

    CURRENT_TZDATA_VERSION=$(dpkg-query  -W -f='${Version}' tzdata)

    if [[ $CURRENT_TZDATA_VERSION < $TZDATA_MIN_VER ]]; then
        echo
        echo "tzdata is still outdated. Using custom package..."
        echo

        CUSTOM_PACKAGE_ORIGIN="https://s3.amazonaws.com/eduk-packages"
        CUSTOM_PACKAGE_NAME="tzdata_2018e-eduk02-0ubuntu0.14.04_all.deb"

        sudo curl -o /root/$CUSTOM_PACKAGE_NAME -O $CUSTOM_PACKAGE_ORIGIN/$CUSTOM_PACKAGE_NAME
        sudo dpkg -i /root/$CUSTOM_PACKAGE_NAME
        sudo rm /root/$CUSTOM_PACKAGE_NAME
    fi

    sudo apt-get clean
}

function run_on_tsuru_deploy() {
    set -e

    update_tzdata_if_needed
    generate_app_version_tsuru
    snitch_deploy
}

function run_tsuru_app() {
    set -e

    set_env_vars_for_process
    env `cat APP_EXTRA_ENV` TSURU_NODE=`get_tsuru_node` $@
}

if [ $# -lt 1 ]; then
    show_help
    print_error_and_exit "Syntax error"
fi

action=$1
shift
if ! is_action_defined $action; then
    print_error_and_exit "unknow action $action"
fi

$action $@
