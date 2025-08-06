# disk-usage

This project provides tools for sending Postmark alerts if the disk is almost full.

## Setup

Important! You must have the environment variable **`$POSTMARK_TOKEN`** set beforehand in your configuration for the setup to work correctly.

```bash
export POSTMARK_TOKEN="your_token_here"
```

Here is an example of what to put in your "*`cloud_init.sh`*"

```bash
#! /bin/bash

touch /etc/.env
echo "POSTMARK_TOKEN="your_token_here"" >> /etc/.env

curl https://raw.githubusercontent.com/ok-worx/disk-usage/refs/heads/main/disk_usage.sh > disk_usage.sh 
chmod +x disk_usage.sh

path_to_sh=($(pwd)/disk_usage.sh)
crontab << EOF
0 * * * * $path_to_sh
EOF
```
