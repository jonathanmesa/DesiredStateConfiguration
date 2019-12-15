break
cls

Set-Location C:\PShell\Demos


# MetaConfig.mof
dir C:\Windows\System32\Configuration\*meta*

Get-DscLocalConfigurationManager

# v4 PULL

Configuration SetPullMode 
{
    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode              = 'ApplyAndAutocorrect'
            ConfigurationID                = [GUID]::NewGuid().Guid
            RefreshFrequencyMins           = 120
            ConfigurationModeFrequencyMins = 240
            RefreshMode                    = 'PULL'
            RebootNodeIfNeeded             = $False
            DownloadManagerName            = 'WebDownloadManager'
            DownloadManagerCustomData      = @{
                ServerUrl               = 'https://pull.contoso.com:8080/PSDSCPullServer.svc'
                AllowUnsecureConnection = 'false'
            }
        }
    }
}

SetPullMode
notepad .\SetPullMode\localhost.meta.mof

Set-DscLocalConfigurationManager -Path .\SetPullMode -Verbose

Get-DscLocalConfigurationManager
(Get-DscLocalConfigurationManager).DownloadManagerCustomData



# V4 PUSH

Configuration SetPushMode
{
	Node localhost
	{
		LocalConfigurationManager
		{
			ConfigurationMode              = 'ApplyAndMonitor'
            RefreshFrequencyMins           = 30
            ConfigurationModeFrequencyMins = 30
			RefreshMode                    = 'PUSH'
            RebootNodeIfNeeded             = $True

		}
	}
}

SetPushMode

Set-DscLocalConfigurationManager -Path .\SetPushMode

Get-DscLocalConfigurationManager



# v5 PULL

[DscLocalConfigurationManager()]
Configuration LCMPullv5
{
    Node localhost
    {
        Settings
        {
            ActionAfterReboot              = 'ContinueConfiguration'
            AllowModuleOverWrite           = $True
            ConfigurationID                = 'a019aeb4-27e0-4ae2-b2f9-edc0fc620338'
            ConfigurationMode              = 'ApplyAndAutoCorrect'
            ConfigurationModeFrequencyMins = 15
            RefreshFrequencyMins           = 30
            StatusRetentionTimeInDays      = 7
            RebootNodeIfNeeded             = $True
            RefreshMode                    = 'Pull'
        }
        ConfigurationRepositoryWeb PullServer
        {
            ServerURL                = "https://pull.contoso.com:8080/PSDSCPullServer.svc"
            AllowUnsecureConnection  = $false
        }
    }
}
LCMPullv5
Set-DSCLocalConfigurationManager -Path .\LCMPullv5

Get-DscLocalConfigurationManager
(Get-DscLocalConfigurationManager).ConfigurationDownloadManagers



# V5 LCM Tweaks (and v4 KB3000850)

Configuration LCMTest
{
    Node localhost
    {
        LocalConfigurationManager
        {
            # ContinueConfiguration, StopConfiguration
            ActionAfterReboot = 'ContinueConfiguration'
            
            # Push, Pull, Disabled
            # Used with Invoke-DscResource
            RefreshMode       = 'Push'
            
            # None, ForceModuleImport, All, ResourceScriptBreakAll
            # Forces resource modules to load freshly during development
            DebugMode         = 'All'
        }
    }
}

LCMTest
Set-DscLocalConfigurationManager -Path .\LCMTest

Get-DscLocalConfigurationManager






# Reset
del C:\windows\System32\Configuration\*meta*.mof
