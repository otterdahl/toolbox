#!/bin/bash
# usage: pdf_rotate.sh [-r|--range <range>] [-a|--angle [-90,0,90,180] [-i|--input <filename>] [-o|--output <filename>]
#        range: e.g. "2-3". Commas are not supported
#        angle, e.g. "-90", "90", "180"
# Basically a wrapper around pdftk for common rotate operations
# TODO: doesn't deal with spaces in file names

set -e

USAGE="usage: pdf_rotate.sh [-r|--range <range, e.g. 1-3>] [-a|--angle [-90,0,90,180] [-i|--input <filename>] [-o|--output <filename>]"
VIEWAPP=`grep 'application/pdf' /etc/mailcap | awk -F\;  '{ print $2 }' | awk -F\  '{ print $1 }' | head -1`

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo $USAGE
    exit 1
fi

TEMP=`getopt -o r:a:i:o: --long range:,angle:,input:,output: -n 'pdf_rotate.sh' -- "$@"`
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
        -i|--input)
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
        -o|--output)
            case "$2" in
                "")
                    shift 2
                    ;;
                *)
                    OUTPUT="$2"
                    shift 2
                    ;;
            esac
            ;;
        --) shift ; break ;;
    esac
done

# Check if output file exists
if [ -a "$OUTPUT" ]; then
    echo File already exists
    exit 1
fi

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

pdftk $INPUT cat $PRE $RANGE$ANGLE $POST output $OUTPUT
$VIEWAPP "$OUTPUT"
