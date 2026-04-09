# disk-usage

This project provides tools for sending alerts if the disk is almost full. Supports **Postmark** (email), **Seven API** (SMS), or both.

## Setup

Set the environment variables for the provider(s) you want to use in `/etc/.env`. If both are configured, both will fire.

### Postmark (email)

```bash
POSTMARK_TOKEN="your_token_here"
```

### Seven API (SMS)

```bash
SEVEN_API_KEY="your_seven_api_key_here"
```

Also set `SEVEN_TO_NUMBER` and optionally `SEVEN_FROM_NUMBER` in `disk_usage.sh`.

### cloud_init.sh example

```bash
#! /bin/bash

touch /etc/.env
echo "POSTMARK_TOKEN=your_token_here" >> /etc/.env
echo "SEVEN_API_KEY=your_seven_api_key_here" >> /etc/.env

curl https://raw.githubusercontent.com/ok-worx/disk-usage/refs/heads/main/disk_usage.sh > disk_usage.sh 
chmod +x disk_usage.sh

path_to_sh=($(pwd)/disk_usage.sh)
crontab << EOF
0 * * * * $path_to_sh
EOF
```
