---
name: mail
description: Send and receive emails using GNU mailutils (mail/mailx command). Supports reading inbox, sending emails via SMTP, and managing mailboxes via IMAP. Multi-profile support for managing multiple email accounts.
allowed-tools: Bash(./mail.sh), Bash(mail), Bash(mailx), Bash(/usr/bin/mail), Bash(/usr/bin/mailx)
---

# Mail Skill

Send and receive emails using the GNU mailutils `mail` command locally or via IMAP remote servers. Supports multiple email profiles for easy account switching.

## Prerequisites

- GNU mailutils (`apt install mailutils` on Debian/Ubuntu)
- `jq` for JSON config parsing (`apt install jq`)
- SMTP/IMAP server credentials for remote access

## Quick Start

```bash
# List available profiles
./mail.sh list-profiles

# Send email using default profile
./mail.sh send -t recipient@example.com -s "Hello" "Message body"

# Send email using specific profile
./mail.sh -p work send -t boss@company.com -s "Report" "Here's the report"

# Read inbox
./mail.sh list
```

## Configuration

### JSON Config (Recommended)

Create `mail.config.json` in the skill directory with multiple profiles:

```json
{
  "defaultProfile": "personal",
  "profiles": {
    "personal": {
      "description": "Personal Gmail account",
      "smtp": {
        "server": "smtp.gmail.com:587",
        "user": "you@gmail.com",
        "password": "your-app-password"
      },
      "imap": {
        "server": "imap.gmail.com:993",
        "user": "you@gmail.com",
        "password": "your-app-password"
      },
      "from": "you@gmail.com"
    },
    "work": {
      "description": "Work Office 365 account",
      "smtp": {
        "server": "smtp.office365.com:587",
        "user": "you@company.com",
        "password": "your-password"
      },
      "imap": {
        "server": "outlook.office365.com:993",
        "user": "you@company.com",
        "password": "your-password"
      },
      "from": "you@company.com"
    }
  }
}
```

### Environment Variables

Override any config setting with environment variables:

```bash
export MAIL_SMTP_SERVER="smtp.gmail.com:587"
export MAIL_SMTP_USER="user@gmail.com"
export MAIL_SMTP_PASSWORD="app-password"
export MAIL_IMAP_SERVER="imap.gmail.com:993"
export MAIL_IMAP_USER="user@gmail.com"
export MAIL_IMAP_PASSWORD="app-password"
export MAIL_FROM="user@gmail.com"
```

### Configuration Priority

1. **Environment variables** (highest priority)
2. JSON profile (selected with `-p` or default)
3. Legacy `.mail.conf` file (lowest priority)

## Usage

### Profile Management

```bash
# List all available profiles
./mail.sh list-profiles

# Show details of a specific profile
./mail.sh show-profile work

# Use a specific profile for a command
./mail.sh -p work send -t client@example.com -s "Project update" "..."
```

### Send Email

```bash
# Basic send
./mail.sh send -t recipient@example.com -s "Subject" "Message body"

# Send with attachment
./mail.sh send -t recipient@example.com -s "Subject" -a file.pdf "See attached"

# Send to multiple recipients
./mail.sh send -t "a@example.com,b@example.com" -s "Subject" "Hello all"

# Pipe command output
df -h | ./mail.sh send -t admin@example.com -s "Disk Usage Report"

# Use specific profile
./mail.sh -p work send -t boss@company.com -s "Report" "Here it is"
```

### Read Inbox

```bash
# List unread messages (default 5)
./mail.sh list

# List last 10 messages
./mail.sh list -n 10

# List all messages
./mail.sh list -a

# Use specific profile
./mail.sh -p personal list
```

### Read Specific Message

```bash
# Read message by number
./mail.sh read 5

# Read last message
./mail.sh read last
```

### Delete Messages

```bash
# Delete message by number
./mail.sh delete 3

# Delete multiple messages
./mail.sh delete 1 3 5
```

### Interactive Mode

```bash
# Open interactive mail client
./mail.sh interactive

# With specific profile
./mail.sh -p work interactive
```

Useful commands in interactive mode:
- `h` - List headers
- `p [num]` - Print message
- `d [num]` - Delete message
- `r [num]` - Reply to message
- `s [num] file` - Save message to file
- `q` - Quit and save changes
- `x` - Quit without saving

## Common Patterns

### Automated Reports

```bash
# Daily backup notification
if tar czf backup.tar.gz /data; then
    ./mail.sh -p work send -t admin@company.com -s "Backup OK" "Backup completed"
else
    ./mail.sh -p work send -t admin@company.com -s "Backup FAILED" "Backup failed: $?"
fi
```

### Script Output via Email

```bash
# Send script output
./my-script.sh 2>&1 | ./mail.sh send -t logs@example.com -s "Script Output"
```

### Monitoring Alerts

```bash
# Disk space alert
df -h | grep -E '^/dev/[a-z]+' | awk '{if($5+0 > 80) print $0}' | \
    ./mail.sh send -t admin@example.com -s "Disk Space Warning"
```

## Provider-Specific Settings

### Gmail

```json
{
  "smtp": {
    "server": "smtp.gmail.com:587",
    "user": "you@gmail.com",
    "password": "app-password"
  },
  "imap": {
    "server": "imap.gmail.com:993",
    "user": "you@gmail.com",
    "password": "app-password"
  }
}
```

**Note:** Use an [App Password](https://support.google.com/accounts/answer/185833) instead of your regular password.

### Outlook / Office 365

```json
{
  "smtp": {
    "server": "smtp.office365.com:587",
    "user": "you@company.com",
    "password": "your-password"
  },
  "imap": {
    "server": "outlook.office365.com:993",
    "user": "you@company.com",
    "password": "your-password"
  }
}
```

### Fastmail

```json
{
  "smtp": {
    "server": "smtp.fastmail.com:587",
    "user": "you@fastmail.com",
    "password": "your-password"
  },
  "imap": {
    "server": "imap.fastmail.com:993",
    "user": "you@fastmail.com",
    "password": "your-password"
  }
}
```

## Troubleshooting

### Test Configuration

```bash
# Test SMTP settings
./mail.sh test-smtp

# Test IMAP settings
./mail.sh test-imap
```

### Debug Mode

Add `-v` flag for verbose output:
```bash
./mail.sh -v send -t user@example.com -s "Test" "Debug message"
```

### Common Issues

| Issue | Solution |
|-------|----------|
| "GNU mailutils not found" | `apt install mailutils` |
| "jq is required" | `apt install jq` |
| Authentication failed | Use app-specific password for Gmail |
| Connection timeout | Check firewall, verify server/port |
| TLS/SSL errors | Try different ports (587 vs 465) |

## Security Notes

- Set `mail.config.json` permissions to 600: `chmod 600 mail.config.json`
- Use app-specific passwords for Gmail/Outlook
- Consider using `pass` or other secret managers
- Passwords with special characters may need URL-encoding for IMAP URLs
