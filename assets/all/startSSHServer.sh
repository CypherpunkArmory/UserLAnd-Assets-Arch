#! /bin/bash

dropbear -E -p 2022 -R -F
read -n 1 -s -r -p "Press any key to continue"
