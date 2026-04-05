#!/bin/bash

# Mail skill - wrapper for GNU mailutils
# Provides convenient interface for sending and receiving emails
# Supports multiple profiles via JSON configuration

# set -e  # Disabled to avoid issues with pipeline return codes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_CONFIG="$SCRIPT_DIR/mail.config.json"
LEGACY_CONFIG="$SCRIPT_DIR/.mail.conf"
VERBOSE=false
SELECTED_PROFILE=""

# Default configuration
SMTP_SERVER=""
SMTP_USER=""
SMTP_PASSWORD=""
IMAP_SERVER=""
IMAP_USER=""
IMAP_PASSWORD=""
MAIL_DIR="${MAIL_DIR:-$HOME/Mail}"
FROM_ADDRESS=""

# Check if jq is available
has_jq() {
    command -v jq &> /dev/null
}

# Load configuration from JSON file for a specific profile
load_json_profile() {
    local profile="$1"
    
    if [[ ! -f "$JSON_CONFIG" ]]; then
        return 1
    fi
    
    if ! has_jq; then
        echo "WARNING: jq is required for JSON config. Install with: apt install jq" >&2
        return 1
    fi
    
    # Check if profile exists
    if ! jq -e ".profiles.\"$profile\"" "$JSON_CONFIG" &> /dev/null; then
        return 1
    fi
    
    # Load profile settings
    SMTP_SERVER=$(jq -r '.profiles["'$profile'"].smtp.server // empty' "$JSON_CONFIG")
    SMTP_USER=$(jq -r '.profiles["'$profile'"].smtp.user // empty' "$JSON_CONFIG")
    SMTP_PASSWORD=$(jq -r '.profiles["'$profile'"].smtp.password // empty' "$JSON_CONFIG")
    IMAP_SERVER=$(jq -r '.profiles["'$profile'"].imap.server // empty' "$JSON_CONFIG")
    IMAP_USER=$(jq -r '.profiles["'$profile'"].imap.user // empty' "$JSON_CONFIG")
    IMAP_PASSWORD=$(jq -r '.profiles["'$profile'"].imap.password // empty' "$JSON_CONFIG")
    FROM_ADDRESS=$(jq -r '.profiles["'$profile'"].from // empty' "$JSON_CONFIG")
    
    return 0
}

# Get default profile from JSON config
get_default_profile() {
    if [[ -f "$JSON_CONFIG" ]] && has_jq; then
        jq -r '.defaultProfile // empty' "$JSON_CONFIG"
    fi
}

# List all available profiles
list_profiles() {
    if [[ ! -f "$JSON_CONFIG" ]]; then
        echo "No JSON config file found at: $JSON_CONFIG"
        return 0
    fi
    
    if ! has_jq; then
        echo "ERROR: jq is required to list profiles. Install with: apt install jq"
        return 0
    fi
    
    local default=$(get_default_profile)
    
    echo "Available mail profiles:"
    echo ""
    
    # Get profile names and descriptions
    local profiles
    profiles=$(jq -r '.profiles | to_entries[] | "\(.key)|\(.value.description // "No description")"' "$JSON_CONFIG")
    
    while IFS='|' read -r name desc; do
        if [[ "$name" == "$default" ]]; then
            echo "  * $name (default) - $desc"
        else
            echo "    $name - $desc"
        fi
    done <<< "$profiles"
    
    return 0
}

