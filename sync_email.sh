#!/bin/bash
# Sync offlineimap
# 1, Only run one instance at a time
# 2, Disable sync if incorrect password
# F=0 disabled
# F=1 enabled
# F=2 enabled, running
F=~/config/email_sync_enabled
if [ `cat $F` -eq "0" ]; then
    exit 1;
fi
echo 2 > $F

offlineimap $@ 2>&1 | grep -q 'LOGIN authentication failed'
S=$?
if [ $S -ne 0 ]; then
    # Login successful
    echo 1 > $F
else
    # Login failed due to auth error, offlineimap disabled
    echo 0 > $F
fi 
