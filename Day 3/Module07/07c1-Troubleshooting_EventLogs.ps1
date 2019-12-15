# xDscDiagnostics PowerShell Module
Find-Module -name xDscDiagnostics -Repository PSGallery

Install-Module xDscDiagnostics -Force

Get-Command -Module xDscDiagnostics | ft -AutoSize

Get-Command Update-xDscEventLogStatus -Syntax

Update-xDscEventLogStatus -ComputerName ms1 -Status Enabled -Channel Debug -Verbose
Update-xDscEventLogStatus -ComputerName ms1 -Status Enabled -Channel Analytic -Verbose

Update-xDscEventLogStatus -ComputerName ms1 -Status Disabled -Channel Debug -Verbose
Update-xDscEventLogStatus -ComputerName ms1 -Status Disabled -Channel Analytic -Verbose


# Listlog - IsEnabled = True
Get-WinEvent -cn ms1 -ListLog 'Microsoft-Windows-DSC/Debug' | select *
Get-WinEvent -cn ms1 -ListLog 'Microsoft-Windows-DSC/Analytic'

# Generate activity
Start-DscConfiguration -ComputerName ms1.contoso.com -Path C:\PShell\Demos\WindowsBackup -Wait -Verbose

# Create some logs in Debug
Get-DscLocalConfigurationManager -CimSession ms1

# View Events
Get-WinEvent -cn ms1 -LogName 'Microsoft-Windows-DSC/Debug' -Oldest

# Check the details of the log
Get-WinEvent -cn ms1 -LogName 'Microsoft-Windows-DSC/Debug' -Oldest

# Disable the Logs
Update-xDscEventLogStatus -ComputerName ms1 -Status Disabled -Channel Debug -Verbose
# Enable them again
Update-xDscEventLogStatus -ComputerName ms1 -Status Enabled -Channel Debug -Verbose

# note the logs are empty ?!
Get-WinEvent -cn ms1 -ListLog 'Microsoft-Windows-DSC/Debug' | 
    select FileSize, LogName, LastWriteTime

# Check the Analytic
Get-WinEvent -cn ms1 -LogName 'Microsoft-Windows-DSC/Analytic' -Oldest

#region Configuration
Configuration myDefaultConfig {
  param ( [string[]]$ComputerName = $env:COMPUTERNAME )

  Import-DSCResource -ModuleName PSDesiredStateConfiguration
  
  Node $ComputerName {

    File dsctestdir
    {
      DestinationPath = 'c:\dsctest'
      Type            = 'Directory'
    }
      
    File dsctestfile
    {
      DestinationPath = 'c:\dsctest\dsctest.txt'
      Contents        = "$($Node.Nodename) $(Get-Date)"
      Type            = 'File'
      DependsOn       = '[File]dsctestdir'
    }
  }#Node
}

myDefaultConfig -ComputerName ms1 -OutputPath .\myDefaultConfig

# Runs in background job
Start-DscConfiguration -Path .\myDefaultConfig -ComputerName ms1 -Force
get-job | receive-job

#endregion

# Check the Logs again
Get-WinEvent -cn ms1 -LogName 'Microsoft-Windows-DSC/Debug' -Oldest
Get-WinEvent -cn ms1 -LogName 'Microsoft-Windows-DSC/Analytic' -Oldest -MaxEvents 25

# Disable and Enable the Logs
Update-xDscEventLogStatus -ComputerName ms1 -Status Disabled -Channel Analytic -Verbose
Update-xDscEventLogStatus -ComputerName ms1 -Status Enabled -Channel Analytic -Verbose

# Saving the logs to evtx File
wevtutil epl /?
Invoke-command -ComputerName ms1 -ScriptBlock {
    $DebugPath = '%SystemRoot%\System32\Winevt\Logs\Microsoft-Windows-DSC%4Debug.evtx'
    wevtutil export-log 'Microsoft-Windows-DSC/Debug' $DebugPath 
}

Get-WinEvent -cn ms1 -LogName 'Microsoft-Windows-DSC/Debug' -Oldest
Get-WinEvent -cn ms1 -ListLog 'Microsoft-Windows-DSC/Debug' | select *


# xDscDiagnostics PowerShell Module
Get-Command -Module xDscDiagnostics | ft -AutoSize

Get-Command Get-xDscOperation -Syntax

Get-xDscOperation -Newest 5 -ComputerName ms1 -OutVariable OP | ft -AutoSize
$op[3].jobid.guid

Get-Command Trace-xDscOperation -Syntax

Trace-xDscOperation -JobId ($op[3].jobid.guid) -ComputerName ms1 | ft -auto
Trace-xDscOperation -SequenceID 4 -ComputerName ms1 | ft -auto

Test-DscConfiguration -Detailed -CimSession ms1

Start-DscConfiguration -Path .\myDefaultConfig


#----------------------------------------------------------------------
$log     = 'Microsoft-Windows-DSC/Operational'
$MinFrom = 30
$Start   = (Get-date).AddMinutes(-$MinFrom)
$End     = (Get-date).AddMinutes(-0)
$Node    = 'ms1'
$Filter  = @{ LogName = $log ; StartTime =$Start ; EndTime   =$end }

Get-WinEvent -FilterHashtable $Filter -ComputerName $Node  | 
    Sort-Object -Property TimeCreated |
        Select-Object @{n="Jobid";e={$_.properties[0].value}} -Unique | 
            Where-Object {$_.jobid -as [Guid]} |
                ForEach-Object -Process {

    Write-Verbose -Message "Processing JobID $($_.JobID)" -Verbose
    Trace-xDscOperation -JobId $_.jobID -ComputerName $Node -EA 0

} #---------------------------------------------------------------------

Get-LCMEventHistory -ComputerName ms1 -MinFrom 60
