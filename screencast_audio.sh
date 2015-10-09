#!/bin/bash
echo "Additional steps required to enable audio"
echo "-----------------------------------------"
echo "1, Start pavucontrol"
echo "2, Select audio sources and select to show all"
echo "3, Select source (monitor?) and click the green button"
ffcast -s reca -m 4 $(date +%F_%H-%M-%S).mkv
