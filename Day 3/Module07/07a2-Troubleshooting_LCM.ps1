## Configuration Status

Get-DscConfiguration -CimSession $CS

# V5
Get-DscConfigurationStatus -CimSession $CS -OutVariable Status | ft -AutoSize

$Status | select ResourcesInDesiredState,ResourcesNotInDesiredState | fl

$Status | foreach ResourcesInDesiredState | ogv
$Status | foreach ResourcesNotInDesiredState

Test-DscConfiguration -CimSession $CS
Test-DscConfiguration -CimSession $CS -Detailed
Test-DscConfiguration -CimSession $CS -Verbose


# Configuration Status

Get-DscConfigurationStatus -CimSession $CS -OutVariable Status -All

Invoke-Command -CN $CN -ScriptBlock {Get-DscConfigurationStatus -All}

psEdit "\\$CN\c$\windows\System32\Configuration\DSCStatusHistory.mof"

Get-ChildItem -Path "\\$CN\c$\windows\System32\Configuration\ConfigurationStatus" -OutVariable $statusFiles

psEdit "\\ms1\c`$\windows\System32\Configuration\ConfigurationStatus\{0E7554FF-E8BA-11E4-80C9-000D3A10E6EB}-0.mof"

<#
instance of DSC_ConfigurationStatusData
{
    Year = 2015;
    Month = 4;
    Day = 14;
    IsMeta = False;
    JobID = "{70895CC8-E2B6-11E4-80C4-000D3A10E6EB}";
    JobStep = 0;
};
#>

# Remove Meta Configurations
Get-ChildItem -Path "\\$CN\c$\windows\System32\Configuration"
Get-ChildItem -Path "\\$CN\c$\windows\System32\Configuration" -Filter meta*.mof

# Confirm the current setting in PULL mode
Get-DscLocalConfigurationManager -CimSession $CS 

# Reset the LCM
Remove-Item -Path "\\$CN\c$\windows\System32\Configuration\MetaConfig*.mof"

# Might take a second to refresh
# Confirm the setting are removed and it goes back to default PUSH
Get-DscLocalConfigurationManager -CimSession $CS 

# Use a helper function to set server back to PULL Mode.
#Import-Module -Name psdsc
#Start-DeployDSCLCMConfigPullSMB -ComputerName $CN

# likely want to utilize the Event Logs for better history tracking.
# This is covered in the next section.
