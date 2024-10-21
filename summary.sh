#!/bin/bash
find . -name "$(date +"%Y%m%d")*.log" -type f | xargs grep -H "time=" | awk -F 'time=' '{if ($2 > 1) print $0}'