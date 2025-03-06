#!/bin/bash

echo "Cleaning old files..."

find ./tb_output/ -iname '*.vcd' -exec rm '{}' \;
find ./tb_output/ -iname '*.err' -exec rm '{}' \;
find ./tb_output/ -iname '*.out' -exec rm '{}' \;

echo "Done."
echo ""

find ./build/ -iname '*.tb' | sort | while read TB_EXEC
do
    TB_PARENT="$(dirname "${TB_EXEC}")"
    TB_NAME="$(basename "${TB_EXEC}" .tb)"
    TB_WORKDIR="./tb_output/${TB_PARENT#./build/}"
    TB_EXEC_ABS="${PWD}/${TB_EXEC}"

    mkdir -p "${TB_WORKDIR}"

    pushd "${TB_WORKDIR}" > /dev/null

    echo "Test bench: '${TB_NAME}'"
    echo "    Work directory: '${TB_WORKDIR}'"
    echo "    Running executable: '${TB_EXEC_ABS}'"

    "${TB_EXEC_ABS}" > "${TB_NAME}.out" 2> "${TB_NAME}.err"

    echo ""

    popd > /dev/null
done
