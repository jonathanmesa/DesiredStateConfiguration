Get-Command -Module PsDesiredStateConfiguration -Noun DscDebug

Get-Command Enable-DscDebug -Syntax
Get-Help Enable-DscDebug -Full

Get-DscLocalConfigurationManager | Select-Object DebugMode

Enable-DscDebug
# -BreakAll required (not reflected in help yet)

Get-DscLocalConfigurationManager | Select-Object DebugMode

Enable-DscDebug -BreakAll

Get-DscLocalConfigurationManager | Select-Object DebugMode

Enable-DscDebug -BreakAll -CimSession ms1

Get-DscLocalConfigurationManager -CimSession ms1 | Select-Object DebugMode

Disable-DscDebug -CimSession pull,ms1

Get-DscLocalConfigurationManager -CimSession pull,ms1 | Select-Object DebugMode
