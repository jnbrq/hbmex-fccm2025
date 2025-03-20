#!/bin/bash

python3 -m hdlscw \
    -r protocols.py \
    --input-hdlinfo "testInput.hdlinfo.json" \
    --output-hpp "test.hpp" \
    --output-cpp "test.cpp"

python3 -m hdlscw \
    -r protocols.py \
    --input-hdlinfo "testInput.hdlinfo.json" \
    --single-file \
    --output-hpp "test_single.hpp"