# Show details of a specific profile (without showing password)
show_profile() {
    local profile="$1"
    
    if [[ ! -f "$JSON_CONFIG" ]]; then
        echo "No JSON config file found at: $JSON_CONFIG"
        return 0
    fi
    
    if ! has_jq; then
        echo "ERROR: jq is required. Install with: apt install jq"
        return 0
    fi
    
    if ! jq -e ".profiles.\"$profile\"" "$JSON_CONFIG" &> /dev/null; then
        echo "Profile not found: $profile"
        return 0
    fi
    
    echo "Profile: $profile"
    echo "Description: $(jq -r '.profiles["'$profile'"].description // "None"' "$JSON_CONFIG")"
    echo ""
    echo "SMTP:"
    echo "  Server: $(jq -r '.profiles["'$profile'"].smtp.server // "Not set"' "$JSON_CONFIG")"
    echo "  User: $(jq -r '.profiles["'$profile'"].smtp.user // "Not set"' "$JSON_CONFIG")"
    echo "  Password: $([ -n "$(jq -r '.profiles["'$profile'"].smtp.password // empty' "$JSON_CONFIG")" ] && echo "********" || echo "Not set")"
    echo ""
    echo "IMAP:"
    echo "  Server: $(jq -r '.profiles["'$profile'"].imap.server // "Not set"' "$JSON_CONFIG")"
    echo "  User: $(jq -r '.profiles["'$profile'"].imap.user // "Not set"' "$JSON_CONFIG")"
    echo "  Password: $([ -n "$(jq -r '.profiles["'$profile'"].imap.password // empty' "$JSON_CONFIG")" ] && echo "********" || echo "Not set")"
    echo ""
    echo "From: $(jq -r '.profiles["'$profile'"].from // "Not set"' "$JSON_CONFIG")"
}

# Load configuration with priority: env vars > JSON profile > legacy config
load_config() {
    # If a profile is selected, load it first
    if [[ -n "$SELECTED_PROFILE" ]]; then
        load_json_profile "$SELECTED_PROFILE" || {
            echo "WARNING: Could not load profile '$SELECTED_PROFILE'" >&2
        }
    else
        # Try to load default profile from JSON
        local default_profile=$(get_default_profile)
        if [[ -n "$default_profile" ]]; then
            load_json_profile "$default_profile"
            log "Using default profile: $default_profile"
        fi
    fi
    
    # Load legacy config file if exists (lower priority than JSON)
    if [[ -f "$LEGACY_CONFIG" ]]; then
        source "$LEGACY_CONFIG"
    fi
    
    # Environment variables have highest priority
    SMTP_SERVER="${MAIL_SMTP_SERVER:-${SMTP_SERVER:-}}"
    SMTP_USER="${MAIL_SMTP_USER:-${SMTP_USER:-}}"
    SMTP_PASSWORD="${MAIL_SMTP_PASSWORD:-${SMTP_PASSWORD:-}}"
    IMAP_SERVER="${MAIL_IMAP_SERVER:-${IMAP_SERVER:-}}"
    IMAP_USER="${MAIL_IMAP_USER:-${IMAP_USER:-}}"
    IMAP_PASSWORD="${MAIL_IMAP_PASSWORD:-${IMAP_PASSWORD:-}}"
    FROM_ADDRESS="${MAIL_FROM:-${FROM_ADDRESS:-$SMTP_USER}}"
}

log() {
    [[ "$VERBOSE" == "true" ]] && echo "[MAIL] $1" >&2
    return 0
}

error() {
    echo "ERROR: $1" >&2
    exit 1
}

# Build temporary mailrc file with SMTP settings
build_mailrc() {
    local mailrc_file=$(mktemp)
    
    # Basic settings
    echo "set prompt=\"& \"" >> "$mailrc_file"
    echo "set indentprefix=\"> \"" >> "$mailrc_file"
    echo "set screen=20" >> "$mailrc_file"
    
    # SMTP settings if configured
    if [[ -n "$SMTP_SERVER" && -n "$SMTP_USER" ]]; then
        # Parse SMTP server into host and port
        local host="${SMTP_SERVER%:*}"
        local port="${SMTP_SERVER##*:}"
        if [[ "$port" == "$host" ]]; then
            port="587"
        fi
        
        # Remove spaces from password (Gmail app passwords have spaces but should be used without)
        local clean_password="${SMTP_PASSWORD// /}"
        
        # URL-encode username and password (for special chars like @)
        local encoded_user=""
        local encoded_pass=""
        encoded_user=$(printf '%s' "$SMTP_USER" | jq -sRr @uri 2>/dev/null || printf '%s' "$SMTP_USER" | sed 's/@/%40/g; s/:/%3A/g; s/\//%2F/g')
        if [[ -n "$clean_password" ]]; then
            encoded_pass=$(printf '%s' "$clean_password" | jq -sRr @uri 2>/dev/null || printf '%s' "$clean_password" | sed 's/@/%40/g; s/:/%3A/g; s/\//%2F/g')
        fi
        
        # Build SMTP URL for sendmail setting
        echo "set sendmail=\"smtp://${encoded_user}:${encoded_pass}@${host}:${port}\"" >> "$mailrc_file"
    else
        # Use default sendmail
        echo "set sendmail=\"/usr/sbin/sendmail\"" >> "$mailrc_file"
    fi
    
    # Set from address
    if [[ -n "$FROM_ADDRESS" ]]; then
        echo "set from=\"$FROM_ADDRESS\"" >> "$mailrc_file"
    fi
    
    echo "$mailrc_file"
}

