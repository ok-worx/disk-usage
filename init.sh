#!/bin/bash

curl https://raw.githubusercontent.com/ok-worx/disk-usage/refs/heads/main/disk_usage.sh > disk_usage.sh 

chmod +x disk_usage.sh
path_to_sh=($(pwd)/disk_usage.sh)

crontab << EOF
0 * * * * $path_to_sh
EOF

