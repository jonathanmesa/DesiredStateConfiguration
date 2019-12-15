break
cls

Set-Location C:\PShell\Demos


Test-DscConfiguration
Test-DscConfiguration -Verbose
Test-DscConfiguration -Detailed

Get-DscConfiguration

Get-DscConfigurationStatus
Get-DscConfigurationStatus -All


Get-DscConfigurationStatus | select * | ogv
Get-DscConfigurationStatus -All | select * | ogv

# CIM sessions can take a number of robust parameters for connectivity and authentication
$cim = New-CimSession -ComputerName 'ms1','ms2'

Test-DscConfiguration -CimSession $cim
Test-DscConfiguration -CimSession $cim -Verbose
Test-DscConfiguration -CimSession $cim -Detailed

Get-DscConfiguration -CimSession $cim
Get-DscConfigurationStatus -CimSession $cim | ft -auto
Get-DscConfigurationStatus -All -CimSession $cim | ft -auto

Remove-CimSession $cim








# Reset
Invoke-Command -ComputerName 'ms1','ms12' -ScriptBlock {
    Remove-Item HKLM:\SOFTWARE\Contoso -Force -Recurse
    Remove-Item C:\Windows\System32\Configuration\*.mof
}