# Build mail command with SMTP settings
build_smtp_opts() {
    local opts=""
    if [[ -n "$FROM_ADDRESS" ]]; then
        opts="-r"
    fi
    echo "$opts"
}

# Build IMAP URL for reading mail (curl-based, faster)
build_imap_creds() {
    if [[ -z "$IMAP_SERVER" ]]; then
        return 1
    fi
    
    # Parse server into host and port
    local host="${IMAP_SERVER%:*}"
    local port="${IMAP_SERVER##*:}"
    
    # Default IMAPS port
    if [[ "$port" == "$host" ]]; then
        port="993"
    fi
    
    # Remove spaces from password (Gmail app passwords)
    local clean_pass="${IMAP_PASSWORD// /}"
    
    echo "${IMAP_USER}:${clean_pass}@${host}:${port}"
}

# Send email
cmd_send() {
    local to=""
    local subject=""
    local body=""
    local attachments=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--to)
                to="$2"
                shift 2
                ;;
            -s|--subject)
                subject="$2"
                shift 2
                ;;
            -a|--attach)
                attachments+=("$2")
                shift 2
                ;;
            -f|--from)
                FROM_ADDRESS="$2"
                shift 2
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                body="$1"
                shift
                ;;
        esac
    done
    
    [[ -z "$to" ]] && error "Recipient (-t) is required"
    [[ -z "$subject" ]] && error "Subject (-s) is required"
    
    # Read body from stdin if not provided
    if [[ -z "$body" ]] && [[ ! -t 0 ]]; then
        body=$(cat)
    fi
    
    log "Sending email to: $to"
    log "Subject: $subject"
    log "From: $FROM_ADDRESS"
    
    # Build attachment arguments
    local attach_args=""
    for file in "${attachments[@]}"; do
        if [[ -f "$file" ]]; then
            attach_args="$attach_args -A $file"
        else
            error "Attachment not found: $file"
        fi
    done
    
    # Build temporary mailrc file with SMTP settings
    local mailrc_file=$(build_mailrc)
    
    # Build additional options
    local smtp_opts
    smtp_opts=$(build_smtp_opts)
    
    # Write body to temp file for reliable stdin handling
    local body_file=$(mktemp)
    printf '%s' "$body" > "$body_file"
    
    # Execute mail command with custom mailrc
    local result=0
    if [[ -n "$attach_args" ]]; then
        if [[ -n "$FROM_ADDRESS" ]]; then
            MAILRC="$mailrc_file" mail -r "$FROM_ADDRESS" -s "$subject" $attach_args "$to" < "$body_file" || result=$?
        else
            MAILRC="$mailrc_file" mail -s "$subject" $attach_args "$to" < "$body_file" || result=$?
        fi
    else
        if [[ -n "$FROM_ADDRESS" ]]; then
            MAILRC="$mailrc_file" mail -r "$FROM_ADDRESS" -s "$subject" "$to" < "$body_file" || result=$?
        else
            MAILRC="$mailrc_file" mail -s "$subject" "$to" < "$body_file" || result=$?
        fi
    fi
    
    # Clean up temp files
    rm -f "$mailrc_file" "$body_file"
    
    if [[ $result -eq 0 ]]; then
        log "Email sent successfully"
    else
        error "Failed to send email"
    fi
}

