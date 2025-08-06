# disk-usage

This project provides tools for sending Postmark alerts if the disk is almost full.

## Setup

Important! You must have the environment variable **`$POSTMARK_TOKEN`** set beforehand in your configuration for the setup to work correctly.

```bash
export POSTMARK_TOKEN="your_token_here"
```

The `init.sh` is an example of what to put in your "*cloud_init.sh*"
