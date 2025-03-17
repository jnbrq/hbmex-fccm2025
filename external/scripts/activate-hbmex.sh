#!/bin/sh

deactivate_hbmex() {
    if [ -n "${HBMEX_OLD_PATH}" ]; then
        PATH="${HBMEX_OLD_PATH}"
        export PATH
        unset HBMEX_OLD_PATH
    fi

    if [ -n "${HBMEX_OLD_LD_LIBRARY_PATH}" ]; then
        LD_LIBRARY_PATH="${HBMEX_OLD_LD_LIBRARY_PATH}"
        export LD_LIBRARY_PATH
        unset HBMEX_OLD_LD_LIBRARY_PATH
    fi

    if [ -n "${HBMEX_OLD_PYTHONHOME}" ]; then
        PYTHONHOME="${HBMEX_OLD_PYTHONHOME}"
        export PYTHONHOME
        unset HBMEX_OLD_PYTHONHOME
    fi

    hash -r 2> /dev/null

    if [ -n "${HBMEX_OLD_PS1}" ]; then
        PS1="${HBMEX_OLD_PS1}"
        export PS1
        unset HBMEX_OLD_PS1
    fi

    unset HBMEX_PREFIX
    unset VIRTUAL_ENV
    unset -f deactivate_hbmex
}

# Check if the environment is already active
if [ -n "$HBMEX_PREFIX" ]; then
    echo "hbmex environment is already active."
    return 0
fi

# TODO FIX THIS
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

export HBMEX_PREFIX="$SCRIPT_DIR"
export VIRTUAL_ENV="$HBMEX_PREFIX"

HBMEX_OLD_PATH="$PATH"
export PATH="$HBMEX_PREFIX/bin:$PATH"

HBMEX_OLD_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$HBMEX_PREFIX/lib:$LD_LIBRARY_PATH"

if [ -n "$PYTHONHOME" ]; then
    HBMEX_OLD_PYTHONHOME="$PYTHONHOME"
    unset PYTHONHOME
fi

if [ -z "$HBMEX_DISABLE_PROMPT" ]; then
    HBMEX_OLD_PS1="$PS1"
    PS1='(hbmex) '"$PS1"
    export PS1
fi

hash -r 2> /dev/null
