#!/bin/bash

ACTIONS=(\
    show_help \
    generate_app_version_tsuru \
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

function generate_app_version_tsuru() {
    set -e

    TOKEN=`curl -s --data "email=$EMAIL&password=$PASSWORD" "$TSURU_HOST/auth/login" | sed 's/{"token":"//' | sed 's/"}//'`
    CURRENT_VERSION=`curl -s -H "Authorization: $TOKEN" "$TSURU_HOST/apps/$TSURU_APPNAME" | sed 's/^.*"deploys"://' | sed 's/[^0-9].*$//'`

    if [ -z "$CURRENT_VERSION" ]; then
        CURRENT_VERSION=-2;
    fi

    echo APP_CURRENT_VERSION=$(($CURRENT_VERSION+1)) >> APP_EXTRA_ENV
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
