### ResourceScriptBreakAll
### This demo is not working on April Preview


break


<#
# Set LCM DebugMode to ResourceScriptBreakAll
[DscLocalConfigurationManager()]
Configuration ConfigureLCMForDebug
{
    Node ms2
    {
        Settings
        {
            DebugMode = 'ResourceScriptBreakAll'
        }
    }
}
ConfigureLCMForDebug -outputpath c:\LCMDebug
Set-DscLocalConfigurationManager -path c:\LCMDebug -verbose
#>

Enable-DscDebug -BreakAll -CimSession ms2

Get-DscLocalConfigurationManager -CimSession ms2 | select DebugMode


# Send a configuration
Configuration myDefaultConfig {
  param ( [string[]]$ComputerName = $env:COMPUTERNAME )

  Import-DSCResource -ModuleName PSDesiredStateConfiguration
  
  Node $ComputerName {
    Registry Decom
    {
        Key       = 'HKLM:\SOFTWARE\Contoso'
        ValueName = 'Decom'
        Ensure    = 'Absent'
    }

    Group InfoSecBackDoor
    {
        GroupName   = 'InfoSec'
        Description = 'This is not the group you are looking for.'
        Ensure      = 'Present'
    }

  }
}

myDefaultConfig -ComputerName ms2 -OutputPath .\myDefaultConfig

Start-DscConfiguration -Path .\myDefaultConfig -Wait -Verbose -ComputerName ms2

