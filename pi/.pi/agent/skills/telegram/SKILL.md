---
name: telegram
description: Send messages, photos, videos, and documents via Telegram Bot API. Use when the user wants to send Telegram notifications, alerts, files, or any other content to themselves or other chats.
---

# Telegram Skill

Send messages and media through Telegram using a bot.

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
```

## Requirements

- `bash`
- `curl`
- `jq` (only for `-l` option to list chats)
