# DSC Event Logs

# Where are the logs?
Get-WinEvent -ListLog *dsc*, *desiredstate* | Foreach logname

Get-WinEvent -ListLog *dsc*, *desiredstate* -Force | Foreach logname

Get-WinEvent -ListLog 'Microsoft-Windows-DSC/Debug' | select *

Get-WinEvent -cn ms1 -ListLog 'Microsoft-Windows-DSC/Debug' | select *

# How to examine and query the logs?
Get-Command -Noun winevent | ft -AutoSize
Get-Command -Noun eventlog | ft -AutoSize

# Enabling the Logs
# Firewall
Set-NetFirewallRule -CimSession ms1 -DisplayGroup 'Remote Event Log Management' -Enabled True -PassThru

# Event Viewer
Show-EventLog -ComputerName ms1

# Windows Events CLI Utility
wevtutil.exe /?
wevtutil.exe set-log /?
wevtutil.exe set-log 'Microsoft-Windows-Dsc/Analytic' /quiet:false /enabled:true /remote:ms1
wevtutil.exe sl 'Microsoft-Windows-Dsc/Debug' /q:True /e:true /r:ms1
wevtutil.exe get-log 'Microsoft-Windows-Dsc/Debug' /r:ms1

# More ways to look and manage the DSC Event logs in the next section
# xDscDiagnostics
