#!/bin/bash

ACTIONS=(\
    show_help \
)

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
