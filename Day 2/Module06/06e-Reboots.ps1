break
cls

# View the LCM configuration
Get-DscLocalConfigurationManager
Get-DscLocalConfigurationManager | fl ConfigurationMode, RefreshMode, ActionAfterReboot, RebootNodeIfNeeded

# Configure the LCM outside of change control window
[DscLocalConfigurationManager()]
Configuration LCMv5
{
Param (
    $ComputerName
)
    Node $ComputerName
    {
        Settings
        {
            ConfigurationMode  = 'ApplyAndMonitor'
            ActionAfterReboot  = 'StopConfiguration'
            RebootNodeIfNeeded = $False
            RefreshMode        = 'Disabled'
        }
    }
}
LCMv5 -ComputerName localhost
Set-DscLocalConfigurationManager .\LCMv5

# View the LCM configuration
Get-DscLocalConfigurationManager
Get-DscLocalConfigurationManager | fl ConfigurationMode, RefreshMode, ActionAfterReboot, RebootNodeIfNeeded

# Configure the LCM for autocorrect all the time
[DscLocalConfigurationManager()]
Configuration LCMv5
{
Param (
    $ComputerName
)
    Node $ComputerName
    {
        Settings
        {
            ConfigurationMode  = 'ApplyAndAutocorrect'
            ActionAfterReboot  = 'ContinueConfiguration'
            RebootNodeIfNeeded = $True
            RefreshMode        = 'Push'
        }
    }
}
LCMv5 -ComputerName localhost
Set-DscLocalConfigurationManager .\LCMv5

# View the LCM configuration
Get-DscLocalConfigurationManager | fl ConfigurationMode, RefreshMode, ActionAfterReboot, RebootNodeIfNeeded

# View the xPendingReboot logic and Set function
ise $Env:ProgramFiles\WindowsPowerShell\Modules\xPendingReboot\DSCResources\MSFT_xPendingReboot\MSFT_xPendingReboot.psm1

# View reboot status
Get-DscConfigurationStatus
Get-DscConfigurationStatus -All

# View reboot status remotely
$cim = New-CimSession -ComputerName ms1.contoso.com,ms2.contoso.com
Get-DscLocalConfigurationManager -CimSession $cim | ft PSComputerName, LCMState, ConfigurationMode, RefreshMode, ActionAfterReboot, RebootNodeIfNeeded -AutoSize
Get-DscConfigurationStatus -CimSession $cim
Get-DscConfigurationStatus -CimSession $cim -All
Remove-CimSession $cim
