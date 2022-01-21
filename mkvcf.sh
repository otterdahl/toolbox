#!/bin/bash

# Create contact (vcf) files with only text information 
# Usage: mkvcf.sh [title] [filename.vcf] < [file.txt]

set -e
title=$1
file=$2

while read line
do
	if [ -z "$text" ]; then
		text=$line
	else
		text=$text\\n$line
	fi
done < /dev/stdin

cat >$file<<END
begin:vcard
version:3.0
title:$text
org:$title
end:vcard
END

tmpfile=$(mktemp)
iconv -f utf8 -t iso-8859-1 $file > ${tmpfile}
cp $tmpfile $file
rm ${tmpfile}
