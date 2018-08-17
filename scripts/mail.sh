#!/bin/bash
scanmode=$1
echo "To do!" | mail -s "DIMS data processing in $scanmode scanmode has finished!" -c a.m.willemsen-8@umcutrecht.nl
