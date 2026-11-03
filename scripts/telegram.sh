#!/usr/bin/env bash
upload_tg() {
    local file="$1"
    local token="$2"
    local chat_id="$3"

    local md5=$(md5sum "${file}" | cut -d' ' -f1)
    local msg_bar="md5: <code>${md5}</code>"

    msg "Uploading to Telegram..."
    curl -s -F document=@"${file}" "https://api.telegram.org/bot${token}/sendDocument" \
        -F chat_id="${chat_id}" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=HTML" \
        -F caption="${msg_bar}"
    
    msg "Upload completed!"
}
