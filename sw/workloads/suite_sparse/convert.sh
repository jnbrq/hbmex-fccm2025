#!/bin/bash

for inputFile in *.mtx
do
    outputFile=$(basename "$inputFile" .mtx).csr

    ../../build/mm2csr $inputFile $outputFile
done
