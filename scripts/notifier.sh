#!/usr/bin/env bash

# --- Configuration ---
# Replace these or set them as environment variables
TOKEN="$TELEGRAM_TOKEN"
CHAT_ID="$TELEGRAM_CHAT_ID"
RUNNER_ID="${1:-"unknown"}"
STATUS="${2:-"started"}"

# --- Message Mapping ---
case "$STATUS" in
    "started")
        TEXT="⏱ *Kernel build started:* \`${RUNNER_ID}\`"
        ;;
    "success")
        TEXT="✅ *Kernel build successfully*"
        ;;
    "canceled")
        TEXT="🛑 *Kernel build canceled*"
        ;;
    "failed")
        TEXT="❌ *Kernel build failed*"
        ;;
    *)
        echo "Error: Unknown status '$STATUS'"
        exit 1
        ;;
esac

# --- Send to Telegram ---
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${TEXT}" \
    -d "parse_mode=Markdown" > /dev/null

if [ $? -eq 0 ]; then
    echo "Notification sent: $STATUS"
else
    echo "Failed to send notification"
    exit 1
fi
