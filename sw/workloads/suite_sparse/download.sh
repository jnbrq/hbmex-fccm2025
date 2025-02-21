#!/bin/bash

urls=(
    "https://suitesparse-collection-website.herokuapp.com/MM/LAW/amazon-2008.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/SNAP/cit-Patents.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/Mittelmann/cont11_l.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/LAW/dblp-2010.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/LAW/eu-2005.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/Gleich/flickr.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/LAW/in-2004.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/LAW/ljournal-2008.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/MAWI/mawi_201512012345.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/Mittelmann/pds-80.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/Mittelmann/rail4284.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/DIMACS10/road_usa.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/Williams/webbase-1M.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/Gleich/wikipedia-20061104.tar.gz"
    "https://suitesparse-collection-website.herokuapp.com/MM/SNAP/com-Youtube.tar.gz"
)

temp_dir=$(mktemp -d)
this_dir="$PWD"

pushd "$temp_dir"

for url in "${urls[@]}"; do
    filename=$(basename "$url")
    
    echo "Downloading $filename..."
    wget "$url"
    
    echo "Extracting $filename..."
    tar -xzf "$filename"

    archive_name="${filename%.tar.gz}"
    
    # Find and copy the .mtx file to the current directory
    mtx_file=$(find "./$archive_name/" -name "$archive_name.mtx" -type f)
    if [ -n "$mtx_file" ]; then
        echo "Copying $archive_name.mtx to the current directory..."
        cp "$mtx_file" "$this_dir/"
    else
        echo "Warning: $archive_name.mtx not found in the archive."
    fi
    
    # Clean up the downloaded file
    echo "Removing $filename..."
    rm "$filename"
done

popd

# Cleanup temporary directory
echo "Cleaning up temporary directory..."
rm -rf "$temp_dir"

echo "All tasks completed!"
