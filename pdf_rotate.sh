#!/bin/bash
# usage: pdf_rotate.sh [-r|--range <range>] [-a|--angle [-90,0,90,180] [-f|--file <filename>]
#        range: e.g. "2-3". Commas are not supported
#        angle, e.g. "-90", "90", "180"
# Basically a wrapper around pdftk for common rotate operations
# TODO: doesn't deal with spaces in file names
# TODO: Check input better. e.g. 1,2 is not supported, -r is required

set -e

USAGE="usage: pdf_rotate.sh [-r|--range <range, e.g. 1-3>] [-a|--angle [-90,0,90,180] [-f|--file <filename>]"
VIEWAPP=`grep 'application/pdf' /etc/mailcap | awk -F\;  '{ print $2 }' | awk -F\  '{ print $1 }' | head -1`

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo $USAGE
    exit 1
fi

TEMP=`getopt -o r:a:f: --long range:,angle:,file: -n 'pdf_rotate.sh' -- "$@"`
eval set -- "$TEMP"

while true; do
    case "$1" in
        -r|--range)
            case "$2" in
                "")
                    shift 2
                    ;;
                *)
                    RANGE="$2"
                    shift 2
                    ;;
            esac
            ;;
        -a|--angle)
            case "$2" in
                "")
                    shift 2
                    ;;
                "-90")
                    ANGLE="left"
                    shift 2
                    ;;
                "90")
                    ANGLE="right"
                    shift 2
                    ;;
                "180")
                    ANGLE="down"
                    shift 2
                    ;;
            esac
            ;;
        -f|--file)
            case "$2" in
                "")
                    shift 2
                    ;;
                *)
                    INPUT="$2"
                    shift 2
                    ;;
            esac
            ;;
        --) shift ; break ;;
    esac
done

NUMPAGES=`pdftk $INPUT dump_data | grep NumberOfPages | awk '{print $2}'`
START=`echo $RANGE | awk -F"-" '{print $1} '`
END=`echo $RANGE | awk -F"-" '{print $2} '`

# if only a single page is defined in the range, set end same as start
if [ -z $END ]; then
    END=$START
fi

# Define ranges for the other pages which are not rotated
if [ "$START" -gt 1 ]; then
    PRE=1-$(($START - 1))
fi

if [ "$NUMPAGES" -gt "$END" ]; then
    POST=$(($END + 1))-$NUMPAGES
fi

OUTPUT=temp.pdf
pdftk $INPUT cat $PRE $RANGE$ANGLE $POST output $OUTPUT
mv -f $OUTPUT $INPUT
$VIEWAPP "$INPUT"
