#!/bin/bash
set -e
USAGE="usage: `basename $0` [-t|--type <type>] <URL>]"

# macOS & homebrew compatibility
if [[ "$OSTYPE" == "darwin"* ]]; then
	GETOPT=/usr/local/opt/gnu-getopt/bin/getopt
else
	GETOPT=getopt
fi

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo $USAGE
    exit 1
fi

TEMP=`$GETOPT -o t: --long type: -n 'getl.sh' -- "$@"`
eval set -- "$TEMP"

while true; do
    case "$1" in
	-t|--type)
            case "$2" in
                "")
                    shift 2
                    ;;
                *)
                    TYPE="$2"
                    shift 2
                    ;;
            esac
            ;;
        --) shift ; break ;;
    esac
done

if [ -z "$1" ]; then
	echo "No URL given"
	exit 1
fi

if [ -z $TYPE ]; then
	wget -nH -nv -r -np $1
else
	wget -nH -nv -r -np -A.$TYPE $1
fi

