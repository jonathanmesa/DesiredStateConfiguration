#Requires -RunAsAdministrator 
Break
cls

# Verify that it was applied
Test-DscConfiguration -CimSession $cim
Get-DscConfiguration -CimSession $cim
Get-DscConfigurationStatus -CimSession $cim

Get-WindowsFeature -Name Windows-Server-Backup -ComputerName ms1.contoso.com

# View the event log
Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock {
    Get-WinEvent -LogName Microsoft-Windows-DSC/Operational -MaxEvents 15 | 
        Select-Object TimeCreated, Message | Format-Table -Wrap -AutoSize }

Remove-CimSession $cim
