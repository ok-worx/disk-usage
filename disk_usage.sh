#!/bin/bash

FILESYSTEM="/"

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

# --- Postmark (email) ---

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

# --- Send helpers ---

send_email(){
  local subject="$1"
  local body="$2"
  if [[ -n "$POSTMARK_TOKEN" ]]; then
    local payload="'{\"From\": \"$FROM_EMAIL\", \"To\": \"$TO_EMAIL\", \"Subject\": \"$subject\", \"HtmlBody\": \"$body\", \"MessageStream\": \"outbound\"}'"
    send_postmark "$payload"
  fi
}

send_sms(){
  local text="$1"
  if [[ -n "$SEVEN_API_KEY" ]] && [[ -n "$RECIPIENT_PHONE" ]]; then
    send_seven "$text"
  fi
}

# --- Sanity check ---

if [[ "$usage" != *% ]] || [[ "$available" != *G ]] || [[ "$total" != *G ]]; then
    send_email \
      "🚨ALERT SOMETHING WENT MAJORLY WRONG🚨 $server_name" \
      "failed to execute df command (output is $(echo $df_out)) <br> on server $server_name <br> ($(date '+%Y-%m-%d %H:%M:%S'))"
    send_sms "CRITICAL: df command failed on $server_name - $(date '+%Y-%m-%d %H:%M:%S')"
    exit 1
fi

usage_value=${usage%\%}
timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

# --- Staggered alerts: 80% email only, 90%+ email + SMS ---

if (( usage_value >= 98 )); then
    send_email \
      "🔴 CRITICAL DISK ALERT 🔴 $server_name ${usage_value}% FULL" \
      "CRITICAL: disk space on $server_name at ${usage_value}% ($available/$total free) <br> ($timestamp)"
    send_sms "CRITICAL: $server_name disk ${usage_value}% full - $available/$total free - $timestamp"

elif (( usage_value >= 95 )); then
    send_email \
      "🟠 DISK ALERT 🟠 $server_name ${usage_value}% FULL" \
      "URGENT: disk space on $server_name at ${usage_value}% ($available/$total free) <br> ($timestamp)"
    send_sms "URGENT: $server_name disk ${usage_value}% full - $available/$total free - $timestamp"

elif (( usage_value >= 90 )); then
    send_email \
      "🟡 DISK WARNING 🟡 $server_name ${usage_value}% FULL" \
      "WARNING: disk space on $server_name at ${usage_value}% ($available/$total free) <br> ($timestamp)"
    send_sms "WARNING: $server_name disk ${usage_value}% full - $available/$total free - $timestamp"

elif (( usage_value >= 80 )); then
    send_email \
      "📀 DISK NOTICE 📀 $server_name ${usage_value}% FULL" \
      "NOTICE: disk space on $server_name at ${usage_value}% ($available/$total free) <br> ($timestamp)"
fi