# List messages in inbox
cmd_list() {
    local count=5
    local all=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--count)
                count="$2"
                shift 2
                ;;
            -a|--all)
                all=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    local imap_creds
    imap_creds=$(build_imap_creds)
    
    if [[ -n "$imap_creds" ]]; then
        log "Listing messages from IMAP: $IMAP_SERVER (using curl)"
        local user="${imap_creds%%:*}"
        local pass_host="${imap_creds#*:}"
        local pass="${pass_host%%@*}"
        local host_port="${pass_host#*@}"
        
        # Get total message count first
        local search_result
        search_result=$(curl -s -u "$user:$pass" "imaps://$host_port/INBOX" -X 'SEARCH ALL' 2>/dev/null)
        local total=$(echo "$search_result" | grep -oP '\* SEARCH.*' | grep -oP '\d+' | wc -l)
        
        if [[ "$all" == "true" ]]; then
            count=$total
        fi
        
        # Calculate range (most recent messages)
        local start=$((total - count + 1))
        [[ $start -lt 1 ]] && start=1
        
        # Fetch headers for last N messages in parallel using background jobs
        local temp_dir=$(mktemp -d)
        local idx=$total
        local printed=0
        
        while [[ $idx -ge $start && $printed -lt $count ]]; do
            local out_file="$temp_dir/msg_$idx"
            # Start background curl request
            curl -s -u "$user:$pass" \
                "imaps://$host_port/INBOX/;MAILINDEX=$idx;SECTION=HEADER.FIELDS%20(SUBJECT%20FROM%20DATE)" \
                -o "$out_file" 2>/dev/null &
            ((idx--))
            ((printed++))
        done
        
        # Wait for all background jobs to complete
        wait
        
        # Print results in order (newest first)
        local idx=$total
        local printed=0
        while [[ $idx -ge $start && $printed -lt $count ]]; do
            local out_file="$temp_dir/msg_$idx"
            if [[ -f "$out_file" ]]; then
                local headers=$(cat "$out_file")
                local from=$(echo "$headers" | grep -i '^From:' | head -1 | sed 's/^From: //')
                local subject=$(echo "$headers" | grep -i '^Subject:' | head -1 | sed 's/^Subject: //')
                printf "%-4s %-30s %s\n" "$idx" "$from" "$subject"
            fi
            ((idx--))
            ((printed++))
        done
        
        # Cleanup
        rm -rf "$temp_dir"
    else
        # Use local mailbox
        log "Listing messages from local mailbox"
        if [[ -d "$MAIL_DIR" ]]; then
            mail -f "$MAIL_DIR" -H 2>/dev/null | head -n "$count"
        else
            mail -H 2>/dev/null | head -n "$count"
        fi
    fi
}

# Read a specific message
cmd_read() {
    local msg_num="${1:-last}"
    
    local imap_creds
    imap_creds=$(build_imap_creds)
    
    if [[ -n "$imap_creds" ]]; then
        local user="${imap_creds%%:*}"
        local pass_host="${imap_creds#*:}"
        local pass="${pass_host%%@*}"
        local host_port="${pass_host#*@}"
        
        log "Reading message $msg_num from IMAP (using curl)"
        
        if [[ "$msg_num" == "last" ]]; then
            # Get total message count first
            local search_result
            search_result=$(curl -s -u "$user:$pass" "imaps://$host_port/INBOX" -X 'SEARCH ALL' 2>/dev/null)
            msg_num=$(echo "$search_result" | grep -oP '\* SEARCH.*' | grep -oP '\d+' | tail -1)
        fi
        
        # Use curl for faster IMAP message fetch
        curl -s -u "$user:$pass" "imaps://$host_port/INBOX/;MAILINDEX=$msg_num" 2>/dev/null
    else
        log "Reading message $msg_num from local mailbox"
        if [[ "$msg_num" == "last" ]]; then
            readmsg -h 2>/dev/null | tail -100
        else
            readmsg -h "$msg_num" 2>/dev/null
        fi
    fi
}

