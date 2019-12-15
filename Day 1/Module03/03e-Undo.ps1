#Requires -RunAsAdministrator 
Break


Set-Location C:\PShell\Demos

Uninstall-WindowsFeature -Name Windows-Server-Backup -ComputerName ms1

Install-WindowsFeature Web-Scripting-Tools
Get-WebSite -Name PSDSC* | Remove-Website
Remove-WindowsFeature -Name Web-Server,ManagementOData,DSC-Service
Get-ChildItem c:\inetpub -File -Recurse | Remove-Item -Force -Confirm:$false

Remove-Item C:\Windows\System32\Configuration\Current.mof, C:\Windows\System32\Configuration\backup.mof, C:\Windows\System32\Configuration\Previous.mof -ErrorAction SilentlyContinue
Get-ChildItem "C:\Program Files\WindowsPowerShell\DSCService\" | Remove-Item -Recurse -Force -Confirm:$false

Restart-Computer
<#
$ScriptBlock = {
    Remove-Item C:\Windows\System32\Configuration\Current.mof, C:\Windows\System32\Configuration\backup.mof, C:\Windows\System32\Configuration\Previous.mof -ErrorAction SilentlyContinue
    Remove-WindowsFeature -Name Windows-Server-Backup
}
Invoke-Command -ComputerName CVMEMBER3 -ScriptBlock $ScriptBlock -ErrorAction SilentlyContinue

Get-DSCLocalConfigurationManager -CimSession $cim
Get-WindowsFeature -Name Windows-Server-Backup -ComputerName CVMEMBER3

Get-WindowsFeature | ? InstallState -eq "Installed"
Get-WindowsFeature -ComputerName cvmember3 | ? InstallState -eq "Installed"

Remove-CimSession $cim

# Restart-Computer -Computername CVMEMBER2
#>
