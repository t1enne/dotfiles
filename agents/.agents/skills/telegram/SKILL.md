---
name: telegram
description: Send messages, photos, videos, and documents via Telegram Bot API. Use when the user wants to send Telegram notifications, alerts, files, or any other content to themselves or other chats, or listen for incoming messages.
---

# Telegram Skill

Send messages and media through Telegram using a bot, or listen for incoming messages to use as prompts.

## Setup

1. Create a bot via [@BotFather](https://t.me/BotFather) and get your bot token
2. Get your chat ID by messaging [@userinfobot](https://t.me/userinfobot)  
3. Configure via environment variables or `~/.pi/agent/skills/telegram/.telegram.sh.conf`:

```bash
export TELEGRAM_TOKEN="your-bot-token"
export TELEGRAM_CHAT="your-chat-id"
```

## Usage

### Send Text Message
```bash
./telegram.sh "Hello, World."
```

### Send with Markdown
```bash
./telegram.sh -M "*Bold* and _italic_ text"
```

### Send from stdin (monospaced)
```bash
ls -l | ./telegram.sh -
```

### Send Photo
```bash
./telegram.sh -i image.png
```

### Send Document
```bash
./telegram.sh -f document.pdf "Here is the file."
```

### Send Video
```bash
./telegram.sh -V video.mp4
```

### Listen for Messages (Continuous)
```bash
./telegram.sh -L
```

### Listen with Message Handler Script
```bash
export MESSAGE_HANDLER=/path/to/handler.sh
./telegram.sh -L
```

### Restrict to Specific Chats
```bash
export ALLOWED_CHAT_IDS="123456789 987654321"
./telegram.sh -L
```

### Send to Multiple Chats
```bash
./telegram.sh -c 1234 -c 5678 "Hello, everyone!"
```

### Use Different Credentials
```bash
./telegram.sh -t <token> -c <chat_id> "One-time message"
```

## Configuration File

Create `.telegram.sh.conf` in the skill directory for permanent settings:

```bash
TELEGRAM_TOKEN="your-token"
TELEGRAM_CHAT="default-chat-id"
HTTPS_PROXY="socks5://127.0.0.1:3128"

# For listening mode - restrict allowed chats (space-separated)
ALLOWED_CHAT_IDS="123456789 987654321"

# For listening mode - custom poll timeout in seconds (default: 30)
LISTEN_TIMEOUT=60

# For listening mode - handler script executed for each message
MESSAGE_HANDLER="/path/to/handler.sh"
```

## Listening Mode

The `-L` option enables continuous listening for incoming messages using long polling. This is useful for:

- Using Telegram as a remote prompt interface
- Building bot workflows
- Receiving notifications and reacting to them

When a message is received, it prints formatted output with:
- Timestamp
- Sender info (name, username, ID)
- Chat ID
- Message text

### Handler Script

If `MESSAGE_HANDLER` environment variable is set to an executable script, it will be called for each message with these environment variables:

| Variable | Description |
|----------|-------------|
| `TG_MESSAGE_ID` | Telegram message ID |
| `TG_FROM_ID` | Sender's user ID |
| `TG_CHAT_ID` | Chat ID where message was sent |
| `TG_USERNAME` | Sender's username (if any) |
| `TG_FIRST_NAME` | Sender's first name |
| `TG_TEXT` | Message text content |
| `TG_DATE` | Unix timestamp of message |

The message text is also passed as the first argument (`$1`).

### Example Handler Script

```bash
#!/bin/bash
# handler.sh - Example message handler

echo "Received: $TG_TEXT" >> /tmp/telegram_messages.log

# Reply back
/home/user/.pi/agent/skills/telegram/telegram.sh -c "$TG_CHAT_ID" "Got your message: $TG_TEXT"
```

## Requirements

- `bash`
- `curl`
- `jq` (required for `-l`, `-L`, `-m`, and `-R` options)
