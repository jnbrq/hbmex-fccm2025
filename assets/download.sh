#!/bin/bash

urls=(
    "https://drive.switch.ch/index.php/s/oNYQH2HHqzxnGwI/download?path=%2Fassets&files=fpga.tar.gz.aa"
    "https://drive.switch.ch/index.php/s/oNYQH2HHqzxnGwI/download?path=%2Fassets&files=fpga.tar.gz.ab"
    "https://drive.switch.ch/index.php/s/oNYQH2HHqzxnGwI/download?path=%2Fassets&files=fpga.tar.gz.ac"
    "https://drive.switch.ch/index.php/s/oNYQH2HHqzxnGwI/download?path=%2Fassets&files=fpga.tar.gz.ad"
    "https://drive.switch.ch/index.php/s/oNYQH2HHqzxnGwI/download?path=%2Fassets&files=fpga.tar.gz.ae"
    "https://drive.switch.ch/index.php/s/oNYQH2HHqzxnGwI/download?path=%2Fassets&files=workloads.tar.gz.aa"
    "https://drive.switch.ch/index.php/s/oNYQH2HHqzxnGwI/download?path=%2Fassets&files=workloads.tar.gz.ab"
)


for url in "${urls[@]}"; do
    [[ $url =~ files=(.*) ]]
    filename="${BASH_REMATCH[1]}"
    echo "downloading '$url' to '$filename'"
    wget --no-check-certificate "$url" -O "$filename"
done
