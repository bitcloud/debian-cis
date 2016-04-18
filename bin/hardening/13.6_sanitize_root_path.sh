#!/bin/bash

#
# CIS Debian 7 Hardening
#

#
# 13.6 Ensure root PATH Integrity (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

ERRORS=0

# This function will be called if the script status is on enabled / audit mode
audit () {
    if [ "`echo $PATH | grep :: `" != "" ]; then
        crit "Empty Directory in PATH (::)"
        ERRORS=$((ERRORS+1))
    fi
    if [ "`echo $PATH | grep :$`" != "" ]; then
        crit "Trailing : in PATH $PATH"
        ERRORS=$((ERRORS+1))
    fi
    FORMATTED_PATH=$(echo $PATH | sed -e 's/::/:/' -e 's/:$//' -e 's/:/ /g')
    set -- $FORMATTED_PATH
    while [ "${1:-}" != "" ]; do
        if [ "$1" = "." ]; then
            crit "PATH contains ."
            ERRORS=$((ERRORS+1))
        else
            if [ -d $1 ]; then
                dirperm=$(ls -ldH $1 | cut -f1 -d" ")
                if [ $(echo $dirperm | cut -c6 ) != "-" ]; then
                    crit "Group Write permission set on directory $1"
                    ERRORS=$((ERRORS+1))
                fi
                if [ $(echo $dirperm | cut -c9 ) != "-" ]; then
                    crit "Other Write permission set on directory $1"
                    ERRORS=$((ERRORS+1))
                fi
                dirown=$(ls -ldH $1 | awk '{print $3}')
                if [ "$dirown" != "root" ] ; then
                    crit "$1 is not owned by root"
                    ERRORS=$((ERRORS+1))
                fi
            else
                crit "$1 is not a directory"
                ERRORS=$((ERRORS+1))
            fi
        fi
        shift
    done

    if [ $ERRORS = 0 ]; then
        ok "root PATH is secure"
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    info "Editing items from PATH may seriously harm your system, report only here"
}

# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ ! -r /etc/default/cis-hardening ]; then
    echo "There is no /etc/default/cis-hardening file, cannot source CIS_ROOT_DIR variable, aborting"
    exit 128
else
    . /etc/default/cis-hardening
    if [ -z $CIS_ROOT_DIR ]; then
        echo "No CIS_ROOT_DIR variable, aborting"
    fi
fi 

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
[ -r $CIS_ROOT_DIR/lib/main.sh ] && . $CIS_ROOT_DIR/lib/main.sh
