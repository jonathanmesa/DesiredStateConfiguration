break
cls

Set-Location C:\PShell\Demos


# MetaConfig.mof
dir C:\Windows\System32\Configuration\*meta*

Get-DscLocalConfigurationManager

# v5 PUSH
[DscLocalConfigurationManager()]
Configuration LCMPushv5
{
    Node localhost
    {
        Settings
        {
            ActionAfterReboot              = 'ContinueConfiguration'
            AllowModuleOverWrite           = $True
            ConfigurationMode              = 'ApplyAndAutoCorrect'
            ConfigurationModeFrequencyMins = 15
            RefreshFrequencyMins           = 30
            StatusRetentionTimeInDays      = 7
            RebootNodeIfNeeded             = $True
            RefreshMode                    = 'Push'
        }
    }
}
LCMPushv5

Set-DSCLocalConfigurationManager -Path .\LCMPushv5

Get-DscLocalConfigurationManager






# Reset
del C:\windows\System32\Configuration\*meta*.mof
