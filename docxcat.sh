#!/bin/bash
filename="$1"
unzip -p "$filename" | grep --text '<w:r' | sed 's/<w:p[^<\/]*>/ \n/g' | sed 's/<[^<]*>//g' | grep -v "^[[:space:]]*$" | sed G
