#!/bin/bash

declare -A _HBMEX_OLD_ENV_VARS

hbmex_set_var() {
    local var_name="$1"
    local new_value="$2"

    if [[ -v "$var_name" && -z "${_HBMEX_OLD_ENV_VARS[$var_name]}" ]]; then
        _HBMEX_OLD_ENV_VARS[$var_name]="${!var_name}"
    fi

    export "$var_name"="$new_value"
}

hbmex_reset_var() {
    local var_name="$1"

    if [[ -v "_HBMEX_OLD_ENV_VARS[$var_name]" ]]; then
        export "$var_name"="${_HBMEX_OLD_ENV_VARS[$var_name]}"
        unset "_HBMEX_OLD_ENV_VARS[$var_name]"
    else
        unset "$var_name"
    fi
}

hbmex_activate() {
    hbmex_set_var "HBMEX_PREFIX" "$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"

    hbmex_set_var "VIRTUAL_ENV" "$HBMEX_PREFIX"
    hbmex_set_var "PYTHONHOME" ""

    hbmex_set_var "SYSTEMC_HOME" "$HBMEX_PREFIX"
    hbmex_set_var "SYSTEMC_INCLUDE" "$HBMEX_PREFIX/include"
    hbmex_set_var "SYSTEMC_LIBDIR" "$HBMEX_PREFIX/lib"

    hbmex_set_var "VERILATOR_ROOT" "$HBMEX_PREFIX"

    hbmex_set_var "PATH" "$HBMEX_PREFIX/bin:$PATH"
    hbmex_set_var "LD_LIBRARY_PATH" "$HBMEX_PREFIX/lib:$LD_LIBRARY_PATH"

    hbmex_set_var "SBT_OPTS" "-Dsbt.ivy.home=$HBMEX_PREFIX/.ivy2 $SBT_OPTS"

    hbmex_set_var "PS1" "(hbmex) $PS1"

    hash -r 2>/dev/null
}

hbmex_deactivate() {
    hbmex_reset_var "HBMEX_PREFIX"

    hbmex_reset_var "VIRTUAL_ENV"
    hbmex_reset_var "PYTHONHOME"

    hbmex_reset_var "SYSTEMC_HOME"
    hbmex_reset_var "SYSTEMC_INCLUDE"
    hbmex_reset_var "SYSTEMC_LIBDIR"

    hbmex_reset_var "VERILATOR_ROOT"

    hbmex_reset_var "PATH"
    hbmex_reset_var "LD_LIBRARY_PATH"

    hbmex_reset_var "SBT_OPTS"

    hbmex_reset_var "PS1"

    unset hbmex_deactivate
    unset hbmex_set_var
    unset hbmex_reset_var

    hash -r 2>/dev/null
}

if [[ -n "${_HBMEX_OLD_ENV_VARS["PATH"]}" || -n "${_HBMEX_OLD_ENV_VARS["LD_LIBRARY_PATH"]}" ]]; then
    echo "hbmex environment is already active."
    return 0
fi

hbmex_activate
unset hbmex_activate