# Delete messages
cmd_delete() {
    local msg_nums=("$@")
    
    [[ ${#msg_nums[@]} -eq 0 ]] && error "Message number(s) required"
    
    local imap_creds
    imap_creds=$(build_imap_creds)
    
    if [[ -n "$imap_creds" ]]; then
        log "Deleting messages from IMAP: ${msg_nums[*]}"
        local user="${imap_creds%%:*}"
        local pass_host="${imap_creds#*:}"
        local pass="${pass_host%%@*}"
        local host_port="${pass_host#*@}"
        local encoded_user=$(printf '%s' "$user" | jq -sRr @uri)
        local imap_url="imaps://${encoded_user}:${pass}@${host_port}/INBOX"
        
        for num in "${msg_nums[@]}"; do
            echo "d $num" | mail -f "$imap_url" 2>/dev/null
        done
        echo "q" | mail -f "$imap_url" 2>/dev/null
    else
        log "Deleting messages from local mailbox: ${msg_nums[*]}"
        for num in "${msg_nums[@]}"; do
            echo "d $num" | mail 2>/dev/null
        done
        echo "q" | mail 2>/dev/null
    fi
    
    log "Messages deleted"
}

# Count messages
cmd_count() {
    local imap_creds
    imap_creds=$(build_imap_creds)
    
    if [[ -n "$imap_creds" ]]; then
        log "Counting messages in IMAP inbox"
        local user="${imap_creds%%:*}"
        local pass_host="${imap_creds#*:}"
        local pass="${pass_host%%@*}"
        local host_port="${pass_host#*@}"
        local encoded_user=$(printf '%s' "$user" | jq -sRr @uri)
        local imap_url="imaps://${encoded_user}:${pass}@${host_port}/INBOX"
        mail -f "$imap_url" -H 2>/dev/null | wc -l
    else
        log "Counting messages in local mailbox"
        mail -H 2>/dev/null | wc -l
    fi
}

# Open interactive mail client
cmd_interactive() {
    local imap_creds
    imap_creds=$(build_imap_creds)
    
    if [[ -n "$imap_creds" ]]; then
        local user="${imap_creds%%:*}"
        local pass_host="${imap_creds#*:}"
        local pass="${pass_host%%@*}"
        local host_port="${pass_host#*@}"
        local encoded_user=$(printf '%s' "$user" | jq -sRr @uri)
        local imap_url="imaps://${encoded_user}:${pass}@${host_port}/INBOX"
        
        log "Opening interactive IMAP session: $IMAP_SERVER"
        mail -f "$imap_url"
    else
        log "Opening interactive local mailbox"
        mail
    fi
}

# Test SMTP configuration
cmd_test_smtp() {
    log "Testing SMTP configuration..."
    echo "SMTP Server: $SMTP_SERVER"
    echo "SMTP User: $SMTP_USER"
    echo "From Address: $FROM_ADDRESS"
    
    if [[ -z "$SMTP_SERVER" ]]; then
        echo "WARNING: No SMTP server configured"
    fi
    if [[ -z "$SMTP_USER" ]]; then
        echo "WARNING: No SMTP user configured"
    fi
    if [[ -z "$SMTP_PASSWORD" ]]; then
        echo "WARNING: No SMTP password configured"
    fi
    
    # Try to send test email to self
    if [[ -n "$SMTP_SERVER" && -n "$SMTP_USER" ]]; then
        echo "Sending test email to $SMTP_USER..."
        cmd_send -t "$SMTP_USER" -s "Mail Skill Test" "This is a test email from the mail skill."
    fi
}

# Test IMAP configuration
cmd_test_imap() {
    log "Testing IMAP configuration..."
    echo "IMAP Server: $IMAP_SERVER"
    echo "IMAP User: $IMAP_USER"
    
    if [[ -z "$IMAP_SERVER" ]]; then
        echo "WARNING: No IMAP server configured"
        return
    fi
    if [[ -z "$IMAP_USER" ]]; then
        echo "WARNING: No IMAP user configured"
    fi
    if [[ -z "$IMAP_PASSWORD" ]]; then
        echo "WARNING: No IMAP password configured"
    fi
    
    # Try to list inbox
    echo "Attempting to list inbox..."
    cmd_list -n 1
}

# Show help
show_help() {
    cat << 'EOF'
Mail Skill - Send and receive emails using GNU mailutils

Usage: mail.sh [options] <command> [command-options]

Global Options:
  -p, --profile <name>    Use a specific profile from mail.config.json
  -v, --verbose           Enable verbose output
  -h, --help              Show this help

Commands:
  send          Send an email
  list          List messages in inbox
  read          Read a specific message
  delete        Delete messages
  count         Count messages in inbox
  interactive   Open interactive mail client
  test-smtp     Test SMTP configuration
  test-imap     Test IMAP configuration
  list-profiles List all available profiles
  show-profile  Show details of a profile

Send Options:
  -t, --to <address>      Recipient email address (required)
  -s, --subject <subj>    Email subject (required)
  -a, --attach <file>     Attach a file
  -f, --from <address>    Override from address

List Options:
  -n, --count <num>       Number of messages to show (default: 5)
  -a, --all               Show all messages

Read Options:
  <num>                   Message number to read
  last                    Read the last message (default)

Examples:
  # Use default profile
  ./mail.sh send -t user@example.com -s "Hello" "Hi there!"

  # Use specific profile
  ./mail.sh -p work send -t boss@company.com -s "Report" "Here it is"

  # Pipe command output
  df -h | ./mail.sh send -t admin@example.com -s "Disk Report"

  # Send with attachment
  ./mail.sh send -t a@b.com -s "Files" -a report.pdf "See attached"

  # List and read messages
  ./mail.sh list -n 10
  ./mail.sh read 5

  # Profile management
  ./mail.sh list-profiles
  ./mail.sh show-profile work

Configuration:
  JSON Config (recommended): mail.config.json
  {
    "defaultProfile": "personal",
    "profiles": {
      "personal": {
        "description": "Personal Gmail",
        "smtp": {
          "server": "smtp.gmail.com:587",
          "user": "you@gmail.com",
          "password": "app-password"
        },
        "imap": {
          "server": "imap.gmail.com:993",
          "user": "you@gmail.com",
          "password": "app-password"
        },
        "from": "you@gmail.com"
      }
    }
  }

  Environment variables (override config):
    MAIL_SMTP_SERVER, MAIL_SMTP_USER, MAIL_SMTP_PASSWORD
    MAIL_IMAP_SERVER, MAIL_IMAP_USER, MAIL_IMAP_PASSWORD
    MAIL_FROM
EOF
}

# Main entry point
main() {
    # Check if mail command exists
    if ! command -v mail &> /dev/null; then
        error "GNU mailutils not found. Install with: apt install mailutils"
    fi
    
    # Parse global options first
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--profile)
                SELECTED_PROFILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                # Unknown option, might be command option - stop parsing global
                break
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Load configuration
    load_config
    
    # Parse command
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        send)
            cmd_send "$@"
            ;;
        list|ls)
            cmd_list "$@"
            ;;
        read|view|show)
            cmd_read "$@"
            ;;
        delete|del|rm)
            cmd_delete "$@"
            ;;
        count)
            cmd_count
            ;;
        interactive|i)
            cmd_interactive
            ;;
        test-smtp)
            cmd_test_smtp
            ;;
        test-imap)
            cmd_test_imap
            ;;
        list-profiles|profiles)
            list_profiles
            ;;
        show-profile)
            show_profile "${1:-}"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $command. Use --help for usage."
            ;;
    esac
}

main "$@"
