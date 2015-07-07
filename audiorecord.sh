#!/bin/bash

# Record audio from default mic for 9 hours
MINUTES=540
FILENAME="out-`date +'%F_%H:%M'`.ogg"
timeout "$MINUTES"m arecord -f cd -t raw | oggenc - -r -o $FILENAME

mv $FILENAME $HOME
