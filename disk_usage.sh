#!/bin/bash

FILESYSTEM="/"
MIN_FREE_PERCENT=10
MIN_FREE_GB=10

FROM_EMAIL="infra-alerts@okworx.com"
TO_EMAIL="alert@okworx.com"
RECIPIENT_PHONE=""   # recipient phone number for SMS (e.g. "+491234567890")


################################################################################################################################################################
source /etc/.env

df_out=$(df -BG $FILESYSTEM)

usage=$(echo "$df_out" | awk 'NR==2 {print $5}')
available=$(echo "$df_out" | awk 'NR==2 {print $4}')
total=$(echo "$df_out" | awk 'NR==2 {print $2}')
server_name=$(hostname)

# --- Postmark (email) message builders ---

make_postmark_msg(){
    cat << EOF
'{
    "From": "$FROM_EMAIL",
    "To": "$TO_EMAIL",
    "Subject": "🚨DISK ALERT🚨 $server_name $usage FULL",
    "HtmlBody": "disk space low on server $server_name <br> only $usage ($available/$total) available <br> ($(date '+%Y-%m-%d %H:%M:%S'))",
    "MessageStream": "outbound"
}'
EOF
}

failed_df_postmark(){
        cat << EOF
'{
    "From": "$FROM_EMAIL",
    "To": "$TO_EMAIL",
    "Subject": "🚨ALERT SOMETHING WENT MAJORLY WRONG🚨 $server_name",
    "HtmlBody": "failed to execute df command (output is $(echo $df_out)) <br> on server $server_name <br> ($(date '+%Y-%m-%d %H:%M:%S'))",
    "MessageStream": "outbound"
}'
EOF
}

send_postmark(){
  bash << EOF
    curl "https://api.postmarkapp.com/email" -X POST -H "Accept: application/json" -H "Content-Type: application/json" -H "X-Postmark-Server-Token: $POSTMARK_TOKEN" -d $1
EOF
}

# --- Seven API (SMS) message builders ---

send_seven(){
  local text="$1"
  local json="{\"to\":\"$RECIPIENT_PHONE\",\"from\":\"$server_name\",\"text\":\"$text\"}"

  curl -s "https://gateway.seven.io/api/sms" \
    -X POST \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: $SEVEN_API_KEY" \
    -d "$json"
}

# --- Unified send ---

send_msg(){
  local postmark_payload="$1"
  local sms_text="$2"

  if [[ -n "$POSTMARK_TOKEN" ]]; then
    send_postmark "$postmark_payload"
  fi

  if [[ -n "$SEVEN_API_KEY" ]] && [[ -n "$RECIPIENT_PHONE" ]]; then
    send_seven "$sms_text"
  fi
}

# sanity check
if [[ "$usage" != *% ]] || [[ "$available" != *G ]] || [[ "$total" != *G ]]; then
    send_msg \
      "$(failed_df_postmark)" \
      "ALERT: df command failed on $server_name (output: $df_out) - $(date '+%Y-%m-%d %H:%M:%S')"
fi

min_percentage=$((100 - MIN_FREE_PERCENT))
usage_value=${usage%\%}
available_value=${available%\G}

if ((usage_value > min_percentage )) || (( MIN_FREE_GB > available_value )); then
    send_msg \
      "$(make_postmark_msg)" \
      "DISK ALERT: $server_name $usage full - only $available/$total available - $(date '+%Y-%m-%d %H:%M:%S')"
fi
