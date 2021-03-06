#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Usage: $0 URL_LIST DOWNLOAD_DIR" >&2
	exit 1
fi

URL_LIST=$1
DOWNLOAD_DIR=$2

mkdir $DOWNLOAD_DIR

echo "--------------------------------------------------"
echo "Stahujem parlamentne tlace..."
echo ""
cat $URL_LIST | grep http | parallel --progress --eta -j 30 ./stiahni_parlamentnu_tlac.pl {} $DOWNLOAD_DIR
