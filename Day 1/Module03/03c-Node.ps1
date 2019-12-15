#Requires -RunAsAdministrator 
Break
cls

Set-Location C:\PShell\Demos

# Set the config target to PULL mode.
# We assign the GUID to the remote target.
[DscLocalConfigurationManager()]
Configuration LCMPullv5
{
Param (
    $ComputerName,
    $GUID
)
    Node $ComputerName
    {
        Settings
        {
            ActionAfterReboot              = 'ContinueConfiguration'
            AllowModuleOverWrite           = $True
            ConfigurationID                = $GUID
            ConfigurationMode              = 'ApplyAndMonitor'
            ConfigurationModeFrequencyMins = 15
            RefreshFrequencyMins           = 30
            StatusRetentionTimeInDays      = 7
            RebootNodeIfNeeded             = $True
            RefreshMode                    = 'Pull'
        }
        ConfigurationRepositoryWeb PullServer
        {
            ServerURL                = "http://pull.contoso.com:8080/PSDSCPullServer.svc"
            AllowUnsecureConnection  = $true
        }
    }
}
LCMPullv5 -ComputerName ms1.contoso.com -GUID $guid

# Connect to node
$cim = New-CimSession -ComputerName ms1.contoso.com

# Configure LCM
Set-DSCLocalConfigurationManager -Path .\LCMPullv5 -CimSession $cim

# Confirm LCM
Get-DSCLocalConfigurationManager -CimSession $cim
(Get-DSCLocalConfigurationManager -CimSession $cim).ConfigurationDownloadManagers

# Trigger pull of configuration (~45 seconds)
Update-DscConfiguration -CimSession $cim -Wait -Verbose
